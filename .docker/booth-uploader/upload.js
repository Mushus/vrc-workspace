const puppeteer = require('puppeteer');
const fs = require('fs');

exports.upload = upload;
exports.command = uploadWithSideEffect;

async function uploadWithSideEffect(option) {
    process.stdin.setEncoding('utf8');
    let text = '';
    for await (const chunk of process.stdin) text += chunk;
    const config = JSON.parse(text);

    const username = process.env.UPLOADER_USERNAME;
    const password = process.env.UPLOADER_PASSWORD;

    return await upload(config, { ...option, username, password });
}

async function upload(config, { visible, username, password, chromePath, cookiePath }) {
    const isSelectedBrowser = Boolean(chromePath);
    const browser = await puppeteer.launch({
        executablePath: isSelectedBrowser ? chromePath : 'chromium-browser',
        headless: !visible,
        args: isSelectedBrowser ? undefined : ['--no-sandbox', '--disable-setuid-sandbox']
    });

    console.log('start');

    // トップページを開く
    const page = (await browser.pages())[0];
    await page.setViewport({ width: 1024, height: 600 });

    page.on('dialog', dialog => dialog.accept());

    // クッキー読み込み
    try {
        console.log('loading coolie');
        const cookies = JSON.parse(fs.readFileSync(cookiePath, 'utf-8'));
        for (let cookie of cookies) {
            await page.setCookie(cookie);
        }
        console.log(' > ok');
    } catch (e) { }

    // ページを開く
    console.log('open booth');
    await page.goto('https://manage.booth.pm/items');

    // ログインしているかチェック
    const loginLink = await page.$('.pixiv-oauth');
    if (loginLink) {
        console.log('start login');
        // pixiv のログイン画面を待つ
        await Promise.all([
            page.waitForNavigation(),
            loginLink.click()
        ]);

        // ログイン情報の入力
        await page.type('input[autocomplete="username"]', username);
        await page.type('input[autocomplete="current-password"]', password);
        await Promise.all([
            page.waitForNavigation(),
            page.click('#LoginComponent button[type="submit"]')
        ]);
        console.log(' > ok');

        // クッキー保存
        console.log('save cookie');
        const afterCookies = await page.cookies();
        fs.writeFileSync(cookiePath, JSON.stringify(afterCookies));
        console.log(' > ok');
    }

    // すべてのアイテムに実行
    for (const item of config) {
        const { id, variations, files, saveas, description } = item;
        console.log(`edit item: ${id}`);

        // アイテム編集ページを開く
        await Promise.all([
            page.waitForNavigation(),
            page.goto(`https://manage.booth.pm/items/${id}/edit`)
        ]);

        console.log('update description');
        const descriptionSelector = "#description";
        await page.$eval(descriptionSelector, element => element.value = '');
        await page.type(descriptionSelector, description);
        console.log(' > ok');

        await page.waitForTimeout(500);

        // バリエーションによってUIが異なる
        if (variations.length === 1) {
            // HACK: フォームを特定する方法がない
            const labelXpath = `//label[text() = "作品ファイル"]`;
            const uploadLabels = await page.$x(labelXpath);
            if (!uploadLabels || uploadLabels.length === 0) continue;
            const [uploadLabel] = uploadLabels;
            // アップロードシートを特定
            let uploadSheet = uploadLabel;
            for (let i = 0; i < 4; i++) {
                uploadSheet = await uploadSheet.getProperty('parentNode');
            }

            // アップロード済みのものがあればすべて消す
            console.log('reflesh files');
            await (async function () {
                const openModal = await uploadSheet.$('.ui-open-modal') || await uploadSheet.$('button');
                await uploadableModal(page, openModal, createRefleshModalFile(files));
            })();
            // HACK: 一旦閉じずに作業するとエラーが起きるので
            await (async function () {
                const openModal = await uploadSheet.$('.ui-open-modal') || await uploadSheet.$('button');
                await uploadableModal(page, openModal, createSelectUploadFiles(variations[0]));
            })();
            console.log(' > ok');
        } else {
            const variationBoxSelector = '.variation-box';
            const variationBox = await page.$(variationBoxSelector);
            const openModal = await variationBox.$('.ui-open-modal') || await variationBox.$('button');

            console.log('reflesh files');
            await uploadableModal(page, openModal, createRefleshModalFile(files));
            console.log(' > ok');

            console.log('update variation');
            const variationBoxList = await page.$$(variationBoxSelector);
            for (const i in variations) {
                const vb = variationBoxList[i];
                const variation = variations[i];
                const openModal = await vb.$('.ui-open-modal') || await vb.$('button');
                await uploadableModal(page, openModal, createSelectUploadFiles(variation));
            }
            console.log(' > ok');
        }

        // アイテムの保存
        const buttonText = saveas === 'draft' ? '下書きで保存する' : '公開で保存する';
        console.log(`save item: ${buttonText}`);
        const buttonXpath = `//button[text() = "${buttonText}"]`;
        const [button] = await page.$x(buttonXpath);
        await Promise.all([
            page.waitForSelector('.item-new-v2-modal', { visible: true }),
            button.click(),
        ]);
        console.log(' > ok');
    }
    await browser.close();
    process.exit(0);
};

async function uploadableModal(page, openModal, callback) {
    const downloadModalSelector = '.downloadable-modal';
    const [downloadableModalContent] = await Promise.all([
        page.waitForSelector(downloadModalSelector, { visible: true }),
        openModal.click()
    ]);

    // ダイアログのフェードインアニメーション考慮
    await page.waitForTimeout(500);

    let modal = downloadableModalContent;
    for (let i = 0; i < 5; i++) {
        modal = await modal.getProperty('parentNode');
    }

    await callback(page, downloadableModalContent)

    // モーダルを閉じる
    const closeButton = await modal.$('.icon-cancel');
    await closeButton.click();

    // ダイアログのフェードインアニメーション考慮
    await page.waitForTimeout(500);
}

function createRefleshModalFile(files) {
    return async function refleshModalFile(page, downloadableModalContent) {
        // クリックしてアップロードファイルを消す
        for (; ;) {
            const button = await downloadableModalContent.$('.drop-zone-destroy');
            if (!button) break;
            await button.click()
            await page.waitForTimeout(300);
        }

        // アップロードボタンクリック
        const dropzone = await downloadableModalContent.$(".drop-zone");
        const [fileChooser] = await Promise.all([
            page.waitForFileChooser(),
            dropzone.click()
        ]);

        // アップロードまで待機
        await fileChooser.accept(files.map(file => file.path));

        // アップロード完了まで待機
        while (await downloadableModalContent.$(".uploaded-downloadable .progress-bar")) {
            await page.waitForTimeout(500);
        }

        // HACK: エラーの原因？ちょっとだけ待機
        await page.waitForTimeout(500);
    };
}

function createSelectUploadFiles(variation) {
    return async function selectUploadFiles(page, downloadableModalContent) {
        const files = variation.files.map(i => String(i));
        // ダウンロードリスト
        const downloadables = await downloadableModalContent.$$('.uploaded-downloadable');
        for (const i in downloadables) {
            // ダウンロードできる状態に合わせる
            const downloadable = downloadables[i];
            const checked = Boolean(await downloadable.$('input[type="checkbox"]:checked'));
            if (checked != files.includes(i)) {
                const checker = await downloadable.$('label.booth-checkbox');
                await checker.click();
                await page.waitForTimeout(300);
            }
        }

        // HACK: エラーの原因？ちょっとだけ待機
        await page.waitForTimeout(500);
    };
}