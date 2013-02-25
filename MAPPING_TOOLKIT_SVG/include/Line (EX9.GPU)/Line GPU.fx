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
float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

texture pTex <string uiname="Position Texture";>;
sampler pSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (pTex);          //apply a texture to the sampler
    MipFilter = POINT; MinFilter = POINT; MagFilter = POINT;
	AddressU = clamp; AddressV = wrap;
};

texture rTex <string uiname="Range Texture";>;
sampler rSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (rTex);          //apply a texture to the sampler
    MipFilter = POINT; MinFilter = POINT; MagFilter = POINT;
	AddressU = clamp; AddressV = wrap;
};

texture cTex <string uiname="Color Texture";>;
sampler cSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (cTex);          
    MipFilter = POINT; MinFilter = POINT; MagFilter = POINT;
	AddressU = clamp; AddressV = wrap;
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
vs2ps VS_Spline(float4 PosO: POSITION, float3 NormO: NORMAL, float4 TexCd : TEXCOORD0, float4 PosCd : TEXCOORD1)
{
    vs2ps Out = (vs2ps)0;
    const float3 rVec = float3(0,0,1);
	const int Size = 2;
	
	//prepare texcoordinates for lookup
	float cSize = (Size-1)*0.9999;
	float4 cCd = PosCd;
	cCd.x = floor(cCd.x*(cSize))/cSize;
	
	//lookup start and end
    float4 p1 = tex2Dlod(pSamp, cCd);
	float4 p2 = tex2Dlod(pSamp, float4(cCd.x+0.5,cCd.yzw));	
    
	//from to
	float4 range = tex1Dlod(rSamp, PosCd);
	float4 _p1 = lerp(p1, p2, range.x);
	float4 _p2 = lerp(p1, p2, range.y);
	
	pota curve = LinearSpline(_p1,_p2,PosCd.x*cSize);
    float4 spline = curve.Pos;
	
	float3 tang = normalize(curve.Tang);
	float3 bitang= normalize(cross(tang,rVec));
	float3x3 tBN = float3x3((float3)0,bitang,cross(tang,bitang));
	PosO.xyz=spline.xyz+(mul(PosO.xyz,tBN)*spline.w);
	
    Out.PosWVP  = mul(PosO, tWVP);	
    Out.TexCd = mul(TexCd, tTex);
	Out.PosCd = PosCd;

    return Out;
}
// PIXELSHADER------------------------------------------------------------------
float4 PS(vs2ps In): COLOR
{
	float4 col = tex2D(Samp, In.TexCd);
	col *= tex1D(cSamp, In.PosCd); //color lookup per spline
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
