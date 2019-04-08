// Unity 2017,2018 shader
// Autor : nagnae
// Thanks to j1jeong & JP.
//====================================

//- Import from libraries.
//import lib-pom.glsl
//import lib-pbr.glsl
import lib-vectors.glsl
//import lib-sampler.glsl
import lib-env.glsl
import lib-normal.glsl
//import lib-alpha.glsl
//import lib-random.glsl
//import lib-emissive.glsl
import lib-sparse.glsl

//------------------------------------------------------------------------------
//  Parameters
//------------------------------------------------------------------------------

//: state cull_face off

//-------- Render ---------------------------------------------------//

//: param custom {
//:   "default": 0,
//:   "label": "Alpha threshold",
//:   "min": 0.0,
//:   "max": 1.0,
//:   "group": "Render"
//: }
uniform float alpha_threshold;

//: param custom { "default": false, "label": "Double Sided", "group": "Render" }
uniform bool DoubleSided;

//: param custom { "default": false, "label": "Inverse Normal Y\r\n (Unity use OpenGL normal.\r\n Donot recommend use this)", "group": "Render" }
uniform bool inverseNormalY;

//: param custom { "default": true, "label": "Unity SH Ambient", "group": "Render" }
uniform bool useUnityAmbient;

//: param custom { "default": false, "label": "Unity Skybox Approximate", "group": "Render" }
uniform bool use_unity_skybox_approximate;

//-: param custom {
//-:   "default": 7,
//-:   "label": "Unity SpecularProbe",
//-:   "widget": "combobox",
//-:   "values": {
//-:     "16": 4,
//-:     "32": 5,
//-:     "64": 6,
//-:     "128": 7,
//-:     "256": 8,
//-:     "512": 9,
//-:     "1024": 10,
//-:     "2048": 11
//-:   },
//-:   "group": "Render"
//-: }
//uniform int unity_specularprobe_lod_count;


//-------- Mipmap ----------------------------------------------------//

//: param custom { "default": false, "label": "Use", "group": "Mipmap" }
uniform bool useMipmap;

//: param custom { "default": false, "label": "Show Disntance", "group": "Mipmap" }
uniform bool showMipmap;

//: param custom {
//:   "default": 0.0,
//:   "label": "Start",
//:   "min": 0.0,
//:   "max": 10.0,
//:   "group": "Mipmap"
//: }
uniform float mipmap_start;

//: param custom {
//:   "default": 20.0,
//:   "label": "End",
//:   "min": 10.0,
//:   "max": 40.0,
//:   "group": "Mipmap"
//: }
uniform float mipmap_end;

//-: param custom {
//-:   "default": 20,
//-:   "label": "Intensity",
//-:   "min": 1.0,
//-:   "max": 20.0,
//-:   "group": "Mipmap"
//-: }
const float mipmap_intensity = 20;


//-------- Lights ----------------------------------------------------//

//: param custom { "default": [1.0, 1.0, 1.0], "label": "Direction", "min": -1, "max": 1, "group": "Light" }
uniform vec3 lightDirection;

//: param custom { "default": 1, "label": "Color", "widget": "color", "group": "Light" }
uniform vec3 lightColor;

//-------- Surface ---------------------------------------------------//

//: param custom {
//:   "default": 1.0,
//:   "label": "Emissive Intensity",
//:   "min": 0.0,
//:   "max": 100.0,
//:   "group": "Surface"
//: }
uniform float emissive_intensity;

//: param custom {
//:   "default": 1,
//:   "label": "AO Intensity",
//:   "min": 0.00,
//:   "max": 1.0,
//:   "group": "Surface"
//: }
uniform float ao_intensity;

//-------- Constant ---------------------------------------------------//

//: param auto environment_max_lod
uniform float environment_max_lod;

//: param auto texture_environment_size
uniform vec4 environment_size;


//------------------------------------------------------------------------------
// Unity Codebase
//------------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Types

