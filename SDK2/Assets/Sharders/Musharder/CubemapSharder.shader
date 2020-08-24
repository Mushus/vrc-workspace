Shader "Mushader/CubeSharder"
{
    Properties
    {
        _Cube ("Cube", CUBE) = "" {}
        _CubeOcclusion ("Cube Occlusion", Range(0, 1)) = 0.0
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("UV", 2D) = "" {}
        _BumpMap ("Normal Map"  , 2D) = "bump" {}
		_BumpScale ("Normal Scale", Range(0, 1)) = 1.0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        samplerCUBE _Cube;
        half _CubeOcclusion;
        sampler2D _MainTex;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        sampler2D _BumpMap;
		half _BumpScale;

        struct Input
        {
            float2 uv_MainTex;
            half3 worldNormal : TEXCOORD0;
            float3 worldPos;
        };

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
        // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float3 cubeNormal = IN.worldPos - _WorldSpaceCameraPos;
            float4 texColor = tex2D(_MainTex, IN.uv_MainTex);
            fixed4 color = texColor * _Color * texColor.a;
            fixed4 emission = texCUBE(_Cube, cubeNormal.xyz) * (1 - texColor.a);
            fixed4 normal = tex2D(_BumpMap, IN.uv_MainTex);
			o.Normal = UnpackScaleNormal(normal, _BumpScale);
            o.Albedo = color.rgb;
            o.Emission = emission.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Occlusion = texColor.a  + _CubeOcclusion * (1 - texColor.a);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
