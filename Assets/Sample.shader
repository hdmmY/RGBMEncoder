Shader "Custom/Sample" 
{
    CGINCLUDE

    #include "UnityCG.cginc"

    half3 Hue2RGB(half h)
    {
        h = frac(saturate(h)) * 6 - 2;
        half3 rgb = saturate(half3(abs(h - 1) - 1, 2 - abs(h), 2 - abs(h - 2)));

    #if UNITY_COLORSPACE_GAMMA
        rgb = GammaToLinearSpace(rgb);
    #endif

        return rgb;
    }

    // Encode float3 HDR to half4 color
    // It is better to convert the color from linear to gamma space before encoding
    half4 EncodeRGBM(float3 rgb)
    {
        rgb *= 1.0 / 6.0;
        float a = saturate(max(max(rgb.r, rgb.g), max(rgb.b, 1e-5)));
        a = ceil(a * 255.0) / 255.0;
        return half4(rgb / a, a);
    } 

    // Decode half4 RGBM encode HDR to float3 HDR color.
    float3 DecodeRGBM(half4 rgbm)
    {
        return 6.0 * rgbm.rgb * rgbm.a;
    }

    ENDCG

	SubShader 
    {
        Tags
        {
            "RenderType" = "Opaque"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            struct VInput
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD;
            };

            struct VOutput
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD;
            };

            VOutput vert(VInput i)
            {
                VOutput o;

                o.vertex = UnityObjectToClipPos(i.vertex);
                o.uv = i.uv;

                return o;
            }

            half4 frag(VOutput i) : SV_Target
            {
                float x = i.uv.x * 3;
                float y = i.uv.y * 2.99 + 0.1;

                half3 c1 = Hue2RGB(frac(x)) * y;
                half3 c2 = DecodeRGBM(EncodeRGBM(c1));

                if(frac(x + 0.01) < 0.02)
                    return 0;
                else if (x < 1)
                    return half4(c1, 1);
                else if(x < 2)
                    return half4(c2, 1);
                else
                    return length(c1 - c2) / length(c1) * 100;
            }

            ENDCG
        }
	}
}