#define float2 vec2
#define float3 vec3
#define float4 vec4
#define half float
#define half2 vec2
#define half3 vec3
#define half4 vec4
#define real float
#define real2 vec2
#define real3 vec3
#define real4 vec4

// -----------------------------------------------------------------------------
// Constants

#define HALF_MAX        65504.0 // (2 - 2^-10) * 2^15
#define HALF_MAX_MINUS1 65472.0 // (2 - 2^-9) * 2^15
#define EPSILON         1.0e-4
#define PI              3.14159265359
#define TWO_PI          6.28318530718
#define FOUR_PI         12.56637061436
#define INV_PI          0.31830988618
#define INV_TWO_PI      0.15915494309
#define INV_FOUR_PI     0.07957747155
#define HALF_PI         1.57079632679
#define INV_HALF_PI     0.636619772367

#define FLT_EPSILON     1.192092896e-07 // Smallest positive number, such that 1.0 + FLT_EPSILON != 1.0
#define FLT_MIN         1.175494351e-38 // Minimum representable positive floating-point number
#define FLT_MAX         3.402823466e+38 // Maximum representable floating-point number
#define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats
#define HALF_MAX 65504.0
#define REAL_MIN HALF_MIN
#define REAL_MAX HALF_MAX


// -----------------------------------------------------------------------------
// Saturate

half saturate( half v )
{
	return clamp(v,0,1);
}

half2 saturate( half2 v )
{
	return clamp(v,half2(0),half2(1));
}

half3 saturate( half3 v )
{
	return clamp(v,half3(0),half3(1));
}

half4 saturate( half4 v )
{
	return clamp(v,half4(0),half4(1));
}


// -----------------------------------------------------------------------------
// Lerp

half lerp( half a, half b, half t )
{
	return mix(a,b,t);
}

half2 lerp( half2 a, half2 b, half t )
{
	return mix(half2(a),half2(b),half2(t));
}

half2 lerp( half2 a, half b, half t )
{
	return mix(half2(a),half2(b),half2(t));
}

half2 lerp( half a, half2 b, half t )
{
	return mix(half2(a),half2(b),half2(t));
}

half2 lerp( half2 a, half2 b, half2 t )
{
	return mix(half2(a),half2(b),half2(t));
}

half3 lerp( half3 a, half b, half t )
{
	return mix(half3(a),half3(b),half3(t));
}

half3 lerp( half a, half3 b, half t )
{
	return mix(half3(a),half3(b),half3(t));
}

half3 lerp( half3 a, half3 b, half t )
{
	return mix(half3(a),half3(b),half3(t));
}

half3 lerp( half3 a, half3 b, half3 t )
{
	return mix(half3(a),half3(b),half3(t));
}

half4 lerp( half4 a, half b, half t )
{
	return mix(half4(a),half4(b),half4(t));
}

half4 lerp( half a, half4 b, half t )
{
	return mix(half4(a),half4(b),half4(t));
}

half4 lerp( half4 a, half4 b, half t )
{
	return mix(half4(a),half4(b),half4(t));
}

half4 lerp( half4 a, half4 b, half4 t )
{
	return mix(half4(a),half4(b),half4(t));
}


// -----------------------------------------------------------------------------
// math

real Pow4(real x)
{
    return (x * x) * (x * x);
}

// Normalize that account for vectors with zero length
real3 SafeNormalize(real3 inVec)
{
    real dp3 = max(REAL_MIN, dot(inVec, inVec));
    return inVec / sqrt(dp3);
}

float clampstep(float edge0, float edge1, float x)
{
	// Scale, bias and saturate x to 0..1 range
	x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0); 
	return x;
}

float smoothstep(float edge0, float edge1, float x)
{
	// Scale, bias and saturate x to 0..1 range
	x = clampstep( edge0, edge1, x ); 
	// Evaluate polynomial
	return x * x * (3 - 2 * x);
}


//------------------------------------------------------------------------------
//  Ambient SH

