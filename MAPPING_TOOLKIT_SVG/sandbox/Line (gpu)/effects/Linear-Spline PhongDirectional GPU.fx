//@author: woei
//@help: creates a ribbon along 3d coordinates, calculated on the GPU
//@tags: line, spline, linear
// PARAMETERS-------------------------------------------------------------------
//transforms
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tWV: WORLDVIEW;
float4x4 tWVP: WORLDVIEWPROJECTION;


//texture
texture Tex <string uiname="Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

//texture2
texture Tex2 <string uiname="Texture2";>;
sampler Samp2 = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex2);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};


float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;
float alpha = 1;



int Size;
texture pTex <string uiname="Position Texture";>;
sampler pSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (pTex);          //apply a texture to the sampler
    MipFilter = POINT;         //sampler states
    MinFilter = POINT;
    MagFilter = POINT;
	AddressU = clamp;
	ADDRESSV = wrap;
};

struct vs2ps
{
    float4 PosWVP: POSITION;
    float4 TexCd : TEXCOORD0;
	float4 PosCd : TEXCOORD1;
};


//---- Linear-Spline -----------------------------------------------------------
struct pota { float4 Pos; float4 Tang; };
pota LinearSpline(float4 p1, float4 p2, float range) {
	pota Out = (pota)0;
	Out.Pos = lerp(p1,p2,frac(range));	
	Out.Tang = p1-p2;
	return Out;
}
// VERTEXSHADER-----------------------------------------------------------------
float pitch;
vs2ps VS_Spline(float4 PosO: POSITION, float3 NormO: NORMAL, float4 TexCd : TEXCOORD0, float4 PosCd : TEXCOORD1)
{
    vs2ps Out = (vs2ps)0;
   
	
	float cSize = (Size-1)*0.9999;
	float4 cCd = PosCd;	
	cCd.x = floor(cCd.x*(cSize))/cSize;
	
    float4 p1 = tex2Dlod(pSamp, cCd);
	float4 p2 = tex2Dlod(pSamp, float4(cCd.x+(1./cSize),cCd.yzw));	
    
	pota curve = LinearSpline(p1,p2,PosCd.x*cSize);
    float4 spline = curve.Pos;

	float3 rVec = 0;
	sincos(pitch,rVec.y,rVec.z);
	float3x3 tR = float3x3(float3(1,0,0), float3(0,rVec.z,-rVec.y), rVec);

	float3 tang = normalize(curve.Tang);
	float3 bitang= normalize(cross(tang,rVec));
	float3x3 tBN = float3x3((float3)0,bitang,cross(tang,bitang));
	PosO.xyz=spline.xyz+(mul(PosO.xyz,tBN)*spline.w);
	
	//bitang = normalize(cross(tang,mul(NormO,tR)));
	
    Out.PosWVP  = mul(PosO, tWVP);	
    Out.TexCd = mul(TexCd, tTex);

    //normal in view space
   // Out.ViewDirV = -normalize(mul(PosO, tWV));
    //Out.Tang = tang;
    //Out.Bi = bitang;
	//Out.Depth = mul(PosO, tWVP);
    return Out;
}
// PIXELSHADER------------------------------------------------------------------
float4 PS(vs2ps In): COLOR
{
	float4 col = tex2D(Samp2, In.TexCd);
	return col ;
}
 

// TECHNIQUES-------------------------------------------------------------------
technique LinearSpline_PhongDirectional
{
    pass P0
    {
        VertexShader = compile vs_3_0 VS_Spline();
        PixelShader = compile ps_3_0 PS();
    }
}
