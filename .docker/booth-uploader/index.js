const cli = require('cac')()
const upload = require('./upload').command;

cli
  .command('upload', 'upload to booth')
  .option('--visible', 'show browser')
  .option('--username <username>', 'pixiv login username')
  .option('--password <password>', 'pixiv login password')
  .option('--chrome-path <chromePath>', 'executable chrome path')
  .option('--cookie-path <cookiePath>', 'cookie data path')
  .action(upload);

cli.help();
cli.version('0.1.0');
cli.parse();
