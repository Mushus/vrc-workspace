Shader "MuSharder/Bomb"
{
    Properties
    {
        _MainTex ("CutOff", 2D) = "white" {}
        _StartCutoff ("Start CutOff", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags {
            "Queue"="AlphaTest"
            "IgnoreProjector"="True"
            "RenderType"="TransparentCutout"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float3 texcoods : TEXCOORD0;
                fixed4 color : COLOR;
            };

            struct v2f
            {
                float3 texcoods : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float agePercent: TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _StartCutoff;

            v2f vert (appdata v)
            {
                float2 uv = float2(v.texcoods.x, v.texcoods.y);
                uv = TRANSFORM_TEX(uv, _MainTex);

                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoods = float3(uv.x, uv.y, v.texcoods.z);
                UNITY_TRANSFER_FOG(o, o.vertex);
                o.color = v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float2 uv = float2(i.texcoods.x, i.texcoods.y);
                // fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 cutout = tex2D(_MainTex, uv);
                fixed4 col = i.color;
                float agePercent = i.texcoods.z;
                // y = (x - 1)/(1 - c) + 1
                float cutThreshold = (agePercent - 1) / (1 - _StartCutoff) + 1;
                clip(cutout.r - cutThreshold);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
