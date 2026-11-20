{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "52eeaf5ca947e177a667baaefefbdd9e30bcf8f98f8759d8120ce8dc6aae8b9c",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    float4 _167 = float4(_270, 1.0f);\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_shadow_pos = mul(_167, _131_fa_light_vp);\n    gl_Position = mul(_167, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _359_fa_camera_pos : packoffset(c0);\n    float4 _359_fa_ambient : packoffset(c1);\n    float4 _359_fa_base_color : packoffset(c2);\n    float4 _359_fa_emissive : packoffset(c3);\n    float4 _359_fa_model_emissive : packoffset(c4);\n    float4 _359_fa_pbr : packoffset(c5);\n    float4 _359_fa_maps : packoffset(c6);\n    float4 _359_fa_fog : packoffset(c7);\n    float4 _359_fa_fog_b : packoffset(c8);\n    float4 _359_fa_fog_c : packoffset(c9);\n    float4 _359_fa_counts : packoffset(c10);\n    float4 _359_fa_env_sky : packoffset(c11);\n    float4 _359_fa_env_horizon : packoffset(c12);\n    float4 _359_fa_time : packoffset(c13);\n    float4 _359_fa_cl_vpx : packoffset(c14);\n    float4 _359_fa_cl_vpy : packoffset(c15);\n    float4 _359_fa_cl_vpw : packoffset(c16);\n    float4 _359_fa_cl_fwd : packoffset(c17);\n    float4 _359_fa_cl_grid : packoffset(c18);\n    float4 _359_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _364 = _359_fa_cl_info.x < 0.0f;\n    bool _371;\n    if (!_364)\n    {\n        _371 = _359_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _371 = _364;\n    }\n    bool _379;\n    if (!_371)\n    {\n        _379 = _359_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _379 = _371;\n    }\n    bool _386;\n    if (!_379)\n    {\n        _386 = _359_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _386 = _379;\n    }\n    bool _393;\n    if (!_386)\n    {\n        _393 = _359_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _393 = _386;\n    }\n    if (_393)\n    {\n        return int2(0, 0);\n    }\n    float4 _403 = float4(world_pos, 1.0f);\n    float _410 = dot(_359_fa_cl_vpw, _403);\n    if (!(_410 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _433 = float2(dot(_359_fa_cl_vpx, _403), dot(_359_fa_cl_vpy, _403)) / _410.xx;\n    int _437 = int(_359_fa_cl_grid.x);\n    int _441 = int(_359_fa_cl_grid.y);\n    int param = (int(_359_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_359_fa_cl_fwd.xyz, world_pos) + _359_fa_cl_fwd.w, _359_fa_cl_grid.w) / _359_fa_cl_grid.w) * _359_fa_cl_grid.z)), 0, int(_359_fa_cl_info.y) - 1) * _441) + clamp(int(floor(((_433.y * 0.5f) + 0.5f) * _359_fa_cl_grid.y)), 0, _441 - 1)) * _437)) + clamp(int(floor(((_433.x * 0.5f) + 0.5f) * _359_fa_cl_grid.x)), 0, _437 - 1);\n    float4 _512 = fa_light_texel(param);\n    return int2(int(_512.x), int(_512.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_359_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _919 = fa_cluster_lookup(param);\n    fa_cl_slot = _919.x;\n    fa_cl_local = _919.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1029 = fa_linear_to_srgb(param);\n        c = _1029;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1037 = fa_srgb_to_linear(param_1);\n            c = _1037;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _140;\n    if (i.front_facing)\n    {\n        _140 = i.world_normal;\n    }\n    else\n    {\n        _140 = -i.world_normal;\n    }\n    float3 _164 = normalize(i.world_tangent.xyz - (_140 * dot(_140, i.world_tangent.xyz)));\n    float3 _192 = normalize(((_164 * m.x) + ((cross(_140, _164) * i.world_tangent.w) * m.y)) + (_140 * m.z));\n    float3 _195;\n    if (i.front_facing)\n    {\n        _195 = _192;\n    }\n    else\n    {\n        _195 = -_192;\n    }\n    return _195;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _359_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1069 = fa_tex_fix(param_2, param_3);\n    float4 _1775 = base_t;\n    _1775.x = _1069.x;\n    _1775.y = _1069.y;\n    _1775.z = _1069.z;\n    base_t = _1775;\n    float4 _1083 = (_1775 * _359_fa_base_color) * i.vertex_color;\n    float3 _1734 = i.world_normal;\n    if (_359_fa_maps.z > 0.5f)\n    {\n        float param_4 = _359_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1116 = fa_tex_fix(param_6, param_7);\n        float3 _1119 = (_1116 * 2.0f) - 1.0f.xxx;\n        float2 _1124 = _1119.xy * _359_fa_maps.x;\n        float3 _1783 = _1119;\n        _1783.x = _1124.x;\n        _1783.y = _1124.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1783;\n        _1734 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _359_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1153 = fa_tex_fix(param_12, param_13);\n    float4 _1786 = mrt;\n    _1786.x = _1153.x;\n    _1786.y = _1153.y;\n    _1786.z = _1153.z;\n    mrt = _1786;\n    float param_14 = _359_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1192 = fa_tex_fix(param_16, param_17);\n    float param_18 = _359_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1219 = fa_tex_fix(param_20, param_21);\n    Surface _1746 = { _1083.xyz, _1083.w, _1734, clamp(_359_fa_pbr.x * _1153.z, 0.0f, 1.0f), clamp(_359_fa_pbr.y * _1153.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_359_fa_maps.y * (_1192.x - 1.0f)), _359_fa_emissive.xyz + (_359_fa_model_emissive.xyz * _1219) };\n    return _1746;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_359_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _359_fa_ambient.xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _818 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _821 = _818.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_821 * _821, exp2((-9.27999973297119140625f) * ndv)) * _821) + _818.y)) + _818.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_359_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _359_fa_env_horizon.w).xyz;\n    }\n    float _721 = rough * rough;\n    float _752 = 0.60000002384185791015625f * _721;\n    return lerp(lerp(_359_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_359_fa_env_horizon.xyz, _359_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _721)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _752, 0.0500000007450580596923828125f + _752, d.y).xxx), ((_359_fa_env_sky.xyz + _359_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_721 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _860 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _860.x) + _860.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float3 param = normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = lerp(0.039999999105930328369140625f.xxx, s.albedo, clamp(s.metallic, 0.0f, 1.0f).xxx);\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_359_fa_cl_info.x) + int(_359_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _232 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _238 = fa_light_texel(param_1);\n    float _241 = _238.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _248 = _241 < 0.5f;\n    float3 l;\n    if (_248)\n    {\n        l = normalize(_232.xyz);\n    }\n    else\n    {\n        float3 _260 = _232.xyz - world_pos;\n        float _262 = length(_260);\n        dist = _262;\n        l = _260 / max(_262, 9.9999997473787516355514526367188e-05f).xxx;\n        float _277 = _262 / max(_232.w, 0.001000000047497451305389404296875f);\n        float _283 = clamp(1.0f - (_277 * _277), 0.0f, 1.0f);\n        atten = _283 * _283;\n        if (_241 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _297 = fa_light_texel(param_2);\n            float _307 = _297.w;\n            int param_3 = (li * 4) + 3;\n            float4 _314 = fa_light_texel(param_3);\n            float _315 = _314.x;\n            float cos_inner = _315;\n            if (_315 > 1.5f)\n            {\n                cos_inner = lerp(_307, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_307, cos_inner, dot(-l, normalize(_297.xyz)));\n        }\n    }\n    int _345;\n    if (_248)\n    {\n        _345 = 0;\n    }\n    else\n    {\n        _345 = (_241 > 1.5f) ? 2 : 1;\n    }\n    LightSample _1712 = { l, _238.xyz * atten, atten, 1.0f, dist, _345 };\n    return _1712;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_359_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _558 = coord.xyz / coord.w.xxx;\n    float3 p = _558;\n    float2 suv = (_558.xy * 0.5f) + 0.5f.xx;\n    if (_359_fa_counts.z > 0.5f)\n    {\n        float3 _1755 = p;\n        _1755.z = (_1755.z * 0.5f) + 0.5f;\n        p = _1755;\n    }\n    else\n    {\n        float2 _1758 = suv;\n        _1758.y = 1.0f - _1758.y;\n        suv = _1758;\n    }\n    bool _584 = suv.x < 0.0f;\n    bool _591;\n    if (!_584)\n    {\n        _591 = suv.x > 1.0f;\n    }\n    else\n    {\n        _591 = _584;\n    }\n    bool _598;\n    if (!_591)\n    {\n        _598 = suv.y < 0.0f;\n    }\n    else\n    {\n        _598 = _591;\n    }\n    bool _605;\n    if (!_598)\n    {\n        _605 = suv.y > 1.0f;\n    }\n    else\n    {\n        _605 = _598;\n    }\n    bool _612;\n    if (!_605)\n    {\n        _612 = p.z > 1.0f;\n    }\n    else\n    {\n        _612 = _605;\n    }\n    if (_612)\n    {\n        return 1.0f;\n    }\n    float _627 = _359_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _627) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _359_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _947 = fa_light_sample(param, param_1);\n    float3 _1719 = _947.direction;\n    float3 _1714 = _947.color;\n    float _1716 = _947.shadow;\n    int _1724 = _947.type;\n    if ((_1724 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1719;\n        float _961 = fa_shadow_factor(param_2, param_3);\n        _1716 = _961;\n        _1714 *= _961;\n    }\n    LightSample _1731 = { _1719, _1714, _947.attenuation, _1716, _947._distance, _1724 };\n    return _1731;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1597 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1597 = -_1597;\n    }\n    float3 _1264 = normalize(_359_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _1610 = { fa_world_pos, _1597, fa_world_tangent, fa_uv, fa_vertex_color, _1264, gl_FrontFacing };\n    SurfaceInput param_1 = _1610;\n    Surface _1272 = fa_standard_surface(param_1);\n    float3 _1636 = _1272.albedo;\n    float _1637 = _1272.alpha;\n    float3 _1638 = _1272.normal;\n    float _1639 = _1272.metallic;\n    float _1640 = _1272.roughness;\n    float _1641 = _1272.occlusion;\n    float3 _1642 = _1272.emission;\n    SurfaceInput _1618 = { fa_world_pos, _1597, fa_world_tangent, fa_uv, fa_vertex_color, _1264, gl_FrontFacing };\n    SurfaceInput param_2 = _1618;\n    Surface param_3 = _1272;\n    surface(param_2, param_3);\n    _1636 = param_3.albedo;\n    _1637 = param_3.alpha;\n    _1638 = param_3.normal;\n    _1639 = param_3.metallic;\n    _1640 = param_3.roughness;\n    _1641 = param_3.occlusion;\n    _1642 = param_3.emission;\n    float3 result;\n    if (_359_fa_emissive.w > 0.5f)\n    {\n        result = _1636;\n    }\n    else\n    {\n        float3 _1293 = _1638;\n        float3 _1294 = normalize(_1293);\n        _1638 = _1294;\n        float3 param_4 = _1294;\n        SurfaceInput _1626 = { fa_world_pos, _1597, fa_world_tangent, fa_uv, fa_vertex_color, _1264, gl_FrontFacing };\n        SurfaceInput param_5 = _1626;\n        Surface _1672 = { _1636, _1637, _1638, _1639, _1640, _1641, _1642 };\n        Surface param_6 = _1672;\n        float3 param_7 = fa_ambient_light(param_4);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _1313 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1313; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8);\n            float3 param_10 = fa_world_pos;\n            float3 param_11 = _1597;\n            SurfaceInput _1634 = { fa_world_pos, _1597, fa_world_tangent, fa_uv, fa_vertex_color, _1264, gl_FrontFacing };\n            SurfaceInput param_12 = _1634;\n            Surface _1680 = { _1636, _1637, _1638, _1639, _1640, _1641, _1642 };\n            Surface param_13 = _1680;\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    result += _1642;\n    bool _1355 = _359_fa_fog.w > 0.0f;\n    bool _1363;\n    if (!_1355)\n    {\n        _1363 = _359_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1363 = _1355;\n    }\n    if (_1363)\n    {\n        float3 _1372 = fa_world_pos - _359_fa_camera_pos.xyz;\n        float _1379 = dot(_1372, _359_fa_fog_c.xyz);\n        bool _1383 = _359_fa_fog_c.w > 0.5f;\n        float _1384;\n        if (_1383)\n        {\n            _1384 = _1379;\n        }\n        else\n        {\n            _1384 = length(_1372);\n        }\n        float _1396 = _1384 - _359_fa_fog_b.x;\n        if (_1396 > 0.0f)\n        {\n            float _1405 = _359_fa_fog.w * _1396;\n            float tau = _1405 * _1405;\n            if (_359_fa_fog_b.y > 0.0f)\n            {\n                float _1421;\n                if (_1383)\n                {\n                    _1421 = fa_world_pos.y - (_359_fa_fog_c.y * _1379);\n                }\n                else\n                {\n                    _1421 = _359_fa_camera_pos.y;\n                }\n                float _1442 = lerp(_1421, fa_world_pos.y, clamp(_359_fa_fog_b.x / _1384, 0.0f, 1.0f));\n                float _1446 = fa_world_pos.y - _1442;\n                float _1451 = _1442 - _359_fa_fog_b.z;\n                float _1456 = fa_world_pos.y - _359_fa_fog_b.z;\n                bool _1459 = _1451 <= 0.0f;\n                bool _1460 = !_1459;\n                bool _1466;\n                if (_1460)\n                {\n                    _1466 = _359_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1466 = _1459;\n                }\n                float _1467;\n                if (_1466)\n                {\n                    _1467 = _359_fa_fog_b.y;\n                }\n                else\n                {\n                    _1467 = _359_fa_fog_b.y * exp(-min(_359_fa_fog_b.w * _1451, 80.0f));\n                }\n                bool _1494;\n                if (_1460)\n                {\n                    _1494 = _359_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1494 = _1459;\n                }\n                float _1495;\n                if (_1494)\n                {\n                    _1495 = _359_fa_fog_b.y * _1451;\n                }\n                else\n                {\n                    _1495 = (_359_fa_fog_b.y * (1.0f - exp(-min(_359_fa_fog_b.w * _1451, 80.0f)))) / _359_fa_fog_b.w;\n                }\n                bool _1520 = _1456 <= 0.0f;\n                bool _1527;\n                if (!_1520)\n                {\n                    _1527 = _359_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1527 = _1520;\n                }\n                float _1528;\n                if (_1527)\n                {\n                    _1528 = _359_fa_fog_b.y * _1456;\n                }\n                else\n                {\n                    _1528 = (_359_fa_fog_b.y * (1.0f - exp(-min(_359_fa_fog_b.w * _1456, 80.0f)))) / _359_fa_fog_b.w;\n                }\n                float _1555;\n                if (abs(_1446) < 0.001000000047497451305389404296875f)\n                {\n                    _1555 = _1467;\n                }\n                else\n                {\n                    _1555 = (_1528 - _1495) / _1446;\n                }\n                tau += (_1396 * max(_1555, 0.0f));\n            }\n            result = lerp(result, _359_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1637);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_359",
            "hlsl_register_b_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 2
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 3
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 4
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 6
            }
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 7
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 8
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 10
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _384 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _384;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _391 = _273.world_pos;\n    float4 _280 = float4(_391, 1.0f);\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_shadow_pos = mul(_280, _136_fa_light_vp);\n    gl_Position = mul(_280, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _359_fa_camera_pos : packoffset(c0);\n    float4 _359_fa_ambient : packoffset(c1);\n    float4 _359_fa_base_color : packoffset(c2);\n    float4 _359_fa_emissive : packoffset(c3);\n    float4 _359_fa_model_emissive : packoffset(c4);\n    float4 _359_fa_pbr : packoffset(c5);\n    float4 _359_fa_maps : packoffset(c6);\n    float4 _359_fa_fog : packoffset(c7);\n    float4 _359_fa_fog_b : packoffset(c8);\n    float4 _359_fa_fog_c : packoffset(c9);\n    float4 _359_fa_counts : packoffset(c10);\n    float4 _359_fa_env_sky : packoffset(c11);\n    float4 _359_fa_env_horizon : packoffset(c12);\n    float4 _359_fa_time : packoffset(c13);\n    float4 _359_fa_cl_vpx : packoffset(c14);\n    float4 _359_fa_cl_vpy : packoffset(c15);\n    float4 _359_fa_cl_vpw : packoffset(c16);\n    float4 _359_fa_cl_fwd : packoffset(c17);\n    float4 _359_fa_cl_grid : packoffset(c18);\n    float4 _359_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _364 = _359_fa_cl_info.x < 0.0f;\n    bool _371;\n    if (!_364)\n    {\n        _371 = _359_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _371 = _364;\n    }\n    bool _379;\n    if (!_371)\n    {\n        _379 = _359_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _379 = _371;\n    }\n    bool _386;\n    if (!_379)\n    {\n        _386 = _359_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _386 = _379;\n    }\n    bool _393;\n    if (!_386)\n    {\n        _393 = _359_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _393 = _386;\n    }\n    if (_393)\n    {\n        return int2(0, 0);\n    }\n    float4 _403 = float4(world_pos, 1.0f);\n    float _410 = dot(_359_fa_cl_vpw, _403);\n    if (!(_410 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _433 = float2(dot(_359_fa_cl_vpx, _403), dot(_359_fa_cl_vpy, _403)) / _410.xx;\n    int _437 = int(_359_fa_cl_grid.x);\n    int _441 = int(_359_fa_cl_grid.y);\n    int param = (int(_359_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_359_fa_cl_fwd.xyz, world_pos) + _359_fa_cl_fwd.w, _359_fa_cl_grid.w) / _359_fa_cl_grid.w) * _359_fa_cl_grid.z)), 0, int(_359_fa_cl_info.y) - 1) * _441) + clamp(int(floor(((_433.y * 0.5f) + 0.5f) * _359_fa_cl_grid.y)), 0, _441 - 1)) * _437)) + clamp(int(floor(((_433.x * 0.5f) + 0.5f) * _359_fa_cl_grid.x)), 0, _437 - 1);\n    float4 _512 = fa_light_texel(param);\n    return int2(int(_512.x), int(_512.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_359_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _919 = fa_cluster_lookup(param);\n    fa_cl_slot = _919.x;\n    fa_cl_local = _919.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1029 = fa_linear_to_srgb(param);\n        c = _1029;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1037 = fa_srgb_to_linear(param_1);\n            c = _1037;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _140;\n    if (i.front_facing)\n    {\n        _140 = i.world_normal;\n    }\n    else\n    {\n        _140 = -i.world_normal;\n    }\n    float3 _164 = normalize(i.world_tangent.xyz - (_140 * dot(_140, i.world_tangent.xyz)));\n    float3 _192 = normalize(((_164 * m.x) + ((cross(_140, _164) * i.world_tangent.w) * m.y)) + (_140 * m.z));\n    float3 _195;\n    if (i.front_facing)\n    {\n        _195 = _192;\n    }\n    else\n    {\n        _195 = -_192;\n    }\n    return _195;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _359_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1069 = fa_tex_fix(param_2, param_3);\n    float4 _1775 = base_t;\n    _1775.x = _1069.x;\n    _1775.y = _1069.y;\n    _1775.z = _1069.z;\n    base_t = _1775;\n    float4 _1083 = (_1775 * _359_fa_base_color) * i.vertex_color;\n    float3 _1734 = i.world_normal;\n    if (_359_fa_maps.z > 0.5f)\n    {\n        float param_4 = _359_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1116 = fa_tex_fix(param_6, param_7);\n        float3 _1119 = (_1116 * 2.0f) - 1.0f.xxx;\n        float2 _1124 = _1119.xy * _359_fa_maps.x;\n        float3 _1783 = _1119;\n        _1783.x = _1124.x;\n        _1783.y = _1124.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1783;\n        _1734 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _359_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1153 = fa_tex_fix(param_12, param_13);\n    float4 _1786 = mrt;\n    _1786.x = _1153.x;\n    _1786.y = _1153.y;\n    _1786.z = _1153.z;\n    mrt = _1786;\n    float param_14 = _359_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1192 = fa_tex_fix(param_16, param_17);\n    float param_18 = _359_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1219 = fa_tex_fix(param_20, param_21);\n    Surface _1746 = { _1083.xyz, _1083.w, _1734, clamp(_359_fa_pbr.x * _1153.z, 0.0f, 1.0f), clamp(_359_fa_pbr.y * _1153.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_359_fa_maps.y * (_1192.x - 1.0f)), _359_fa_emissive.xyz + (_359_fa_model_emissive.xyz * _1219) };\n    return _1746;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_359_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _359_fa_ambient.xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _818 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _821 = _818.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_821 * _821, exp2((-9.27999973297119140625f) * ndv)) * _821) + _818.y)) + _818.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_359_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _359_fa_env_horizon.w).xyz;\n    }\n    float _721 = rough * rough;\n    float _752 = 0.60000002384185791015625f * _721;\n    return lerp(lerp(_359_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_359_fa_env_horizon.xyz, _359_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _721)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _752, 0.0500000007450580596923828125f + _752, d.y).xxx), ((_359_fa_env_sky.xyz + _359_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_721 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _860 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _860.x) + _860.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float3 param = normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = lerp(0.039999999105930328369140625f.xxx, s.albedo, clamp(s.metallic, 0.0f, 1.0f).xxx);\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_359_fa_cl_info.x) + int(_359_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _232 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _238 = fa_light_texel(param_1);\n    float _241 = _238.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _248 = _241 < 0.5f;\n    float3 l;\n    if (_248)\n    {\n        l = normalize(_232.xyz);\n    }\n    else\n    {\n        float3 _260 = _232.xyz - world_pos;\n        float _262 = length(_260);\n        dist = _262;\n        l = _260 / max(_262, 9.9999997473787516355514526367188e-05f).xxx;\n        float _277 = _262 / max(_232.w, 0.001000000047497451305389404296875f);\n        float _283 = clamp(1.0f - (_277 * _277), 0.0f, 1.0f);\n        atten = _283 * _283;\n        if (_241 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _297 = fa_light_texel(param_2);\n            float _307 = _297.w;\n            int param_3 = (li * 4) + 3;\n            float4 _314 = fa_light_texel(param_3);\n            float _315 = _314.x;\n            float cos_inner = _315;\n            if (_315 > 1.5f)\n            {\n                cos_inner = lerp(_307, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_307, cos_inner, dot(-l, normalize(_297.xyz)));\n        }\n    }\n    int _345;\n    if (_248)\n    {\n        _345 = 0;\n    }\n    else\n    {\n        _345 = (_241 > 1.5f) ? 2 : 1;\n    }\n    LightSample _1712 = { l, _238.xyz * atten, atten, 1.0f, dist, _345 };\n    return _1712;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_359_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _558 = coord.xyz / coord.w.xxx;\n    float3 p = _558;\n    float2 suv = (_558.xy * 0.5f) + 0.5f.xx;\n    if (_359_fa_counts.z > 0.5f)\n    {\n        float3 _1755 = p;\n        _1755.z = (_1755.z * 0.5f) + 0.5f;\n        p = _1755;\n    }\n    else\n    {\n        float2 _1758 = suv;\n        _1758.y = 1.0f - _1758.y;\n        suv = _1758;\n    }\n    bool _584 = suv.x < 0.0f;\n    bool _591;\n    if (!_584)\n    {\n        _591 = suv.x > 1.0f;\n    }\n    else\n    {\n        _591 = _584;\n    }\n    bool _598;\n    if (!_591)\n    {\n        _598 = suv.y < 0.0f;\n    }\n    else\n    {\n        _598 = _591;\n    }\n    bool _605;\n    if (!_598)\n    {\n        _605 = suv.y > 1.0f;\n    }\n    else\n    {\n        _605 = _598;\n    }\n    bool _612;\n    if (!_605)\n    {\n        _612 = p.z > 1.0f;\n    }\n    else\n    {\n        _612 = _605;\n    }\n    if (_612)\n    {\n        return 1.0f;\n    }\n    float _627 = _359_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _627) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _359_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _947 = fa_light_sample(param, param_1);\n    float3 _1719 = _947.direction;\n    float3 _1714 = _947.color;\n    float _1716 = _947.shadow;\n    int _1724 = _947.type;\n    if ((_1724 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1719;\n        float _961 = fa_shadow_factor(param_2, param_3);\n        _1716 = _961;\n        _1714 *= _961;\n    }\n    LightSample _1731 = { _1719, _1714, _947.attenuation, _1716, _947._distance, _1724 };\n    return _1731;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1597 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1597 = -_1597;\n    }\n    float3 _1264 = normalize(_359_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _1610 = { fa_world_pos, _1597, fa_world_tangent, fa_uv, fa_vertex_color, _1264, gl_FrontFacing };\n    SurfaceInput param_1 = _1610;\n    Surface _1272 = fa_standard_surface(param_1);\n    float3 _1636 = _1272.albedo;\n    float _1637 = _1272.alpha;\n    float3 _1638 = _1272.normal;\n    float _1639 = _1272.metallic;\n    float _1640 = _1272.roughness;\n    float _1641 = _1272.occlusion;\n    float3 _1642 = _1272.emission;\n    SurfaceInput _1618 = { fa_world_pos, _1597, fa_world_tangent, fa_uv, fa_vertex_color, _1264, gl_FrontFacing };\n    SurfaceInput param_2 = _1618;\n    Surface param_3 = _1272;\n    surface(param_2, param_3);\n    _1636 = param_3.albedo;\n    _1637 = param_3.alpha;\n    _1638 = param_3.normal;\n    _1639 = param_3.metallic;\n    _1640 = param_3.roughness;\n    _1641 = param_3.occlusion;\n    _1642 = param_3.emission;\n    float3 result;\n    if (_359_fa_emissive.w > 0.5f)\n    {\n        result = _1636;\n    }\n    else\n    {\n        float3 _1293 = _1638;\n        float3 _1294 = normalize(_1293);\n        _1638 = _1294;\n        float3 param_4 = _1294;\n        SurfaceInput _1626 = { fa_world_pos, _1597, fa_world_tangent, fa_uv, fa_vertex_color, _1264, gl_FrontFacing };\n        SurfaceInput param_5 = _1626;\n        Surface _1672 = { _1636, _1637, _1638, _1639, _1640, _1641, _1642 };\n        Surface param_6 = _1672;\n        float3 param_7 = fa_ambient_light(param_4);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _1313 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1313; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8);\n            float3 param_10 = fa_world_pos;\n            float3 param_11 = _1597;\n            SurfaceInput _1634 = { fa_world_pos, _1597, fa_world_tangent, fa_uv, fa_vertex_color, _1264, gl_FrontFacing };\n            SurfaceInput param_12 = _1634;\n            Surface _1680 = { _1636, _1637, _1638, _1639, _1640, _1641, _1642 };\n            Surface param_13 = _1680;\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    result += _1642;\n    bool _1355 = _359_fa_fog.w > 0.0f;\n    bool _1363;\n    if (!_1355)\n    {\n        _1363 = _359_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1363 = _1355;\n    }\n    if (_1363)\n    {\n        float3 _1372 = fa_world_pos - _359_fa_camera_pos.xyz;\n        float _1379 = dot(_1372, _359_fa_fog_c.xyz);\n        bool _1383 = _359_fa_fog_c.w > 0.5f;\n        float _1384;\n        if (_1383)\n        {\n            _1384 = _1379;\n        }\n        else\n        {\n            _1384 = length(_1372);\n        }\n        float _1396 = _1384 - _359_fa_fog_b.x;\n        if (_1396 > 0.0f)\n        {\n            float _1405 = _359_fa_fog.w * _1396;\n            float tau = _1405 * _1405;\n            if (_359_fa_fog_b.y > 0.0f)\n            {\n                float _1421;\n                if (_1383)\n                {\n                    _1421 = fa_world_pos.y - (_359_fa_fog_c.y * _1379);\n                }\n                else\n                {\n                    _1421 = _359_fa_camera_pos.y;\n                }\n                float _1442 = lerp(_1421, fa_world_pos.y, clamp(_359_fa_fog_b.x / _1384, 0.0f, 1.0f));\n                float _1446 = fa_world_pos.y - _1442;\n                float _1451 = _1442 - _359_fa_fog_b.z;\n                float _1456 = fa_world_pos.y - _359_fa_fog_b.z;\n                bool _1459 = _1451 <= 0.0f;\n                bool _1460 = !_1459;\n                bool _1466;\n                if (_1460)\n                {\n                    _1466 = _359_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1466 = _1459;\n                }\n                float _1467;\n                if (_1466)\n                {\n                    _1467 = _359_fa_fog_b.y;\n                }\n                else\n                {\n                    _1467 = _359_fa_fog_b.y * exp(-min(_359_fa_fog_b.w * _1451, 80.0f));\n                }\n                bool _1494;\n                if (_1460)\n                {\n                    _1494 = _359_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1494 = _1459;\n                }\n                float _1495;\n                if (_1494)\n                {\n                    _1495 = _359_fa_fog_b.y * _1451;\n                }\n                else\n                {\n                    _1495 = (_359_fa_fog_b.y * (1.0f - exp(-min(_359_fa_fog_b.w * _1451, 80.0f)))) / _359_fa_fog_b.w;\n                }\n                bool _1520 = _1456 <= 0.0f;\n                bool _1527;\n                if (!_1520)\n                {\n                    _1527 = _359_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1527 = _1520;\n                }\n                float _1528;\n                if (_1527)\n                {\n                    _1528 = _359_fa_fog_b.y * _1456;\n                }\n                else\n                {\n                    _1528 = (_359_fa_fog_b.y * (1.0f - exp(-min(_359_fa_fog_b.w * _1456, 80.0f)))) / _359_fa_fog_b.w;\n                }\n                float _1555;\n                if (abs(_1446) < 0.001000000047497451305389404296875f)\n                {\n                    _1555 = _1467;\n                }\n                else\n                {\n                    _1555 = (_1528 - _1495) / _1446;\n                }\n                tau += (_1396 * max(_1555, 0.0f));\n            }\n            result = lerp(result, _359_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1637);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 9
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 10
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_359",
            "hlsl_register_b_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 2
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 3
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 4
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 6
            }
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 7
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 8
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 10
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _587 = base_t;\n    _587.x = _225.x;\n    _587.y = _225.y;\n    _587.z = _225.z;\n    base_t = _587;\n    float4 _241 = (_587 * _213_fa_base_color) * i.vertex_color;\n    float3 _568 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _595 = _279;\n        _595.x = _284.x;\n        _595.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _595;\n        _568 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _598 = mrt;\n    _598.x = _313.x;\n    _598.y = _313.y;\n    _598.z = _313.z;\n    mrt = _598;\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    Surface _580 = { _241.xyz, _241.w, _568, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_354.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _381) };\n    return _580;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _515 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _515 = -_515;\n    }\n    float3 _427 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _528 = { fa_world_pos, _515, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param = _528;\n    SurfaceInput _536 = { fa_world_pos, _515, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param_1 = _536;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _442 = normalize(param_2.normal);\n    float3 _457 = normalize(float3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / ((abs(_457.x) + abs(_457.y)) + abs(_469)).xx;\n    if (_469 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "hlsl_register_b_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 1
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 2
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 3
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 4
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _413 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _413;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0f);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _587 = base_t;\n    _587.x = _225.x;\n    _587.y = _225.y;\n    _587.z = _225.z;\n    base_t = _587;\n    float4 _241 = (_587 * _213_fa_base_color) * i.vertex_color;\n    float3 _568 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _595 = _279;\n        _595.x = _284.x;\n        _595.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _595;\n        _568 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _598 = mrt;\n    _598.x = _313.x;\n    _598.y = _313.y;\n    _598.z = _313.z;\n    mrt = _598;\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    Surface _580 = { _241.xyz, _241.w, _568, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_354.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _381) };\n    return _580;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _515 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _515 = -_515;\n    }\n    float3 _427 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _528 = { fa_world_pos, _515, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param = _528;\n    SurfaceInput _536 = { fa_world_pos, _515, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param_1 = _536;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _442 = normalize(param_2.normal);\n    float3 _457 = normalize(float3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / ((abs(_457.x) + abs(_457.y)) + abs(_469)).xx;\n    if (_469 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 9
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 10
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "hlsl_register_b_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 1
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 2
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 3
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 4
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          }
        ]
      }
    }
  }
}
