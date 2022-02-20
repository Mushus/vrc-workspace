// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Musharder/MusToon"
{
    Properties
    {
        [Header(Surface)][Space(10)]
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor ("Main Color", Color) = (1, 1, 1)
        _NormalMap ("Normal map", 2D) = "bump" {}
        [Header(Shade)][Space(10)]
        _ShadeColor ("Shade Color", Color) = (0.5, 0.5, 0.5)
        _ShadeOffset ("Shade Offset", Range(-1, 1)) = 0
        [PowerRange(0.01)] _ShadeSharpness ("Shade Sharpness", Range(0, 1)) = 0.001
        _LightDirCorrection ("Light Direction Correction", Range(0, 1)) = 0.5
        [Header(Rim)][Space(10)]
        _RimColor ("Rim Color", Color) = (0.5, 0.5, 0.5)
        _RimInside ("Rim Inside", Range(0, 1)) = 1
        _RimPower ("Rim Power", Range(0, 100)) = 0
        [Header(Outline)][Space(10)]
        [PowerRange(0.01)] _OutlineWidth ("Width", Range(0, 0.1)) = 0
        _OutlineColor ("Width", Color) = (0.5, 0.5, 0.5)
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

            #include "UnityCG.cginc"
            #include "funcs.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                float3 indirectLighting : COLOR1;
                float3 normal : NORMAL;
                float4 tangent : TANGENT0;
                float3 bitan : TANGENT1;
                // float3 normal : NORMAL;
                SHADOW_COORDS(3)
            };

            float4 _LightColor0;

            sampler2D _MainTex;
            float3 _MainColor;
            float3 _ShadeColor;
            float _ShadeOffset;
            float _LightDirCorrection;
            float _ShadeSharpness;
            float3 _RimColor;
            float _RimInside;
            float _RimPower;
            sampler2D _NormalMap;

            v2f vert (appdata v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv  = v.uv;

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.lightDir =  UnityWorldSpaceLightDir(worldPos);
                o.viewDir = UnityWorldSpaceViewDir(worldPos);
                o.normal = v.normal;
                o.tangent = v.tangent;
                o.bitan = cross(UnityObjectToWorldNormal(v.normal) , UnityObjectToWorldDir(v.tangent.xyz)) * v.tangent.w * unity_WorldTransformParams.w;
                TRANSFER_SHADOW(o)
                return o;
            }

            float3 frag (v2f i) : SV_Target
            {
                float3 lightDir = normalize(i.lightDir);
                float3 viewDir = normalize(i.viewDir);
                float3 halfDir = normalize(lerp(i.lightDir, i.viewDir, _LightDirCorrection));

                float3 tex = tex2D(_MainTex, i.uv);

                // ---------- ノーマルマップ
                float3 worldNormal = UnityObjectToWorldNormal(i.normal.xyz);
                {
                    float3 worldTangent = UnityObjectToWorldDir(i.tangent.xyz);

                    float3 normalTex = normalize(UnpackNormal(tex2D(_NormalMap , i.uv)));

                    float3 tangentSx = float3(worldTangent.x, i.bitan.x, worldNormal.x);
                    float3 tangentSy = float3(worldTangent.y, i.bitan.y, worldNormal.y);
                    float3 tangentSz = float3(worldTangent.z, i.bitan.z, worldNormal.z);
                    worldNormal.x = dot(tangentSx, normalTex);
                    worldNormal.y = dot(tangentSy, normalTex);
                    worldNormal.z = dot(tangentSz, normalTex);
                }

                // ノーマルマップから得た法線情報をつかってライティング計算をする
                float ShadeDir = dot(worldNormal, halfDir);
                float shadeSmooth = asin(ShadeDir) * 4 / TAU;

                // float diff = smoothstep(_ShadeSharpness, -_ShadeSharpness, shadeSmooth + _ShadeOffset);

                // half3 spec = half3(0, 0, 0);

                float3 albedo = tex * _MainColor;

                float3 directionalLighting = _LightColor0.rgb * _LightColor0.a;
                float directionalLightingPower = _LightColor0.a;

                // セルフシャドウが汚くなる原因なので、自身のシャドゥができる方向に影が描画されないようにグラデーションをかける
                float AttenShadeDir = dot(worldNormal, lightDir);
                float atten = saturate(max(1 - AttenShadeDir, 0) + SHADOW_ATTENUATION(i));

                // 環境光
                float3 indirectLighting = saturate(ShadeSH9(half4(worldNormal, 1)));

                // リムライト
                // float diff = saturate(-mul(lightDir, viewDir));
                // float rimPower = pow(diff, 3);

                // float rim = saturate(_RimInside - dot(normal, lerp(viewDir, lightDir, 0.1)));
                // float3 emission = _RimColor * pow(rim, 100 / _RimPower) * rimPower;

                float shade = atten * smoothstep(-_ShadeSharpness, _ShadeSharpness, shadeSmooth + _ShadeOffset);
                float noShade = 1 - shade;
                float3 color = saturate(
                    albedo *
                    (indirectLighting + directionalLighting) *
                    lerp(float3(1, 1, 1), _ShadeColor, saturate(noShade * directionalLightingPower))
                );
                // color += emission;
                return color;
            }
            ENDCG
        }

        Pass
        {
            Tags { "LightMode"="ForwardAdd" }

            Blend One One
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd

            #include "UnityCG.cginc"
            #include "funcs.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT0;
                float3 bitan : TANGENT1;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                float3 indirectLighting : COLOR1;
            };

            float4 _LightColor0;

            sampler2D _MainTex;
            float3 _MainColor;
            float3 _ShadeColor;
            float4 _MainTex_ST;
            float _ShadeOffset;
            float _ShadeSharpness;
            float _RimInside;
            float _RimPower;
            sampler2D _NormalMap;

            v2f vert (appdata v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv  = v.uv;

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.lightDir =  UnityWorldSpaceLightDir(worldPos);
                o.viewDir = UnityWorldSpaceViewDir(worldPos);

                o.normal = v.normal;
                o.tangent = v.tangent;
                o.bitan = cross(UnityObjectToWorldNormal(v.normal) , UnityObjectToWorldDir(v.tangent.xyz)) * v.tangent.w * unity_WorldTransformParams.w;
                return o;
            }

            float3 frag (v2f i) : SV_Target
            {
                float3 lightDir = normalize(i.lightDir);
                float3 viewDir = normalize(i.viewDir);
                float3 halfDir = normalize(lerp(lightDir, viewDir, 0.1));

                // 表面の色を求める
                float3 tex = tex2D(_MainTex, i.uv);
                float3 albedo = tex * _MainColor;

                // ---------- ノーマルマップ
                float3 worldNormal = UnityObjectToWorldNormal(i.normal.xyz);
                {
                    float3 worldTangent = UnityObjectToWorldDir(i.tangent.xyz);

                    float3 normalTex = normalize(UnpackNormal(tex2D(_NormalMap , i.uv)));

                    float3 tangentSx = float3(worldTangent.x, i.bitan.x, worldNormal.x);
                    float3 tangentSy = float3(worldTangent.y, i.bitan.y, worldNormal.y);
                    float3 tangentSz = float3(worldTangent.z, i.bitan.z, worldNormal.z);
                    worldNormal.x = dot(tangentSx, normalTex);
                    worldNormal.y = dot(tangentSy, normalTex);
                    worldNormal.z = dot(tangentSz, normalTex);
                }

                // ---------- リムライティング
                // ライトの方向をどれだけ見ているか
                float lookLight = -mul(lightDir, viewDir);
                // ライトを直視した時に眩しくなってほしい
                float rimPower = pow(saturate(lookLight), 3);
                // 正面を向いてる面部分に減衰を入れる
                float rimLight = saturate(_RimInside - dot(worldNormal, viewDir));
                // リムライトに強弱をつける
                float rimLightWithPower = pow(rimLight, 100 / _RimPower) * rimPower;

                // ライトからの直接光
                float3 directLight = max(0, dot(worldNormal, lightDir));

                // ライト全体の着色処理
                UNITY_LIGHT_ATTENUATION(atten, i, worldNormal)
                float3 light = (directLight + rimLightWithPower) * atten * _LightColor0;

                // ライトと色のブレンド
                float3 color = albedo * light;

                return color;
            }
            ENDCG
        }

        //影を落とす処理を行うPass
        Pass
        {
            Tags
            {
                "LightMode"="ShadowCaster"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f
            {
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }

        // アウトラインを出すPass
        Pass
        {
            cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float _OutlineWidth;
            float3 _OutlineColor;

            v2f vert (appdata v)
            {
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                float cameraToVertexLength = length(_WorldSpaceCameraPos - worldPos);
                // どの距離でもアウトラインの太さを均一にする
                float3 worldVertex = worldPos + worldNormal * cameraToVertexLength * _OutlineWidth;

                v2f o;
                o.vertex = mul(UNITY_MATRIX_VP, float4(worldVertex, 1));
                o.uv = v.uv;

                return o;
            }

            float3 frag (v2f i) : SV_Target
            {
                float3 tex = tex2D(_MainTex, i.uv);
                return tex * _OutlineColor;
            }
            ENDCG
        }
    }
}
