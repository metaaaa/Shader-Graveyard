Shader "Unlit/rotation"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Speedx ("SpeedX", Float)=0.0
		_Speedy ("SpeedY", Float)=0.0
		_Speedz ("SpeedZ", Float)=0.0
		
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
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
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Speedx;
			float _Speedy;
			float _Speedz;

			float2 rot(float2 p, float r)
			{
				float c = cos(r);
				float s = sin(r);
				return mul(p, float2x2(c, -s, s, c));
			}
			
			v2f vert (appdata v)
			{
				v2f o;
				v.vertex.xz=rot(v.vertex.xz,_Speedy*_Time.y);
				v.vertex.xy=rot(v.vertex.xy,_Speedz*_Time.y);
				v.vertex.yz=rot(v.vertex.yz,_Speedx*_Time.y);
				
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