real3 SHEvalLinearL0L1(real3 N, real4 shAr, real4 shAg, real4 shAb)
{
    real4 vA = real4(N, 1.0);

    real3 x1;
    // Linear (L1) + constant (L0) polynomial terms
    x1.r = dot(shAr, vA);
    x1.g = dot(shAg, vA);
    x1.b = dot(shAb, vA);

    return x1;
}

real3 SHEvalLinearL2(real3 N, real4 shBr, real4 shBg, real4 shBb, real4 shC)
{
    real3 x2;
    // 4 of the quadratic (L2) polynomials
    real4 vB = N.xyzz * N.yzzx;
    x2.r = dot(shBr, vB);
    x2.g = dot(shBg, vB);
    x2.b = dot(shBb, vB);

    // Final (5th) quadratic (L2) polynomial
    real vC = N.x * N.x - N.y * N.y;
    real3 x3 = shC.rgb * vC;

    return x2 + x3;
}

// Samples SH L0, L1 and L2 terms
half3 SampleSH(half3 N)
{
#if 1
	// skybox setting
	// Substance : parnorama, 259 degree
	// Unity  : parnorama, 162 degree
    float4 shAr = vec4( 0.032, 0.14, 0.15, 0.29 );
    float4 shAg = vec4( 0.039, 0.21, 0.2, 0.34 );
    float4 shAb = vec4( 0.037, 0.29, 0.22, 0.37 );
    float4 shBr = vec4( 0.051, 0.079, 0.14, 0.068 );
    float4 shBg = vec4( 0.051, 0.094, 0.14, 0.083 );
    float4 shBb = vec4( 0.046, 0.1, 0.12, 0.094 );
    float4 shCr = vec4( 0.027, 0.033, 0.036, 1 );
#else
    float4 shAr = vec4( 0.075, 0.14, 0.13, 0.3 );
    float4 shAg = vec4( 0.095, 0.21, 0.17, 0.35 );
    float4 shAb = vec4( 0.1, 0.29, 0.19, 0.38 );
    float4 shBr = vec4( 0.072, 0.058, 0.091, 0.12 );
    float4 shBg = vec4( 0.077, 0.073, 0.091, 0.13 );
    float4 shBb = vec4( 0.074, 0.082, 0.064, 0.12 );
    float4 shCr = vec4( 0.041, 0.05, 0.053, 1 );
#endif

    // Linear + constant polynomial terms
    float3 res = SHEvalLinearL0L1(N, shAr, shAg, shAb);

    // Quadratic polynomials
    res += SHEvalLinearL2(N, shBr, shBg, shBb, shCr);

    return max(half3(0, 0, 0), res);
}

//------------------------------------------------------------------------------
// Sampler
//------------------------------------------------------------------------------

const float DEFAULT_OPACITY = 1.0;
const vec3  DEFAULT_BASE_COLOR     = vec3(0.5);
const float DEFAULT_ROUGHNESS      = 0.3;
const float DEFAULT_METALLIC       = 0.0;
const float DEFAULT_AO             = 1.0;
const float DEFAULT_SPECULAR_LEVEL = 0.5;
const float DEFAULT_HEIGHT         = 0.0;
const float DEFAULT_DISPLACEMENT   = 0.0;

//- Channels needed for metal/rough workflow are bound here.
//: param auto channel_basecolor
uniform SamplerSparse  basecolor_tex;
//: param auto channel_basecolor_size
uniform vec4 basecolor_size;
//: param auto channel_opacity
uniform SamplerSparse opacity_tex;
//: param auto channel_opacity_size
uniform vec4 opacity_size;
//: param auto channel_roughness
uniform SamplerSparse roughness_tex;
//: param auto channel_roughness_size
uniform vec4 roughness_size;
//: param auto channel_metallic
uniform SamplerSparse metallic_tex;
//: param auto channel_metallic_size
uniform vec4 metallic_size;
//: param auto channel_emissive
uniform SamplerSparse emissive_tex;
//: param auto channel_emissive_size
uniform vec4 emissive_size;

