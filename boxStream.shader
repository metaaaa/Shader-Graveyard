Shader "metaaa/boxStream"
{
  Properties {
    _MainTex ("Texture", 2D) = "white" {}
    _BRange("boxRange",Range(0, 1.0)) = 1
    _Speed("Speed",Float)=0.5
    _Amount("BoxAmount",Range(0, 1.0)) = 1

    [Header(Surface)]
    _Tint ("Tint", Color) = (1,1,1,1)

    [Header(Box)]
    _BoxScale ("Box Scale", Float) = 0.01

    [Header(Rim)]
    _RimPower ("Rim Power", Float) = 1
    _RimAmplitude ("Rim Amplitude", Float) = 1
    _RimTint ("Rim Tint", Color) = (1,1,1,1)
  }

  SubShader {
    Tags { "RenderType"="Transparent" "Queue"="Transparent" }
    LOD 100

    Pass {
      Cull Back
      Blend SrcAlpha OneMinusSrcAlpha

      CGPROGRAM
      #pragma target 4.0
      #pragma vertex vert
      #pragma geometry geo
      #pragma fragment frag
      #pragma multi_compile_fog
      #include "UnityCG.cginc"

      struct appdata {
        float4 vertex : POSITION;
        float2 uv     : TEXCOORD0;
        float4 color  : COLOR;
        float3 normal : NORMAL;
      };

      struct v2f {
        float4 vertex : SV_POSITION;
        float2 uv     : TEXCOORD0;
        float4 wpos   : TEXCOORD1;
        float4 color  : TEXCOORD2;
        float3 normal : TEXCOORD3;
        UNITY_FOG_COORDS(4)
      };

      sampler2D _MainTex; float4 _MainTex_ST;
      float4 _WorldPosition;

      float4 _Tint;
      float _BoxScale;

      float _RimPower;
      float _RimAmplitude;
      float4 _RimTint;

      float _BRange;
      float _Speed;
      float _Amount;

      float rand(float2 co) 
      {
          return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
      }

      v2f vert (appdata v) {
        v2f o;
        o.vertex = v.vertex;
        o.uv     = TRANSFORM_TEX(v.uv, _MainTex);
        o.wpos   = mul(unity_ObjectToWorld, v.vertex);
        o.color  = v.color;
        o.normal = v.normal;
        return o;
      }

      #define ADD_VERT(v, n) \
        o.vertex = UnityObjectToClipPos(v); \
        o.normal = UnityObjectToWorldNormal(n); \
        UNITY_TRANSFER_FOG(o,o.vertex); \
        TriStream.Append(o);
      
      #define ADD_TRI(p0, p1, p2, n) \
        ADD_VERT(p0, n) ADD_VERT(p1, n) \
        ADD_VERT(p2, n) \
        TriStream.RestartStrip();


      void geoBox(float scale, triangle v2f v[3], inout TriangleStream<v2f> TriStream) {
        float4 wpos = (v[0].wpos + v[1].wpos + v[2].wpos) / 3;
        float4 vertex = (v[0].vertex + v[1].vertex + v[2].vertex) / 3;
        float2 uv = (v[0].uv + v[1].uv + v[2].uv) / 3;

        v2f o = v[0];
        o.uv = uv;
        o.wpos = wpos;
 
        float4 v0 = float4( 1, 1, 1,1)*scale + float4(vertex.xyz,0);
        float4 v1 = float4( 1, 1,-1,1)*scale + float4(vertex.xyz,0);
        float4 v2 = float4( 1,-1, 1,1)*scale + float4(vertex.xyz,0);
        float4 v3 = float4( 1,-1,-1,1)*scale + float4(vertex.xyz,0);
        float4 v4 = float4(-1, 1, 1,1)*scale + float4(vertex.xyz,0);
        float4 v5 = float4(-1, 1,-1,1)*scale + float4(vertex.xyz,0);
        float4 v6 = float4(-1,-1, 1,1)*scale + float4(vertex.xyz,0);
        float4 v7 = float4(-1,-1,-1,1)*scale + float4(vertex.xyz,0);

        float3 n0 = float3( 1, 0, 0);
        float3 n1 = float3(-1, 0, 0);
        float3 n2 = float3( 0, 1, 0);
        float3 n3 = float3( 0,-1, 0);
        float3 n4 = float3( 0, 0, 1);
        float3 n5 = float3( 0, 0,-1);

        ADD_TRI(v0, v2, v3, n0);
        ADD_TRI(v3, v1, v0, n0);
        ADD_TRI(v5, v7, v6, n1);
        ADD_TRI(v6, v4, v5, n1);

        ADD_TRI(v4, v0, v1, n2);
        ADD_TRI(v1, v5, v4, n2);
        ADD_TRI(v7, v3, v2, n3);
        ADD_TRI(v2, v6, v7, n3);

        ADD_TRI(v6, v2, v0, n4);
        ADD_TRI(v0, v4, v6, n4);
        ADD_TRI(v5, v1, v3, n5);
        ADD_TRI(v3, v7, v5, n5);
      }


      [maxvertexcount(36)]
      void geo(triangle v2f v[3], inout TriangleStream<v2f> TriStream) {
        float4 wpos = (v[0].wpos + v[1].wpos + v[2].wpos) / 3;
        float4 vertex = (v[0].vertex + v[1].vertex + v[2].vertex) / 3;
        float2 uv = (v[0].uv + v[1].uv + v[2].uv) / 3;

        v2f o = v[0];
        o.uv = uv;
        o.wpos = wpos;
        float scale = _BoxScale;

        float lead=frac(_Time.y*_Speed);//流れの先頭

        //一定範囲だけ描画＆乱数でBOX削減
        if(rand(uv)<_Amount){
          if(o.uv.x<=lead && o.uv.x >= lead-_BRange){
            lead=lead-o.uv.x;
          geoBox((1.0-lead)*(1.0-lead)*scale * _BoxScale, v, TriStream);
        }else if(lead-o.uv.x < 0.0 && _BRange>=1.0+lead-o.uv.x){
          lead=1.0+lead-o.uv.x;
          geoBox((1.0-lead)*(1.0-lead)*scale * _BoxScale, v, TriStream);
          }
        }
      }

      fixed4 frag (v2f i) : SV_Target {
        float3 normalDir = normalize(i.normal);
        float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wpos.xyz);
        float NNdotV = 1 - dot(normalDir, viewDir);
        float rim = pow(NNdotV, _RimPower) * _RimAmplitude;

        float4 col = tex2D(_MainTex, i.uv) * i.color * _Tint;
        col.rgb = col.rgb * _RimTint.a + rim * _RimTint.rgb;

        UNITY_APPLY_FOG(i.fogCoord, col);
        return col;
      }
      ENDCG
    }

  }
}