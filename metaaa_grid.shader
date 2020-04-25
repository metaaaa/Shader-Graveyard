Shader "Unlit/metaaa_Grid" {
    Properties {
        [HideInInspector]_LineColor ("Line Color", Color) = (0,0,0,1)
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
        [IntRange] _SplitCount("Split Count", Range(1, 100)) = 10
        _LineSize("Line Size", Range(0.01, 1)) = 0.1
        _FPS("FPS",Range(0.0,60.0))=3.0
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
    
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
    
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            sampler2D _MainTex;
    
            fixed4 _LineColor;
            float _SplitCount;
            float _LineSize;
            float _FPS;
            
            float rand(float2 co) 
            {
                return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            float posterize(float f,float c)
            {
                    float pstr=floor(f*c)/(c-1);
                    return pstr;
            }

            float3 HSV2RGB(float3 c)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
    
            fixed4 frag (v2f i) : SV_Target
            {
                float x = floor(i.uv.x*_SplitCount);
                float y = floor(i.uv.y*_SplitCount);
                float4 c=float4(1.0,1.0,1.0,1.0);
                float ptime=posterize(_Time.y,_FPS);
                float hue=rand(float2(x+ptime,y+ptime));
                c.xyz=HSV2RGB(float3(hue,1.0,1.0));
                return lerp(
                    tex2D(_MainTex, i.uv),
                    _LineColor, 
                    saturate(
                        (frac(i.uv.x * (_SplitCount + _LineSize)) < _LineSize) + 
                        (frac(i.uv.y * (_SplitCount + _LineSize)) < _LineSize)
                    )
                )*c;
            }
            ENDCG
        }
    }
}