//: param auto ao_blending_mode
uniform int ao_blending_mode;
//: param auto texture_ao
uniform SamplerSparse base_ao_tex;
//: param auto channel_ao
uniform SamplerSparse ao_tex;
//: param auto channel_ao_is_set
uniform bool channel_ao_is_set;

//: param auto texture_normal_size
uniform vec4 base_normal_texture_size;
//: param auto channel_normal_size
uniform vec4 normal_texture_size;
//: param auto texture_ao_size
uniform vec4 base_ao_size;
//: param auto channel_ao_size
uniform vec4 ao_size;
//: param auto world_eye_position
uniform vec3 world_eye_position;

vec2 tex_coord;
float eye_distance;

vec4 texture( SamplerSparse s, vec2 uv )
{
	return textureSparse( s, getSparseCoord(uv) );
}

vec4 readTexel_mipmap( SamplerSparse s, vec4 tex_size )
{
	if( is2DView || !useMipmap || tex_size.x <= 2 || tex_size.y <= 2 )
	{
		return texture(s, tex_coord );
	}

	// mipmap simulation
#if 0
	// gaussian mipmap
	// calulate radius
	int texel_radius_x;
	int texel_radius_y;
	float texel_ratio = tex_size.y / tex_size.x;
	if( texel_ratio <= 1 )
	{
		texel_radius_x = int(eye_distance);
		texel_radius_y = int( texel_radius_x * texel_ratio );
	}
	else
	{
		texel_radius_y = int(eye_distance);
		texel_radius_x = int( texel_radius_y / texel_ratio );
	}
	float texel_radius_y_squared = texel_radius_y * tex_size.w;
	texel_radius_y_squared *= texel_radius_y_squared;

	// texel map
	vec4 texel = vec4(0);
	float weight_sum = 0;
	float gaussian_b = -1.0 / (2.0 * texel_radius_y*texel_radius_y);
	float gaussian_a = gaussian_b / -M_PI;
	gaussian_b *= tex_size.y * tex_size.y;
	
	//return vec4( gaussian_a );
	//return vec4( gaussian_a * exp( tex_size.w*tex_size.w * gaussian_b ) );
	//return vec4( texel_radius_y_squared * 1000 );
	//return vec4( -gaussian_b * 0.0001 );
	//return vec4( gaussian_a );
	
	for( int y = -texel_radius_y; y <= +texel_radius_y; y++ )
	{
		for( int x = -texel_radius_x; x <= +texel_radius_x; x++ )
		{
			vec2 uv = vec2( x*tex_size.z + tex_coord.x, y*tex_size.w + tex_coord.y );
			vec2 uv_diff = uv - tex_coord;
			uv_diff.x *= texel_ratio;
			float r = dot( uv_diff, uv_diff );
			if( r <= texel_radius_y_squared )
			{
				//uv = clamp( uv, 0, 1 );
				float weight = gaussian_a * exp( r * gaussian_b );
				weight_sum += weight;
				texel += weight * texture(s, uv );
			}
		}
	}

	if( weight_sum > 0 )
		texel /= weight_sum;
	else
		texel = texture(s, tex_coord );
#else
	// box mipmap
	// calulate radius
	int texel_radius_x;
	int texel_radius_y;
	float texel_ratio = tex_size.y / tex_size.x;
	if( texel_ratio <= 1 )
	{
		texel_radius_x = int(eye_distance);
		texel_radius_y = int( texel_radius_x * texel_ratio );
	}
	else
	{
		texel_radius_y = int(eye_distance);
		texel_radius_x = int( texel_radius_y / texel_ratio );
	}
	float texel_radius_y_squared = texel_radius_y * tex_size.w;
	texel_radius_y_squared *= texel_radius_y_squared;

	// texel map
	vec4 texel = vec4(0);
	int texel_count = 0;
	for( int y = -texel_radius_y; y <= +texel_radius_y; y++ )
	{
		for( int x = -texel_radius_x; x <= +texel_radius_x; x++ )
		{
			vec2 uv = vec2( x*tex_size.z + tex_coord.x, y*tex_size.w + tex_coord.y );
			vec2 uv_diff = uv - tex_coord;
			uv_diff.x *= texel_ratio;
			if( dot( uv_diff, uv_diff ) <= texel_radius_y_squared )
			{
				//uv = clamp( uv, 0, 1 );
				texel_count++;
				texel += texture(s, uv );
			}
		}
	}

	if( texel_count > 0 )
		texel /= texel_count;
#endif
	return texel;
}


