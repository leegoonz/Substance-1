//- Allegorithmic Metal/Rough PBR shader
//- ====================================
//-
//- Import from libraries.
import lib-sampler.glsl
import lib-pbr.glsl
import lib-pom.glsl
import lib-utils.glsl

//- Declare the iray mdl material to use with this shader.
//: metadata {
//:   "mdl":"mdl::alg::materials::physically_metallic_roughness::physically_metallic_roughness"
//: }

//- Channels needed for metal/rough workflow are bound here.
//: param auto channel_basecolor
uniform sampler2D basecolor_tex;
//: param auto channel_roughness
uniform sampler2D roughness_tex;
//: param auto channel_metallic
uniform sampler2D metallic_tex;
//: param auto channel_specularlevel
uniform sampler2D specularlevel_tex;

//: param custom { "default": false, "label": "ACES Tonemapping" }
uniform bool aces;

// Directional Sun Settings

//: param custom { "default": false, "label": "Sun & Sky" }
uniform bool sun;

//: param custom { "default": 1.0, "label": "Sun Strenght", "min": 0.0, "max": 10.0 }
uniform float sun_strenght;

//: param custom { "default": false, "label": "Frontal Light" }
uniform bool front_light;

//: param auto main_light
uniform vec4 light_main;

vec3 microfacets_brdf(
	vec3 Nn,
	vec3 Ln,
	vec3 Vn,
	vec3 Ks,
	float Roughness)
{
	vec3 Hn = normalize(Vn + Ln);
	float vdh = max( 0.0, dot(Vn, Hn) );
	float ndh = max( 0.0, dot(Nn, Hn) );
	float ndl = max( 0.0, dot(Nn, Ln) );
	float ndv = max( 0.0, dot(Nn, Vn) );
	return fresnel(vdh,Ks) *
		( normal_distrib(ndh,Roughness) * visibility(ndl,ndv,Roughness) / 4.0 );
}

vec3 pointLightContribution(
	vec3 fixedNormalWS,
	vec3 pointToLightDirWS,
	vec3 pointToCameraDirWS,
	vec3 diffColor,
	vec3 specColor,
	float roughness,
	vec3 LampColor)
{
	return  max(dot(fixedNormalWS,pointToLightDirWS), 0.0) * ( (
		(diffColor*(vec3(1.0,1.0,1.0)-specColor) * M_INV_PI)
		+ microfacets_brdf(
			fixedNormalWS,
			pointToLightDirWS,
			pointToCameraDirWS,
			specColor,
			roughness) ) *LampColor*M_PI);
}

// ACES Tonemapping

vec3 tonemapSCurve(vec3 x)
{
  	float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return clamp((x*(a*x+b))/(x*(c*x+d)+e),0.0,1.0);
}


//- Shader entry point.
void shade(V2F inputs)
{
	// Fetch material parameters, and conversion to the specular/glossiness model
	float roughness = getRoughness(roughness_tex, inputs.tex_coord);
	vec3 baseColor = getBaseColor(basecolor_tex, inputs.tex_coord);
	float metallic = getMetallic(metallic_tex, inputs.tex_coord);
  	float specularLevel = getSpecularLevel(specularlevel_tex, inputs.tex_coord);
	vec3 diffColor = generateDiffuseColor(baseColor, metallic);
	vec3 specColor = generateSpecularColor(specularLevel, baseColor, metallic);
	// Get detail (ambient occlusion) and global (shadow) occlusion factors
	float occlusion = getAO(inputs.tex_coord) * getShadowFactor();

	vec3 normal_vec = computeWSNormal(inputs.tex_coord, inputs.tangent, inputs.bitangent, inputs.normal);
	vec3 eye_vec = is_perspective ?
	normalize(camera_pos - inputs.position) :
	-camera_dir;

	vec3 sunIrradiance = vec3(1.0);//1e-4 * envSampleLOD(light_main.xyz, 0.0);
	vec3 sun_vec = normalize(light_main.xyz*100.0 - inputs.position);

	vec3 sunContrib = pointLightContribution(normal_vec, sun_vec, eye_vec, diffColor,	specColor, roughness, sunIrradiance * sun_strenght);

	vec3 front_lightContrib = pointLightContribution(normal_vec, eye_vec, eye_vec, diffColor,	specColor, roughness, vec3(1.0));

	// Feed parameters for a physically based BRDF integration
	//vec4 color = pbrComputeBRDF(inputs, diffColor, specColor, glossiness, occlusion);
  
  	LocalVectors vectors = computeLocalFrame(inputs);

    float specOcclusion = specularOcclusionCorrection(occlusion, metallic, roughness);
  	vec3 Emissive = pbrComputeEmissive(emissive_tex, inputs.tex_coord).rgb;
	vec3 SpecularShading = specOcclusion * pbrComputeSpecular(vectors, specColor, roughness);
	vec3 DiffuseShading = occlusion * envIrradiance(vectors.normal);
	vec3 color = Emissive + diffColor * DiffuseShading + SpecularShading;

	if (sun){
		//color *= 0.5;
		color += sunContrib;
	}

	if (front_light){
		color += front_lightContrib;
	}

	if (aces){
		color = tonemapSCurve(color);
	}
	emissiveColorOutput(pbrComputeEmissive(emissive_tex, inputs.tex_coord));
	albedoOutput(color.rgb);
	diffuseShadingOutput(vec3(1.0));
	specularShadingOutput(vec3(0.0));
}


