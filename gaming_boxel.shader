Shader "Unlit/meta_boxel"
 {
  Properties {
    _MainTex ("Texture", 2D) = "white" {}
    
    _S("S",float)=1.0
    _V("V",Float)=1.0

    [Header(Surface)]
    _Tint ("Tint", Color) = (1,1,1,1)

    [Header(Box)]
    _BoxScale ("Box Scale", Float) = 0.01

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
      
      #define PI acos(-1.0)
      float3 rand3D(float3 p)
      {
          p = float3( dot(p,float3(127.1, 311.7, 74.7)),
          dot(p,float3(269.5, 183.3,246.1)),
          dot(p,float3(113.5,271.9,124.6)));
          return frac(sin(p)*43758.5453123);
      }

      float rand(float2 co) 
      {
          return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
      }

      float3 HSV2RGB(float3 c)
      {
            float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
      }

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

      float _V;
      float _S;

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
      
      void geoOri(triangle v2f v[3], inout TriangleStream<v2f> TriStream) {
        for (int i = 0; i < 3; i++) {
          v2f o = v[i];

          o.vertex = UnityObjectToClipPos(v[i].vertex);
          o.normal = UnityObjectToWorldNormal(v[i].normal);

          UNITY_TRANSFER_FOG(o,o.vertex);
          TriStream.Append(o);
        }
        TriStream.RestartStrip();
      }

      void geoBox(float scale, triangle v2f v[3], inout TriangleStream<v2f> TriStream) {
        float4 wpos = (v[0].wpos + v[1].wpos + v[2].wpos) / 3;
        float4 vertex = (v[0].vertex + v[1].vertex + v[2].vertex) / 3;
        float2 uv = (v[0].uv + v[1].uv + v[2].uv) / 3;

        v2f o = v[0];
        o.uv = uv;
        o.wpos = wpos;
        o.color.x=rand3D(float3(uv.x,uv.y,1.0)).x;

        float tri=asin(sin(_Time.y*6+100*rand(uv.xy)))*2./PI;

        float size=scale*(rand(uv.yx));
        size+=tri*0.003;
 
        float4 v0 = float4( 1, 1, 1,1)*size + float4(vertex.xyz,0);
        float4 v1 = float4( 1, 1,-1,1)*size + float4(vertex.xyz,0);
        float4 v2 = float4( 1,-1, 1,1)*size + float4(vertex.xyz,0);
        float4 v3 = float4( 1,-1,-1,1)*size + float4(vertex.xyz,0);
        float4 v4 = float4(-1, 1, 1,1)*size + float4(vertex.xyz,0);
        float4 v5 = float4(-1, 1,-1,1)*size + float4(vertex.xyz,0);
        float4 v6 = float4(-1,-1, 1,1)*size + float4(vertex.xyz,0);
        float4 v7 = float4(-1,-1,-1,1)*size + float4(vertex.xyz,0);

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

        o.color.x=rand(uv.yx);

        geoBox(scale * _BoxScale, v, TriStream);
      }

      fixed4 frag (v2f i) : SV_Target {
        float4 col = tex2D(_MainTex, i.uv) * _Tint;
        float3 hsv=HSV2RGB(float3(i.color.x+_Time.y*0.5,_S,_V));
        col.xyz*=hsv;

        return col;
      }
      ENDCG
    }

  }
}