float getOpacity()
{
#if 0
	vec2 opacity_a = texture(opacity_tex, tex_coord).rg;
#else
	vec2 opacity_a = readTexel_mipmap( opacity_tex, opacity_size ).rg;
#endif
	return opacity_a.r + DEFAULT_OPACITY * (1.0 - opacity_a.g);
}

vec3 getBaseColor()
{
#if 1
	vec4 out_color = texture(basecolor_tex, tex_coord);
#else
	vec4 out_color = readTexel_mipmap(basecolor_tex, basecolor_size);
#endif
	return out_color.rgb + DEFAULT_BASE_COLOR * (1.0 - out_color.a);
}

float getRoughness()
{
#if 0
	vec2 roughness_a = texture(roughness_tex, tex_coord).rg;
#else
	vec2 roughness_a = readTexel_mipmap(roughness_tex, roughness_size).rg;
#endif
	return roughness_a.r + DEFAULT_ROUGHNESS * (1.0 - roughness_a.g);
}

float getMetallic()
{
#if 0
	vec2 metallic_a = texture(metallic_tex, tex_coord).rg;
#else
	vec2 metallic_a = readTexel_mipmap(metallic_tex, metallic_size).rg;
#endif
	return metallic_a.r + DEFAULT_METALLIC * (1.0 - metallic_a.g);
}

float getAO( bool is_premult )
{
#if 1
	vec2 ao_lookup = texture(base_ao_tex, tex_coord).ra;
#else
	vec2 ao_lookup = readTexel_mipmap( base_ao_tex, base_ao_size ).ra;
#endif
	
	float ao = ao_lookup.x + DEFAULT_AO * (1.0 - ao_lookup.y);

	if (channel_ao_is_set)
	{
#if 0
		ao_lookup = texture(ao_tex, tex_coord).rg;
#else
		ao_lookup = readTexel_mipmap( ao_tex, ao_size ).rg;
#endif
		if (!is_premult) ao_lookup.x *= ao_lookup.y;
		float channel_ao = ao_lookup.x + DEFAULT_AO * (1.0 - ao_lookup.y);
		if (ao_blending_mode == BlendingMode_Replace)
		{
			ao = channel_ao;
		}
		else if (ao_blending_mode == BlendingMode_Multiply)
		{
			ao *= channel_ao;
		}
	}

	// Modulate AO value by AO_intensity
	return mix(1.0, ao, ao_intensity);
}

vec3 getUnpackedNormal( SamplerSparse  t, vec4 s, float y )
{
	vec4 normal_texel = readTexel_mipmap( t, s );
	if( inverseNormalY )
	{
		normal_texel.y = 1 - normal_texel.y;
	}
	return normalUnpack( normal_texel, y);
}

vec3 getUnpackedNormal( SamplerSparse t, vec4 s)
{
	return getUnpackedNormal( t, s, 1);
}

vec3 getUnpackedNormal()
{
	float height_force = 1.0;
	vec3 normalFromHeight = normalFromHeight(tex_coord, height_force);
	
  	// get base normal
	vec3 normal = getUnpackedNormal( base_normal_texture, base_normal_texture_size, base_normal_y_coeff );
	normal = normalBlendOriented(normal, normalFromHeight);

	if (base_normal_texture.is_set)
	{
		vec3 channelNormal = getUnpackedNormal( normal_texture, normal_texture_size );
		if (normal_blending_mode == BlendingMode_Replace)
		{
			normal = normalBlendOriented(normalFromHeight, channelNormal);
		}
		else if (normal_blending_mode == BlendingMode_NM_Combine)
		{
			normal = normalBlendOriented(normal, channelNormal);
		}
	}

	return normal;
}

