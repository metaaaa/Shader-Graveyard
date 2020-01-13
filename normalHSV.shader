Shader "Unlit/normalHSV"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		[PowerSlider(3.0)]
        _WireframeVal ("Wireframe width", Range(0., 0.34)) = 0.05
        _FrontColor ("Front color", color) = (1., 1., 1., 1.)
        _BackColor ("Back color", color) = (1., 1., 1., 1.)
		_Speed ("Speed",Float)=1.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		Cull Off


		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			//#pragma multi_compile_fog
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				//float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : tangent;
			};

			struct v2f
			{
				//float2 uv : TEXCOORD0;
				//UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float4 tangent : tangent;

			};

			//sampler2D _MainTex;
			//float4 _MainTex_ST;
			float _Speed;
			
			float3 rand3D(float3 p)
			{
				p = float3( dot(p,float3(127.1, 311.7, 74.7)),
							dot(p,float3(269.5, 183.3,246.1)),
							dot(p,float3(113.5,271.9,124.6)));
				return frac(sin(p)*43758.5453123);
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
				//o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				//UNITY_TRANSFER_FOG(o,o.vertex);
				o.normal=v.normal;
				o.tangent=v.tangent;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col=fixed4(i.normal,1);
				float3 rand0 = rand3D(i.normal);
				float tmp=i.normal.x+i.normal.y+i.normal.z;
				tmp+=i.tangent.x;
				//tmp=dot(i.tangent.xyz,i.normal);
				//tmp+=rand0;
				tmp+=_Time.y*_Speed;
				
				float3 hsv=float3(tmp,1.0,1.0);
				float3 rgb=HSV2RGB(hsv);
				col=fixed4(rgb,1.0);
				// sample the texture
				//fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}

		Pass
        {
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom
            #include "UnityCG.cginc"

            struct v2g {
                float4 pos : SV_POSITION;
            };

            struct g2f {
                float4 pos : SV_POSITION;
                float3 bary : TEXCOORD0;
            };

            v2g vert(appdata_base v) {
                v2g o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            [maxvertexcount(3)]
            void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {
                g2f o;
                o.pos = IN[0].pos;
                o.bary = float3(1., 0., 0.);
                triStream.Append(o);
                o.pos = IN[1].pos;
                o.bary = float3(0., 0., 1.);
                triStream.Append(o);
                o.pos = IN[2].pos;
                o.bary = float3(0., 1., 0.);
                triStream.Append(o);
            }

            float _WireframeVal;
            fixed4 _BackColor;

            fixed4 frag(g2f i) : SV_Target {
            if(!any(bool3(i.bary.x < _WireframeVal, i.bary.y < _WireframeVal, i.bary.z < _WireframeVal)))
                 discard;

                return _BackColor;
            }

            ENDCG
        }
		//waiya
        Pass
        {
            Cull Back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom
            #include "UnityCG.cginc"

            struct v2g {
                float4 pos : SV_POSITION;
            };

            struct g2f {
                float4 pos : SV_POSITION;
                float3 bary : TEXCOORD0;
            };

            v2g vert(appdata_base v) {
                v2g o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            [maxvertexcount(3)]
            void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {
                g2f o;
                o.pos = IN[0].pos;
                o.bary = float3(1., 0., 0.);
                triStream.Append(o);
                o.pos = IN[1].pos;
                o.bary = float3(0., 0., 1.);
                triStream.Append(o);
                o.pos = IN[2].pos;
                o.bary = float3(0., 1., 0.);
                triStream.Append(o);
            }

            float _WireframeVal;
            fixed4 _FrontColor;

            fixed4 frag(g2f i) : SV_Target {
            if(!any(bool3(i.bary.x < _WireframeVal, i.bary.y < _WireframeVal, i.bary.z < _WireframeVal)))
                 discard;

                return _FrontColor;
            }

            ENDCG
        }
	}
}