//: param auto shadow_mask_enable
uniform bool sm_enable;
//: param auto shadow_mask_opacity
uniform float sm_opacity;
//: param auto shadow_mask
uniform sampler2D sm_tex;
//: param auto screen_size
uniform vec4 screen_size;

float getShadowFactor()
{
	float shadowFactor = 1.0;

	if (sm_enable)
	{
		vec2 screenCoord = (gl_FragCoord.xy * vec2(screen_size.z, screen_size.w));
		vec2 shadowSample = texture(sm_tex, screenCoord).xy;
		// shadowSample.x / shadowSample.y is the normalized shadow factor.
		// shadowSample.x may already be normalized, shadowSample.y contains 0.0 in this case.
		shadowFactor = shadowSample.y == 0.0 ? shadowSample.x : shadowSample.x / shadowSample.y;
	}

	return mix(1.0, shadowFactor, sm_opacity);
}

//------------------------------------------------------------------------------
// Unity LWRP lighting
//------------------------------------------------------------------------------

struct Light  
{
	vec3 direction;
	vec3 color;
	float attenuation;
};

Light GetMainLight()
{
	Light light;
	light.direction = normalize( lightDirection );
	//light.direction = half3(1,1,1);
	//light.direction.x = -mainLight.direction.x;
	light.color = lightColor;
	return light;
}

struct BRDFData
{
    half3 diffuse;
    half3 specular;

    half perceptualRoughness;
    half roughness;
    half roughness2;
    half grazingTerm;

    // We save some light invariant BRDF terms so we don't have to recompute
    // them in the light loop. Take a look at DirectBRDF function for detailed explaination.
    half normalizationTerm;     // roughness * 4.0 + 2.0
    half roughness2MinusOne;    // roughness² - 1.0
};

#define kDieletricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)

half OneMinusReflectivityMetallic_Cusom(half metallic)
{
    // We'll need oneMinusReflectivity, so
    //   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
    // store (1-dielectricSpec) in kDieletricSpec.a, then
    //   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
    //                  = alpha - metallic * alpha
    half oneMinusDielectricSpec = kDieletricSpec.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

real PerceptualSmoothnessToPerceptualRoughness(real perceptualSmoothness)
{
    return (1.0 - perceptualSmoothness);
}

real PerceptualRoughnessToRoughness(real perceptualRoughness)
{
    return perceptualRoughness * perceptualRoughness;
}

BRDFData InitializeBRDFData(half3 albedo, half metallic, half smoothness )
{
    half oneMinusReflectivity = OneMinusReflectivityMetallic_Cusom(metallic);
    half reflectivity = 1.0 - oneMinusReflectivity;

	BRDFData outBRDFData;
    outBRDFData.diffuse = albedo * half3(oneMinusReflectivity);
    outBRDFData.specular = lerp(kDieletricSpec.rgb, albedo, metallic);

    outBRDFData.grazingTerm = saturate(smoothness + reflectivity);
    outBRDFData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
    outBRDFData.roughness = PerceptualRoughnessToRoughness(outBRDFData.perceptualRoughness);
    outBRDFData.roughness2 = outBRDFData.roughness * outBRDFData.roughness;

    outBRDFData.normalizationTerm = outBRDFData.roughness * 4.0 + 2.0;
    outBRDFData.roughness2MinusOne = outBRDFData.roughness2 - 1.0;

	return outBRDFData;
}

#define UNITY_SPECCUBE_LOD_STEPS_CUSTOM 6

real PerceptualRoughnessToMipmapLevel(real perceptualRoughness)
{
    half mip = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
	//mip = pow( mip, 0.53 );
	mip = pow( mip, 0.4 );
	//mip = pow( mip, 0.3 );
	mip *= 0.97;
	
	//float unity_environment_lod_count = float(unity_specularprobe_lod_count);

#if 0
	const float mipmap_end = environment_max_lod - environment_mipmap_bias;
	const float mipmap_start = mipmap_end - UNITY_SPECCUBE_LOD_STEPS_CUSTOM;
#elif 0	
	const float mipmap_start = max( 0, environment_max_lod - unity_environment_lod_count );
	const float mipmap_end = min( unity_environment_lod_count, mipmap_start + UNITY_SPECCUBE_LOD_STEPS_CUSTOM );
#elif 0
	const float mipmap_start = 0;
	const float mipmap_scale = environment_max_lod / unity_environment_lod_count;
	const float mipmap_tail = ( unity_environment_lod_count - UNITY_SPECCUBE_LOD_STEPS_CUSTOM ) * mipmap_scale - 1;
	const float mipmap_end = min( environment_max_lod, environment_max_lod - mipmap_tail*1.2 );
#elif 1
	const float mipmap_start = 0;
	const float mipmap_end = environment_max_lod - 1.5;
#endif

	return mip * ( mipmap_end - mipmap_start ) + mipmap_start;
}

half3 GlossyEnvironmentReflection(half3 reflectVector, half perceptualRoughness, half occlusion)
{
#if !defined(_GLOSSYREFLECTIONS_OFF)
    half mip = PerceptualRoughnessToMipmapLevel( perceptualRoughness );
   	half3 irradiance = envSampleLOD(reflectVector, mip);

	if( use_unity_skybox_approximate )
	{
		const float threshold = 0.6;

		mip =  ( mip - 1 ) / ( environment_max_lod - 1 );
		mip = 1 - ( 1-threshold ) * mip;
		mip = max( mip, threshold );
		float irradiance_length = dot( irradiance, irradiance );
		if( irradiance_length > mip )
		{
			irradiance_length = clamp( ( irradiance_length - mip ) / ( 1 - mip ), 0, 1 );
			irradiance_length = 1 - irradiance_length*mip;
			irradiance = mip + ( irradiance - mip ) * irradiance_length;
		}
	}

   	irradiance *= occlusion;
    return irradiance;
#endif // GLOSSY_REFLECTIONS

	half3 _GlossyEnvironmentColor = half3( 1,1,1); // !!TEMP
    return _GlossyEnvironmentColor.rgb * occlusion;
}

half3 EnvironmentBRDF(BRDFData brdfData, half3 indirectDiffuse, half3 indirectSpecular, half fresnelTerm)
{
    half3 c = indirectDiffuse * brdfData.diffuse;
    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
    c += surfaceReduction * indirectSpecular * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm);
    return c;
}


half3 GlobalIllumination(BRDFData brdfData, half3 bakedGI, half occlusion, half3 normalWS, half3 viewDirectionWS)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, viewDirectionWS)));

    half3 indirectDiffuse = bakedGI * occlusion;
    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion);
	//return indirectSpecular;
    return EnvironmentBRDF(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);
}


half3 LightingPhysicallyBased(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS)
{
    half NdotL = saturate(dot(normalWS, light.direction));
    half3 radiance = light.color * (light.attenuation * NdotL);

#ifndef _SPECULARHIGHLIGHTS_OFF
    half3 halfDir = SafeNormalize(light.direction + viewDirectionWS);

    half NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(light.direction, halfDir));

    // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
    // BRDFspec = (D * V * F) / 4.0
    // D = roughness² / ( NoH² * (roughness² - 1) + 1 )²
    // V * F = 1.0 / ( LoH² * (roughness + 0.5) )
    // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
    // https://community.arm.com/events/1155

    // Final BRDFspec = roughness² / ( NoH² * (roughness² - 1) + 1 )² * (LoH² * (roughness + 0.5) * 4.0)
    // We further optimize a few light invariant terms
    // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
    half d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001;

    half LoH2 = LoH * LoH;
    half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1, LoH2) * brdfData.normalizationTerm);

    // on mobiles (where half actually means something) denominator have risk of overflow
    // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
    // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
#if defined (SHADER_API_MOBILE)
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif

	half3 color = specularTerm * brdfData.specular + brdfData.diffuse;
	return color * half3(radiance);
#else
    return brdfData.diffuse * half3(radiance);
#endif
}


half3 LightweightFragmentPBR(LocalVectors vectors, Light light, half3 albedo, half metallic, half smoothness, half occlusion, half3 emission)
{
	vec3 ambient_normal;
	if( gl_FrontFacing )
	{
		ambient_normal = vectors.vertexNormal;
	}
	else
	{
		//!!INFO : 결과물이 LWRP와 완벽하게 같지는 않다.
		// LWRP는 vertex에서 L0L1을 pixel에서 L2를 계산한다.
		// 또 다 vertex에서 계산한 것과도 퀄리티 차이가 별 나지 않아 보인다.
		// 하지만 back face처리 때문에 다 vertex에서 계산할 수는 없다.
		// back face를 그리지 않는다면, 다 vertex에서 계산하도록 LWRP를 수정하는게 좋아 보인다.
		ambient_normal = -vectors.vertexNormal;
	}

	vec3 ambient;
	if(!useUnityAmbient)
	{
		ambient = envIrradiance(ambient_normal);
	}
	else
	{
		ambient = SampleSH(ambient_normal);
	}

    BRDFData brdfData = InitializeBRDFData(albedo, metallic, smoothness );

    half3 color = emission;
	color += GlobalIllumination(brdfData, ambient, occlusion, vectors.normal, vectors.eye);
    color += LightingPhysicallyBased(brdfData, light, vectors.normal, vectors.eye);
    return color;
}

//------------------------------------------------------------------------------
// Main Shader
//------------------------------------------------------------------------------

//- Shader entry point.
void shade(V2F inputs)
{
	// Apply parallax occlusion mapping if possible
	//vec3 viewTS = worldSpaceToTangentSpace(getEyeVec(inputs.position), inputs);
	//inputs.tex_coord += getParallaxOffset(inputs.tex_coord, viewTS);

	// get distance
	tex_coord = inputs.tex_coord;
	{
		vec3 eye_distance_vec = world_eye_position - inputs.position;
		eye_distance = sqrt( dot( eye_distance_vec, eye_distance_vec ) );
		eye_distance = clampstep( mipmap_start, mipmap_end, eye_distance );
		eye_distance *= mipmap_intensity;
	}

	// alpha kill
	float opacity = getOpacity();
	if (opacity < alpha_threshold * (1+EPSILON))
		discard;

	// double sided
	if( !gl_FrontFacing && !DoubleSided )
		discard;

	if( showMipmap )
	{
		diffuseShadingOutput(vec3(eye_distance / mipmap_intensity));
		return;
		//return vec4(eye_distance / mipmap_intensity);
	}

	//return readTexel_mipmap( normal_texture, normal_size );

	// calculate vector
	LocalVectors vectors;
	{
		vec3 normal = getUnpackedNormal();
		normal = tangentSpaceToWorldSpace( normal, inputs );

		// cull facing
		if( !gl_FrontFacing )
		{
			inputs.normal = -inputs.normal;
			normal = -normal;
		}

		vectors = computeLocalFrame(inputs, normal, 0);
	}

	// Fetch material parameters, and conversion to the specular/glossiness model
	vec3 baseColor = getBaseColor();
	float glossiness = 1.0 - getRoughness();
	float metallic = getMetallic();
	vec3 emissive = emissive_intensity * readTexel_mipmap( emissive_tex, emissive_size ).rgb;
	float occlusion = getAO( true );

	// get light
    Light mainLight = GetMainLight();
    mainLight.attenuation = getShadowFactor();

	// Feed parameters for a physically based BRDF integration
	vec3 color = LightweightFragmentPBR(vectors, mainLight, baseColor, metallic, glossiness, occlusion, emissive );

	diffuseShadingOutput(color);
	//return vec4(color,1);
}

//- Entry point of the shadow pass.
void shadeShadow(V2F inputs)
{
}
