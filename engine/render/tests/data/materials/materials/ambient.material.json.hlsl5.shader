{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "7cd31c28ac6572768802838498bbbd3180b96e0a1bb1bab7ad49d1d6af9d528c",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _258 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _258;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_265, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _394_fa_camera_pos : packoffset(c0);\n    float4 _394_fa_ambient : packoffset(c1);\n    float4 _394_fa_base_color : packoffset(c2);\n    float4 _394_fa_emissive : packoffset(c3);\n    float4 _394_fa_model_emissive : packoffset(c4);\n    float4 _394_fa_pbr : packoffset(c5);\n    float4 _394_fa_maps : packoffset(c6);\n    float4 _394_fa_fog : packoffset(c7);\n    float4 _394_fa_fog_b : packoffset(c8);\n    float4 _394_fa_fog_c : packoffset(c9);\n    float4 _394_fa_counts : packoffset(c10);\n    float4 _394_fa_env_sky : packoffset(c11);\n    float4 _394_fa_env_horizon : packoffset(c12);\n    float4 _394_fa_time : packoffset(c13);\n    float4 _394_fa_cl_vpx : packoffset(c14);\n    float4 _394_fa_cl_vpy : packoffset(c15);\n    float4 _394_fa_cl_vpw : packoffset(c16);\n    float4 _394_fa_cl_fwd : packoffset(c17);\n    float4 _394_fa_cl_grid : packoffset(c18);\n    float4 _394_fa_cl_info : packoffset(c19);\n    float4 _394_fa_layers_a : packoffset(c20);\n    float4 _394_fa_layers_b : packoffset(c21);\n    float4 _394_fa_layers_c : packoffset(c22);\n    float4 _394_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _630_fa_shadow_mat[4] : packoffset(c0);\n    float4 _630_fa_shadow_rect[4] : packoffset(c16);\n    float4 _630_fa_shadow_info[4] : packoffset(c20);\n    float4 _630_fa_shadow_split : packoffset(c24);\n    float4 _630_fa_shadow_cfg : packoffset(c25);\n    float4 _630_fa_shadow_bias : packoffset(c26);\n    float4 _630_fa_shadow_eye : packoffset(c27);\n    float4 _630_fa_shadow_fwd : packoffset(c28);\n    float4 _630_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _399 = _394_fa_cl_info.x < 0.0f;\n    bool _406;\n    if (!_399)\n    {\n        _406 = _394_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = _394_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = _394_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = _394_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return int2(0, 0);\n    }\n    float4 _438 = float4(world_pos, 1.0f);\n    float _445 = dot(_394_fa_cl_vpw, _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _467 = float2(dot(_394_fa_cl_vpx, _438), dot(_394_fa_cl_vpy, _438)) / _445.xx;\n    int _471 = int(_394_fa_cl_grid.x);\n    int _475 = int(_394_fa_cl_grid.y);\n    int param = (int(_394_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_394_fa_cl_fwd.xyz, world_pos) + _394_fa_cl_fwd.w, _394_fa_cl_grid.w) / _394_fa_cl_grid.w) * _394_fa_cl_grid.z)), 0, int(_394_fa_cl_info.y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5f) + 0.5f) * _394_fa_cl_grid.y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5f) + 0.5f) * _394_fa_cl_grid.x)), 0, _471 - 1);\n    float4 _546 = fa_light_texel(param);\n    return int2(int(_546.x), int(_546.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_394_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1674 = fa_cluster_lookup(param);\n    fa_cl_slot = _1674.x;\n    fa_cl_local = _1674.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1810 = fa_linear_to_srgb(param);\n        c = _1810;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1818 = fa_srgb_to_linear(param_1);\n            c = _1818;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _175;\n    if (i.front_facing)\n    {\n        _175 = i.world_normal;\n    }\n    else\n    {\n        _175 = -i.world_normal;\n    }\n    float3 _199 = normalize(i.world_tangent.xyz - (_175 * dot(_175, i.world_tangent.xyz)));\n    float3 _227 = normalize(((_199 * m.x) + ((cross(_175, _199) * i.world_tangent.w) * m.y)) + (_175 * m.z));\n    float3 _230;\n    if (i.front_facing)\n    {\n        _230 = _227;\n    }\n    else\n    {\n        _230 = -_227;\n    }\n    return _230;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _394_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1849 = fa_tex_fix(param_2, param_3);\n    float4 _2792 = base_t;\n    _2792.x = _1849.x;\n    _2792.y = _1849.y;\n    _2792.z = _1849.z;\n    base_t = _2792;\n    float4 _1863 = (_2792 * _394_fa_base_color) * i.vertex_color;\n    float3 _2707 = i.world_normal;\n    if (_394_fa_maps.z > 0.5f)\n    {\n        float param_4 = _394_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1895 = fa_tex_fix(param_6, param_7);\n        float3 _1899 = (_1895 * 2.0f) - 1.0f.xxx;\n        float2 _1904 = _1899.xy * _394_fa_maps.x;\n        float3 _2800 = _1899;\n        _2800.x = _1904.x;\n        _2800.y = _1904.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2800;\n        _2707 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _394_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1933 = fa_tex_fix(param_12, param_13);\n    float4 _2803 = mrt;\n    _2803.x = _1933.x;\n    _2803.y = _1933.y;\n    _2803.z = _1933.z;\n    mrt = _2803;\n    float4 _1962 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _394_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _1962.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1974 = fa_tex_fix(param_16, param_17);\n    float param_18 = _394_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2004 = fa_tex_fix(param_20, param_21);\n    float _2712 = _394_fa_layers_a.x;\n    float _2713 = _394_fa_layers_a.y;\n    float _2716 = _394_fa_layers_a.z;\n    float _2715 = _394_fa_layers_b.w;\n    float _2718 = _394_fa_layers_c.x;\n    if (_394_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_394_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _2712 *= _1974.y;\n            _2713 *= _1974.z;\n            _2715 *= _1962.w;\n        }\n        if (_394_fa_layers_c.z > 1.5f)\n        {\n            _2716 *= mrt.x;\n            _2718 *= mrt.w;\n        }\n    }\n    Surface _2737 = { _1863.xyz, _1863.w, _2707, clamp(_394_fa_pbr.x * _1933.z, 0.0f, 1.0f), clamp(_394_fa_pbr.y * _1933.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_394_fa_maps.y * (_1974.x - 1.0f)), _394_fa_emissive.xyz + (_394_fa_model_emissive.xyz * _2004), _2712, _2713, _394_fa_layers_b.xyz, _2715, _2716, _394_fa_layers_a.w, _2718, _394_fa_layers_c.y, _394_fa_layers_d.xyz };\n    return _2737;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_394_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _394_fa_ambient.xyz;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_394_fa_cl_info.x) + int(_394_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _267 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _273 = fa_light_texel(param_1);\n    float _276 = _273.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _283 = _276 < 0.5f;\n    float3 l;\n    if (_283)\n    {\n        l = normalize(_267.xyz);\n    }\n    else\n    {\n        float3 _295 = _267.xyz - world_pos;\n        float _297 = length(_295);\n        dist = _297;\n        l = _295 / max(_297, 9.9999997473787516355514526367188e-05f).xxx;\n        float _312 = _297 / max(_267.w, 0.001000000047497451305389404296875f);\n        float _318 = clamp(1.0f - (_312 * _312), 0.0f, 1.0f);\n        atten = _318 * _318;\n        if (_276 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _332 = fa_light_texel(param_2);\n            float _342 = _332.w;\n            int param_3 = (li * 4) + 3;\n            float4 _349 = fa_light_texel(param_3);\n            float _350 = _349.x;\n            float cos_inner = _350;\n            if (_350 > 1.5f)\n            {\n                cos_inner = lerp(_342, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_342, cos_inner, dot(-l, normalize(_332.xyz)));\n        }\n    }\n    int _380;\n    if (_283)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_276 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2685 = { l, _273.xyz * atten, atten, 1.0f, dist, _380 };\n    return _2685;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _620;\n    if (i == 0)\n    {\n        _620 = _630_fa_shadow_split.x;\n    }\n    else\n    {\n        float _636;\n        if (i == 1)\n        {\n            _636 = _630_fa_shadow_split.y;\n        }\n        else\n        {\n            float _644;\n            if (i == 2)\n            {\n                _644 = _630_fa_shadow_split.z;\n            }\n            else\n            {\n                _644 = _630_fa_shadow_split.w;\n            }\n            _636 = _644;\n        }\n        _620 = _636;\n    }\n    return _620;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _677 = fa_shadow_depth(param, param_1);\n    float _681;\n    if (conv.x < 0.5f)\n    {\n        _681 = _677;\n    }\n    else\n    {\n        _681 = (conv.y * conv.z) / (conv.z - (_677 * (conv.z - conv.y)));\n    }\n    return _681;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _608 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_608), sin(_608)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _727 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _741 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _727;\n            float2 _760 = fa_shadow_vogel(param_3, param_4, param_5) * _741;\n            float2 param_6 = uv + (_760 * _630_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _772 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_772 < (zr - (length(_760) * plane)))\n            {\n                sum += _772;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _816 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _816; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _816;\n        float param_11 = _727;\n        float2 _835 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_835 * _630_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_835) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_816);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _877 = max(_630_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _882 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _888 = sqrt(1.0f - (_882 * _882));\n    float _896 = min(_888 / max(_882, 0.20000000298023223876953125f), 4.0f);\n    float _901;\n    if (_630_fa_shadow_bias.y > 0.0f)\n    {\n        _901 = _630_fa_shadow_bias.y;\n    }\n    else\n    {\n        _901 = 1.5f * _630_fa_shadow_info[ci].x;\n    }\n    float4 _926 = mul(float4(world + (n * (_901 * _888)), 1.0f), _630_fa_shadow_mat[ci]);\n    float _933 = _926.x;\n    bool _936 = _933 < _630_fa_shadow_rect[ci].x;\n    bool _945;\n    if (!_936)\n    {\n        _945 = _933 > _630_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _945 = _936;\n    }\n    bool _954;\n    if (!_945)\n    {\n        _954 = _926.y < _630_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _954 = _945;\n    }\n    bool _963;\n    if (!_954)\n    {\n        _963 = _926.y > _630_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _963 = _954;\n    }\n    bool _970;\n    if (!_963)\n    {\n        _970 = _926.z > 1.0f;\n    }\n    else\n    {\n        _970 = _963;\n    }\n    if (_970)\n    {\n        return -1.0f;\n    }\n    float _979;\n    if (_630_fa_shadow_bias.x > 0.0f)\n    {\n        _979 = _630_fa_shadow_bias.x;\n    }\n    else\n    {\n        _979 = 1.5f * _630_fa_shadow_info[ci].x;\n    }\n    float2 param = _926.xy;\n    float4 param_1 = _630_fa_shadow_rect[ci];\n    float param_2 = _926.z - ((_979 * (1.0f + (0.5f * _896))) / _877);\n    float param_3 = _630_fa_shadow_info[ci].x;\n    float param_4 = _877;\n    float param_5 = _877 * 0.25f;\n    float param_6 = ((_630_fa_shadow_info[ci].x * min(_896, 3.0f)) * 0.5f) / _877;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_630_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _630_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_394_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1373 = int(_630_fa_shadow_cfg.x + 0.5f);\n    if (_1373 < 1)\n    {\n        return 1.0f;\n    }\n    float _1389 = dot(world - _630_fa_shadow_eye.xyz, _630_fa_shadow_fwd.xyz);\n    int param = _1373 - 1;\n    if (_1389 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1401 = _1373 > 1;\n    bool _1408;\n    if (_1401)\n    {\n        _1408 = _1389 > _630_fa_shadow_split.x;\n    }\n    else\n    {\n        _1408 = _1401;\n    }\n    if (_1408)\n    {\n        ci = 1;\n    }\n    bool _1412 = _1373 > 2;\n    bool _1419;\n    if (_1412)\n    {\n        _1419 = _1389 > _630_fa_shadow_split.y;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    if (_1419)\n    {\n        ci = 2;\n    }\n    bool _1423 = _1373 > 3;\n    bool _1430;\n    if (_1423)\n    {\n        _1430 = _1389 > _630_fa_shadow_split.z;\n    }\n    else\n    {\n        _1430 = _1423;\n    }\n    if (_1430)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1373)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1456 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1456;\n        if (_1456 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_630_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1481;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1481 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1481 = _630_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1500 = _630_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1481, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1511 = clamp((_1389 - (fa_shadow_split_at(param_7) - _1500)) / _1500, 0.0f, 1.0f);\n        if (_1511 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1373)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1532 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1532;\n                if (_1532 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1511);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1038 = _394_fa_pbr.z < 0.5f;\n    bool _1046;\n    if (!_1038)\n    {\n        _1046 = _630_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1046 = _1038;\n    }\n    if (_1046)\n    {\n        return 1.0f;\n    }\n    int param = (int(_630_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1059 = fa_light_texel(param);\n    float _1060 = _1059.x;\n    if (_1060 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1069 = int(_1060 + 0.5f);\n    int param_1 = _1069;\n    float4 _1073 = fa_light_texel(param_1);\n    int param_2 = _1069 + 1;\n    float4 _1078 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1081 = _1073.y;\n    if (_1081 > 0.0f)\n    {\n        float _1098 = 1.0f - smoothstep(0.75f * _1081, _1081, length(world - _630_fa_shadow_eye.xyz));\n        fade = _1098;\n        if (_1098 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1073.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1117 = world - fa_light_texel(param_3).xyz;\n        float3 _1120 = abs(_1117);\n        float _1122 = _1120.x;\n        float _1124 = _1120.y;\n        bool _1125 = _1122 >= _1124;\n        bool _1133;\n        if (_1125)\n        {\n            _1133 = _1122 >= _1120.z;\n        }\n        else\n        {\n            _1133 = _1125;\n        }\n        int _1134;\n        if (_1133)\n        {\n            _1134 = (_1117.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1147;\n            if (_1124 >= _1120.z)\n            {\n                _1147 = (_1117.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1147 = (_1117.z > 0.0f) ? 4 : 5;\n            }\n            _1134 = _1147;\n        }\n        face = _1134;\n    }\n    int _1166 = (_1069 + 2) + (face * 6);\n    int param_4 = _1166;\n    int param_5 = _1166 + 1;\n    int param_6 = _1166 + 3;\n    float4 _1180 = fa_light_texel(param_6);\n    int param_7 = _1166 + 4;\n    float4 _1185 = fa_light_texel(param_7);\n    int param_8 = _1166 + 5;\n    float4 _1190 = fa_light_texel(param_8);\n    float _1202 = _1190.x * max(dot(_1180, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1207 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1213 = sqrt(1.0f - (_1207 * _1207));\n    float _1219 = min(_1213 / max(_1207, 0.20000000298023223876953125f), 4.0f);\n    float _1222 = _1078.y;\n    float _1224;\n    if (_1222 > 0.0f)\n    {\n        _1224 = _1222;\n    }\n    else\n    {\n        _1224 = 1.5f * _1202;\n    }\n    float4 _1244 = float4(world + (n * (_1224 * _1213)), 1.0f);\n    float _1248 = dot(_1180, _1244);\n    float _1251 = _1190.y;\n    if (_1248 < _1251)\n    {\n        return 1.0f;\n    }\n    float2 _1266 = float2(dot(fa_light_texel(param_4), _1244), dot(fa_light_texel(param_5), _1244)) / _1248.xx;\n    float _1268 = _1266.x;\n    bool _1271 = _1268 < _1185.x;\n    bool _1280;\n    if (!_1271)\n    {\n        _1280 = _1268 > _1185.z;\n    }\n    else\n    {\n        _1280 = _1271;\n    }\n    bool _1289;\n    if (!_1280)\n    {\n        _1289 = _1266.y < _1185.y;\n    }\n    else\n    {\n        _1289 = _1280;\n    }\n    bool _1298;\n    if (!_1289)\n    {\n        _1298 = _1266.y > _1185.w;\n    }\n    else\n    {\n        _1298 = _1289;\n    }\n    if (_1298)\n    {\n        return 1.0f;\n    }\n    float _1304 = _1078.x;\n    float _1306;\n    if (_1304 > 0.0f)\n    {\n        _1306 = _1304;\n    }\n    else\n    {\n        _1306 = 1.5f * _1202;\n    }\n    float2 param_9 = _1266;\n    float4 param_10 = _1185;\n    float param_11 = _1248 - (_1306 * (1.0f + (0.5f * _1219)));\n    float param_12 = _1202;\n    float param_13 = 1.0f;\n    float param_14 = _1190.z * 0.25f;\n    float param_15 = (_1202 * min(_1219, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _1251, _1190.z);\n    int param_17 = int(_1073.z + 0.5f);\n    float param_18 = _1073.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1702 = fa_light_sample(param, param_1);\n    float3 _2692 = _1702.direction;\n    float3 _2687 = _1702.color;\n    float _2694 = _1702.attenuation;\n    float _2689 = _1702.shadow;\n    int _2697 = _1702.type;\n    if ((_2697 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2692;\n        float _1716 = fa_shadow_factor(param_2, param_3);\n        _2689 = _1716;\n        _2687 *= _1716;\n    }\n    else\n    {\n        bool _1727 = _2697 != 0;\n        bool _1733;\n        if (_1727)\n        {\n            _1733 = _2694 > 0.0f;\n        }\n        else\n        {\n            _1733 = _1727;\n        }\n        if (_1733)\n        {\n            int param_4 = li;\n            float3 param_5 = world_pos;\n            float3 param_6 = gn;\n            float3 param_7 = _2692;\n            float _1745 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _2689 = _1745;\n            _2687 *= _1745;\n        }\n    }\n    LightSample _2704 = { _2692, _2687, _2694, _2689, _1702._distance, _2697 };\n    return _2704;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_630_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1556 = int(_630_fa_shadow_cfg.x + 0.5f);\n    float _1566 = dot(world - _630_fa_shadow_eye.xyz, _630_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1571 = _1556 > 0;\n    bool _1580;\n    if (_1571)\n    {\n        int param = _1556 - 1;\n        _1580 = _1566 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1580 = _1571;\n    }\n    if (_1580)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1587 = _1556 > 1;\n        bool _1594;\n        if (_1587)\n        {\n            _1594 = _1566 > _630_fa_shadow_split.x;\n        }\n        else\n        {\n            _1594 = _1587;\n        }\n        if (_1594)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1600 = _1556 > 2;\n        bool _1607;\n        if (_1600)\n        {\n            _1607 = _1566 > _630_fa_shadow_split.y;\n        }\n        else\n        {\n            _1607 = _1600;\n        }\n        if (_1607)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1613 = _1556 > 3;\n        bool _1620;\n        if (_1613)\n        {\n            _1620 = _1566 > _630_fa_shadow_split.z;\n        }\n        else\n        {\n            _1620 = _1613;\n        }\n        if (_1620)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2516 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2516 = -_2516;\n    }\n    float3 _2129 = normalize(_394_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2529 = { fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _2129, gl_FrontFacing };\n    SurfaceInput param_1 = _2529;\n    Surface _2137 = fa_standard_surface(param_1);\n    float3 _2555 = _2137.albedo;\n    float _2556 = _2137.alpha;\n    float3 _2557 = _2137.normal;\n    float _2558 = _2137.metallic;\n    float _2559 = _2137.roughness;\n    float _2560 = _2137.occlusion;\n    float3 _2561 = _2137.emission;\n    float _2562 = _2137.clearcoat;\n    float _2563 = _2137.clearcoat_roughness;\n    float3 _2564 = _2137.sheen_color;\n    float _2565 = _2137.sheen_roughness;\n    float _2566 = _2137.anisotropy;\n    float _2567 = _2137.anisotropy_rotation;\n    float _2568 = _2137.specular;\n    float _2569 = _2137.ior;\n    float3 _2570 = _2137.specular_color;\n    SurfaceInput _2537 = { fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _2129, gl_FrontFacing };\n    SurfaceInput param_2 = _2537;\n    Surface param_3 = _2137;\n    surface(param_2, param_3);\n    _2555 = param_3.albedo;\n    _2556 = param_3.alpha;\n    _2557 = param_3.normal;\n    _2558 = param_3.metallic;\n    _2559 = param_3.roughness;\n    _2560 = param_3.occlusion;\n    _2561 = param_3.emission;\n    _2562 = param_3.clearcoat;\n    _2563 = param_3.clearcoat_roughness;\n    _2564 = param_3.sheen_color;\n    _2565 = param_3.sheen_roughness;\n    _2566 = param_3.anisotropy;\n    _2567 = param_3.anisotropy_rotation;\n    _2568 = param_3.specular;\n    _2569 = param_3.ior;\n    _2570 = param_3.specular_color;\n    float3 result;\n    if (_394_fa_emissive.w > 0.5f)\n    {\n        result = _2555;\n    }\n    else\n    {\n        float3 _2158 = _2557;\n        float3 _2159 = normalize(_2158);\n        _2557 = _2159;\n        float3 param_4 = _2159;\n        SurfaceInput _2545 = { fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _2129, gl_FrontFacing };\n        SurfaceInput param_5 = _2545;\n        Surface _2636 = { _2555, _2556, _2557, _2558, _2559, _2560, _2561, _2562, _2563, _2564, _2565, _2566, _2567, _2568, _2569, _2570 };\n        Surface param_6 = _2636;\n        float3 param_7 = fa_ambient_light(param_4);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _2178 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2178; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8);\n            float3 param_10 = fa_world_pos;\n            float3 param_11 = _2516;\n            SurfaceInput _2553 = { fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _2129, gl_FrontFacing };\n            SurfaceInput param_12 = _2553;\n            Surface _2653 = { _2555, _2556, _2557, _2558, _2559, _2560, _2561, _2562, _2563, _2564, _2565, _2566, _2567, _2568, _2569, _2570 };\n            Surface param_13 = _2653;\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _2215 = result;\n    float3 _2216 = _2215 + _2561;\n    result = _2216;\n    float3 param_15 = _2216;\n    float3 param_16 = fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16);\n    bool _2225 = _394_fa_fog.w > 0.0f;\n    bool _2232;\n    if (!_2225)\n    {\n        _2232 = _394_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2232 = _2225;\n    }\n    if (_2232)\n    {\n        float3 _2241 = fa_world_pos - _394_fa_camera_pos.xyz;\n        float _2247 = dot(_2241, _394_fa_fog_c.xyz);\n        bool _2251 = _394_fa_fog_c.w > 0.5f;\n        float _2252;\n        if (_2251)\n        {\n            _2252 = _2247;\n        }\n        else\n        {\n            _2252 = length(_2241);\n        }\n        float _2264 = _2252 - _394_fa_fog_b.x;\n        if (_2264 > 0.0f)\n        {\n            float _2273 = _394_fa_fog.w * _2264;\n            float tau = _2273 * _2273;\n            if (_394_fa_fog_b.y > 0.0f)\n            {\n                float _2289;\n                if (_2251)\n                {\n                    _2289 = fa_world_pos.y - (_394_fa_fog_c.y * _2247);\n                }\n                else\n                {\n                    _2289 = _394_fa_camera_pos.y;\n                }\n                float _2310 = lerp(_2289, fa_world_pos.y, clamp(_394_fa_fog_b.x / _2252, 0.0f, 1.0f));\n                float _2314 = fa_world_pos.y - _2310;\n                float _2319 = _2310 - _394_fa_fog_b.z;\n                float _2324 = fa_world_pos.y - _394_fa_fog_b.z;\n                bool _2327 = _2319 <= 0.0f;\n                bool _2328 = !_2327;\n                bool _2334;\n                if (_2328)\n                {\n                    _2334 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2334 = _2327;\n                }\n                float _2335;\n                if (_2334)\n                {\n                    _2335 = _394_fa_fog_b.y;\n                }\n                else\n                {\n                    _2335 = _394_fa_fog_b.y * exp(-min(_394_fa_fog_b.w * _2319, 80.0f));\n                }\n                bool _2362;\n                if (_2328)\n                {\n                    _2362 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2362 = _2327;\n                }\n                float _2363;\n                if (_2362)\n                {\n                    _2363 = _394_fa_fog_b.y * _2319;\n                }\n                else\n                {\n                    _2363 = (_394_fa_fog_b.y * (1.0f - exp(-min(_394_fa_fog_b.w * _2319, 80.0f)))) / _394_fa_fog_b.w;\n                }\n                bool _2388 = _2324 <= 0.0f;\n                bool _2395;\n                if (!_2388)\n                {\n                    _2395 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2395 = _2388;\n                }\n                float _2396;\n                if (_2395)\n                {\n                    _2396 = _394_fa_fog_b.y * _2324;\n                }\n                else\n                {\n                    _2396 = (_394_fa_fog_b.y * (1.0f - exp(-min(_394_fa_fog_b.w * _2324, 80.0f)))) / _394_fa_fog_b.w;\n                }\n                float _2423;\n                if (abs(_2314) < 0.001000000047497451305389404296875f)\n                {\n                    _2423 = _2335;\n                }\n                else\n                {\n                    _2423 = (_2396 - _2363) / _2314;\n                }\n                tau += (_2264 * max(_2423, 0.0f));\n            }\n            result = lerp(result, _394_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2556);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_394",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_630",
            "hlsl_register_b_n": 7
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 6
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
              "hlsl_register_t_n": 7
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _379 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _379;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_386, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _394_fa_camera_pos : packoffset(c0);\n    float4 _394_fa_ambient : packoffset(c1);\n    float4 _394_fa_base_color : packoffset(c2);\n    float4 _394_fa_emissive : packoffset(c3);\n    float4 _394_fa_model_emissive : packoffset(c4);\n    float4 _394_fa_pbr : packoffset(c5);\n    float4 _394_fa_maps : packoffset(c6);\n    float4 _394_fa_fog : packoffset(c7);\n    float4 _394_fa_fog_b : packoffset(c8);\n    float4 _394_fa_fog_c : packoffset(c9);\n    float4 _394_fa_counts : packoffset(c10);\n    float4 _394_fa_env_sky : packoffset(c11);\n    float4 _394_fa_env_horizon : packoffset(c12);\n    float4 _394_fa_time : packoffset(c13);\n    float4 _394_fa_cl_vpx : packoffset(c14);\n    float4 _394_fa_cl_vpy : packoffset(c15);\n    float4 _394_fa_cl_vpw : packoffset(c16);\n    float4 _394_fa_cl_fwd : packoffset(c17);\n    float4 _394_fa_cl_grid : packoffset(c18);\n    float4 _394_fa_cl_info : packoffset(c19);\n    float4 _394_fa_layers_a : packoffset(c20);\n    float4 _394_fa_layers_b : packoffset(c21);\n    float4 _394_fa_layers_c : packoffset(c22);\n    float4 _394_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _630_fa_shadow_mat[4] : packoffset(c0);\n    float4 _630_fa_shadow_rect[4] : packoffset(c16);\n    float4 _630_fa_shadow_info[4] : packoffset(c20);\n    float4 _630_fa_shadow_split : packoffset(c24);\n    float4 _630_fa_shadow_cfg : packoffset(c25);\n    float4 _630_fa_shadow_bias : packoffset(c26);\n    float4 _630_fa_shadow_eye : packoffset(c27);\n    float4 _630_fa_shadow_fwd : packoffset(c28);\n    float4 _630_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _399 = _394_fa_cl_info.x < 0.0f;\n    bool _406;\n    if (!_399)\n    {\n        _406 = _394_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = _394_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = _394_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = _394_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return int2(0, 0);\n    }\n    float4 _438 = float4(world_pos, 1.0f);\n    float _445 = dot(_394_fa_cl_vpw, _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _467 = float2(dot(_394_fa_cl_vpx, _438), dot(_394_fa_cl_vpy, _438)) / _445.xx;\n    int _471 = int(_394_fa_cl_grid.x);\n    int _475 = int(_394_fa_cl_grid.y);\n    int param = (int(_394_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_394_fa_cl_fwd.xyz, world_pos) + _394_fa_cl_fwd.w, _394_fa_cl_grid.w) / _394_fa_cl_grid.w) * _394_fa_cl_grid.z)), 0, int(_394_fa_cl_info.y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5f) + 0.5f) * _394_fa_cl_grid.y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5f) + 0.5f) * _394_fa_cl_grid.x)), 0, _471 - 1);\n    float4 _546 = fa_light_texel(param);\n    return int2(int(_546.x), int(_546.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_394_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1674 = fa_cluster_lookup(param);\n    fa_cl_slot = _1674.x;\n    fa_cl_local = _1674.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1810 = fa_linear_to_srgb(param);\n        c = _1810;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1818 = fa_srgb_to_linear(param_1);\n            c = _1818;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _175;\n    if (i.front_facing)\n    {\n        _175 = i.world_normal;\n    }\n    else\n    {\n        _175 = -i.world_normal;\n    }\n    float3 _199 = normalize(i.world_tangent.xyz - (_175 * dot(_175, i.world_tangent.xyz)));\n    float3 _227 = normalize(((_199 * m.x) + ((cross(_175, _199) * i.world_tangent.w) * m.y)) + (_175 * m.z));\n    float3 _230;\n    if (i.front_facing)\n    {\n        _230 = _227;\n    }\n    else\n    {\n        _230 = -_227;\n    }\n    return _230;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _394_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1849 = fa_tex_fix(param_2, param_3);\n    float4 _2792 = base_t;\n    _2792.x = _1849.x;\n    _2792.y = _1849.y;\n    _2792.z = _1849.z;\n    base_t = _2792;\n    float4 _1863 = (_2792 * _394_fa_base_color) * i.vertex_color;\n    float3 _2707 = i.world_normal;\n    if (_394_fa_maps.z > 0.5f)\n    {\n        float param_4 = _394_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1895 = fa_tex_fix(param_6, param_7);\n        float3 _1899 = (_1895 * 2.0f) - 1.0f.xxx;\n        float2 _1904 = _1899.xy * _394_fa_maps.x;\n        float3 _2800 = _1899;\n        _2800.x = _1904.x;\n        _2800.y = _1904.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2800;\n        _2707 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _394_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1933 = fa_tex_fix(param_12, param_13);\n    float4 _2803 = mrt;\n    _2803.x = _1933.x;\n    _2803.y = _1933.y;\n    _2803.z = _1933.z;\n    mrt = _2803;\n    float4 _1962 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _394_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _1962.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1974 = fa_tex_fix(param_16, param_17);\n    float param_18 = _394_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2004 = fa_tex_fix(param_20, param_21);\n    float _2712 = _394_fa_layers_a.x;\n    float _2713 = _394_fa_layers_a.y;\n    float _2716 = _394_fa_layers_a.z;\n    float _2715 = _394_fa_layers_b.w;\n    float _2718 = _394_fa_layers_c.x;\n    if (_394_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_394_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _2712 *= _1974.y;\n            _2713 *= _1974.z;\n            _2715 *= _1962.w;\n        }\n        if (_394_fa_layers_c.z > 1.5f)\n        {\n            _2716 *= mrt.x;\n            _2718 *= mrt.w;\n        }\n    }\n    Surface _2737 = { _1863.xyz, _1863.w, _2707, clamp(_394_fa_pbr.x * _1933.z, 0.0f, 1.0f), clamp(_394_fa_pbr.y * _1933.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_394_fa_maps.y * (_1974.x - 1.0f)), _394_fa_emissive.xyz + (_394_fa_model_emissive.xyz * _2004), _2712, _2713, _394_fa_layers_b.xyz, _2715, _2716, _394_fa_layers_a.w, _2718, _394_fa_layers_c.y, _394_fa_layers_d.xyz };\n    return _2737;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_394_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _394_fa_ambient.xyz;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_394_fa_cl_info.x) + int(_394_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _267 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _273 = fa_light_texel(param_1);\n    float _276 = _273.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _283 = _276 < 0.5f;\n    float3 l;\n    if (_283)\n    {\n        l = normalize(_267.xyz);\n    }\n    else\n    {\n        float3 _295 = _267.xyz - world_pos;\n        float _297 = length(_295);\n        dist = _297;\n        l = _295 / max(_297, 9.9999997473787516355514526367188e-05f).xxx;\n        float _312 = _297 / max(_267.w, 0.001000000047497451305389404296875f);\n        float _318 = clamp(1.0f - (_312 * _312), 0.0f, 1.0f);\n        atten = _318 * _318;\n        if (_276 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _332 = fa_light_texel(param_2);\n            float _342 = _332.w;\n            int param_3 = (li * 4) + 3;\n            float4 _349 = fa_light_texel(param_3);\n            float _350 = _349.x;\n            float cos_inner = _350;\n            if (_350 > 1.5f)\n            {\n                cos_inner = lerp(_342, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_342, cos_inner, dot(-l, normalize(_332.xyz)));\n        }\n    }\n    int _380;\n    if (_283)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_276 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2685 = { l, _273.xyz * atten, atten, 1.0f, dist, _380 };\n    return _2685;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _620;\n    if (i == 0)\n    {\n        _620 = _630_fa_shadow_split.x;\n    }\n    else\n    {\n        float _636;\n        if (i == 1)\n        {\n            _636 = _630_fa_shadow_split.y;\n        }\n        else\n        {\n            float _644;\n            if (i == 2)\n            {\n                _644 = _630_fa_shadow_split.z;\n            }\n            else\n            {\n                _644 = _630_fa_shadow_split.w;\n            }\n            _636 = _644;\n        }\n        _620 = _636;\n    }\n    return _620;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _677 = fa_shadow_depth(param, param_1);\n    float _681;\n    if (conv.x < 0.5f)\n    {\n        _681 = _677;\n    }\n    else\n    {\n        _681 = (conv.y * conv.z) / (conv.z - (_677 * (conv.z - conv.y)));\n    }\n    return _681;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _608 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_608), sin(_608)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _727 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _741 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _727;\n            float2 _760 = fa_shadow_vogel(param_3, param_4, param_5) * _741;\n            float2 param_6 = uv + (_760 * _630_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _772 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_772 < (zr - (length(_760) * plane)))\n            {\n                sum += _772;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _816 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _816; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _816;\n        float param_11 = _727;\n        float2 _835 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_835 * _630_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_835) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_816);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _877 = max(_630_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _882 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _888 = sqrt(1.0f - (_882 * _882));\n    float _896 = min(_888 / max(_882, 0.20000000298023223876953125f), 4.0f);\n    float _901;\n    if (_630_fa_shadow_bias.y > 0.0f)\n    {\n        _901 = _630_fa_shadow_bias.y;\n    }\n    else\n    {\n        _901 = 1.5f * _630_fa_shadow_info[ci].x;\n    }\n    float4 _926 = mul(float4(world + (n * (_901 * _888)), 1.0f), _630_fa_shadow_mat[ci]);\n    float _933 = _926.x;\n    bool _936 = _933 < _630_fa_shadow_rect[ci].x;\n    bool _945;\n    if (!_936)\n    {\n        _945 = _933 > _630_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _945 = _936;\n    }\n    bool _954;\n    if (!_945)\n    {\n        _954 = _926.y < _630_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _954 = _945;\n    }\n    bool _963;\n    if (!_954)\n    {\n        _963 = _926.y > _630_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _963 = _954;\n    }\n    bool _970;\n    if (!_963)\n    {\n        _970 = _926.z > 1.0f;\n    }\n    else\n    {\n        _970 = _963;\n    }\n    if (_970)\n    {\n        return -1.0f;\n    }\n    float _979;\n    if (_630_fa_shadow_bias.x > 0.0f)\n    {\n        _979 = _630_fa_shadow_bias.x;\n    }\n    else\n    {\n        _979 = 1.5f * _630_fa_shadow_info[ci].x;\n    }\n    float2 param = _926.xy;\n    float4 param_1 = _630_fa_shadow_rect[ci];\n    float param_2 = _926.z - ((_979 * (1.0f + (0.5f * _896))) / _877);\n    float param_3 = _630_fa_shadow_info[ci].x;\n    float param_4 = _877;\n    float param_5 = _877 * 0.25f;\n    float param_6 = ((_630_fa_shadow_info[ci].x * min(_896, 3.0f)) * 0.5f) / _877;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_630_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _630_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_394_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1373 = int(_630_fa_shadow_cfg.x + 0.5f);\n    if (_1373 < 1)\n    {\n        return 1.0f;\n    }\n    float _1389 = dot(world - _630_fa_shadow_eye.xyz, _630_fa_shadow_fwd.xyz);\n    int param = _1373 - 1;\n    if (_1389 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1401 = _1373 > 1;\n    bool _1408;\n    if (_1401)\n    {\n        _1408 = _1389 > _630_fa_shadow_split.x;\n    }\n    else\n    {\n        _1408 = _1401;\n    }\n    if (_1408)\n    {\n        ci = 1;\n    }\n    bool _1412 = _1373 > 2;\n    bool _1419;\n    if (_1412)\n    {\n        _1419 = _1389 > _630_fa_shadow_split.y;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    if (_1419)\n    {\n        ci = 2;\n    }\n    bool _1423 = _1373 > 3;\n    bool _1430;\n    if (_1423)\n    {\n        _1430 = _1389 > _630_fa_shadow_split.z;\n    }\n    else\n    {\n        _1430 = _1423;\n    }\n    if (_1430)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1373)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1456 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1456;\n        if (_1456 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_630_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1481;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1481 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1481 = _630_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1500 = _630_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1481, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1511 = clamp((_1389 - (fa_shadow_split_at(param_7) - _1500)) / _1500, 0.0f, 1.0f);\n        if (_1511 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1373)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1532 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1532;\n                if (_1532 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1511);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1038 = _394_fa_pbr.z < 0.5f;\n    bool _1046;\n    if (!_1038)\n    {\n        _1046 = _630_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1046 = _1038;\n    }\n    if (_1046)\n    {\n        return 1.0f;\n    }\n    int param = (int(_630_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1059 = fa_light_texel(param);\n    float _1060 = _1059.x;\n    if (_1060 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1069 = int(_1060 + 0.5f);\n    int param_1 = _1069;\n    float4 _1073 = fa_light_texel(param_1);\n    int param_2 = _1069 + 1;\n    float4 _1078 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1081 = _1073.y;\n    if (_1081 > 0.0f)\n    {\n        float _1098 = 1.0f - smoothstep(0.75f * _1081, _1081, length(world - _630_fa_shadow_eye.xyz));\n        fade = _1098;\n        if (_1098 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1073.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1117 = world - fa_light_texel(param_3).xyz;\n        float3 _1120 = abs(_1117);\n        float _1122 = _1120.x;\n        float _1124 = _1120.y;\n        bool _1125 = _1122 >= _1124;\n        bool _1133;\n        if (_1125)\n        {\n            _1133 = _1122 >= _1120.z;\n        }\n        else\n        {\n            _1133 = _1125;\n        }\n        int _1134;\n        if (_1133)\n        {\n            _1134 = (_1117.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1147;\n            if (_1124 >= _1120.z)\n            {\n                _1147 = (_1117.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1147 = (_1117.z > 0.0f) ? 4 : 5;\n            }\n            _1134 = _1147;\n        }\n        face = _1134;\n    }\n    int _1166 = (_1069 + 2) + (face * 6);\n    int param_4 = _1166;\n    int param_5 = _1166 + 1;\n    int param_6 = _1166 + 3;\n    float4 _1180 = fa_light_texel(param_6);\n    int param_7 = _1166 + 4;\n    float4 _1185 = fa_light_texel(param_7);\n    int param_8 = _1166 + 5;\n    float4 _1190 = fa_light_texel(param_8);\n    float _1202 = _1190.x * max(dot(_1180, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1207 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1213 = sqrt(1.0f - (_1207 * _1207));\n    float _1219 = min(_1213 / max(_1207, 0.20000000298023223876953125f), 4.0f);\n    float _1222 = _1078.y;\n    float _1224;\n    if (_1222 > 0.0f)\n    {\n        _1224 = _1222;\n    }\n    else\n    {\n        _1224 = 1.5f * _1202;\n    }\n    float4 _1244 = float4(world + (n * (_1224 * _1213)), 1.0f);\n    float _1248 = dot(_1180, _1244);\n    float _1251 = _1190.y;\n    if (_1248 < _1251)\n    {\n        return 1.0f;\n    }\n    float2 _1266 = float2(dot(fa_light_texel(param_4), _1244), dot(fa_light_texel(param_5), _1244)) / _1248.xx;\n    float _1268 = _1266.x;\n    bool _1271 = _1268 < _1185.x;\n    bool _1280;\n    if (!_1271)\n    {\n        _1280 = _1268 > _1185.z;\n    }\n    else\n    {\n        _1280 = _1271;\n    }\n    bool _1289;\n    if (!_1280)\n    {\n        _1289 = _1266.y < _1185.y;\n    }\n    else\n    {\n        _1289 = _1280;\n    }\n    bool _1298;\n    if (!_1289)\n    {\n        _1298 = _1266.y > _1185.w;\n    }\n    else\n    {\n        _1298 = _1289;\n    }\n    if (_1298)\n    {\n        return 1.0f;\n    }\n    float _1304 = _1078.x;\n    float _1306;\n    if (_1304 > 0.0f)\n    {\n        _1306 = _1304;\n    }\n    else\n    {\n        _1306 = 1.5f * _1202;\n    }\n    float2 param_9 = _1266;\n    float4 param_10 = _1185;\n    float param_11 = _1248 - (_1306 * (1.0f + (0.5f * _1219)));\n    float param_12 = _1202;\n    float param_13 = 1.0f;\n    float param_14 = _1190.z * 0.25f;\n    float param_15 = (_1202 * min(_1219, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _1251, _1190.z);\n    int param_17 = int(_1073.z + 0.5f);\n    float param_18 = _1073.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1702 = fa_light_sample(param, param_1);\n    float3 _2692 = _1702.direction;\n    float3 _2687 = _1702.color;\n    float _2694 = _1702.attenuation;\n    float _2689 = _1702.shadow;\n    int _2697 = _1702.type;\n    if ((_2697 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2692;\n        float _1716 = fa_shadow_factor(param_2, param_3);\n        _2689 = _1716;\n        _2687 *= _1716;\n    }\n    else\n    {\n        bool _1727 = _2697 != 0;\n        bool _1733;\n        if (_1727)\n        {\n            _1733 = _2694 > 0.0f;\n        }\n        else\n        {\n            _1733 = _1727;\n        }\n        if (_1733)\n        {\n            int param_4 = li;\n            float3 param_5 = world_pos;\n            float3 param_6 = gn;\n            float3 param_7 = _2692;\n            float _1745 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _2689 = _1745;\n            _2687 *= _1745;\n        }\n    }\n    LightSample _2704 = { _2692, _2687, _2694, _2689, _1702._distance, _2697 };\n    return _2704;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_630_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1556 = int(_630_fa_shadow_cfg.x + 0.5f);\n    float _1566 = dot(world - _630_fa_shadow_eye.xyz, _630_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1571 = _1556 > 0;\n    bool _1580;\n    if (_1571)\n    {\n        int param = _1556 - 1;\n        _1580 = _1566 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1580 = _1571;\n    }\n    if (_1580)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1587 = _1556 > 1;\n        bool _1594;\n        if (_1587)\n        {\n            _1594 = _1566 > _630_fa_shadow_split.x;\n        }\n        else\n        {\n            _1594 = _1587;\n        }\n        if (_1594)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1600 = _1556 > 2;\n        bool _1607;\n        if (_1600)\n        {\n            _1607 = _1566 > _630_fa_shadow_split.y;\n        }\n        else\n        {\n            _1607 = _1600;\n        }\n        if (_1607)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1613 = _1556 > 3;\n        bool _1620;\n        if (_1613)\n        {\n            _1620 = _1566 > _630_fa_shadow_split.z;\n        }\n        else\n        {\n            _1620 = _1613;\n        }\n        if (_1620)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2516 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2516 = -_2516;\n    }\n    float3 _2129 = normalize(_394_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2529 = { fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _2129, gl_FrontFacing };\n    SurfaceInput param_1 = _2529;\n    Surface _2137 = fa_standard_surface(param_1);\n    float3 _2555 = _2137.albedo;\n    float _2556 = _2137.alpha;\n    float3 _2557 = _2137.normal;\n    float _2558 = _2137.metallic;\n    float _2559 = _2137.roughness;\n    float _2560 = _2137.occlusion;\n    float3 _2561 = _2137.emission;\n    float _2562 = _2137.clearcoat;\n    float _2563 = _2137.clearcoat_roughness;\n    float3 _2564 = _2137.sheen_color;\n    float _2565 = _2137.sheen_roughness;\n    float _2566 = _2137.anisotropy;\n    float _2567 = _2137.anisotropy_rotation;\n    float _2568 = _2137.specular;\n    float _2569 = _2137.ior;\n    float3 _2570 = _2137.specular_color;\n    SurfaceInput _2537 = { fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _2129, gl_FrontFacing };\n    SurfaceInput param_2 = _2537;\n    Surface param_3 = _2137;\n    surface(param_2, param_3);\n    _2555 = param_3.albedo;\n    _2556 = param_3.alpha;\n    _2557 = param_3.normal;\n    _2558 = param_3.metallic;\n    _2559 = param_3.roughness;\n    _2560 = param_3.occlusion;\n    _2561 = param_3.emission;\n    _2562 = param_3.clearcoat;\n    _2563 = param_3.clearcoat_roughness;\n    _2564 = param_3.sheen_color;\n    _2565 = param_3.sheen_roughness;\n    _2566 = param_3.anisotropy;\n    _2567 = param_3.anisotropy_rotation;\n    _2568 = param_3.specular;\n    _2569 = param_3.ior;\n    _2570 = param_3.specular_color;\n    float3 result;\n    if (_394_fa_emissive.w > 0.5f)\n    {\n        result = _2555;\n    }\n    else\n    {\n        float3 _2158 = _2557;\n        float3 _2159 = normalize(_2158);\n        _2557 = _2159;\n        float3 param_4 = _2159;\n        SurfaceInput _2545 = { fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _2129, gl_FrontFacing };\n        SurfaceInput param_5 = _2545;\n        Surface _2636 = { _2555, _2556, _2557, _2558, _2559, _2560, _2561, _2562, _2563, _2564, _2565, _2566, _2567, _2568, _2569, _2570 };\n        Surface param_6 = _2636;\n        float3 param_7 = fa_ambient_light(param_4);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _2178 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2178; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8);\n            float3 param_10 = fa_world_pos;\n            float3 param_11 = _2516;\n            SurfaceInput _2553 = { fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _2129, gl_FrontFacing };\n            SurfaceInput param_12 = _2553;\n            Surface _2653 = { _2555, _2556, _2557, _2558, _2559, _2560, _2561, _2562, _2563, _2564, _2565, _2566, _2567, _2568, _2569, _2570 };\n            Surface param_13 = _2653;\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _2215 = result;\n    float3 _2216 = _2215 + _2561;\n    result = _2216;\n    float3 param_15 = _2216;\n    float3 param_16 = fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16);\n    bool _2225 = _394_fa_fog.w > 0.0f;\n    bool _2232;\n    if (!_2225)\n    {\n        _2232 = _394_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2232 = _2225;\n    }\n    if (_2232)\n    {\n        float3 _2241 = fa_world_pos - _394_fa_camera_pos.xyz;\n        float _2247 = dot(_2241, _394_fa_fog_c.xyz);\n        bool _2251 = _394_fa_fog_c.w > 0.5f;\n        float _2252;\n        if (_2251)\n        {\n            _2252 = _2247;\n        }\n        else\n        {\n            _2252 = length(_2241);\n        }\n        float _2264 = _2252 - _394_fa_fog_b.x;\n        if (_2264 > 0.0f)\n        {\n            float _2273 = _394_fa_fog.w * _2264;\n            float tau = _2273 * _2273;\n            if (_394_fa_fog_b.y > 0.0f)\n            {\n                float _2289;\n                if (_2251)\n                {\n                    _2289 = fa_world_pos.y - (_394_fa_fog_c.y * _2247);\n                }\n                else\n                {\n                    _2289 = _394_fa_camera_pos.y;\n                }\n                float _2310 = lerp(_2289, fa_world_pos.y, clamp(_394_fa_fog_b.x / _2252, 0.0f, 1.0f));\n                float _2314 = fa_world_pos.y - _2310;\n                float _2319 = _2310 - _394_fa_fog_b.z;\n                float _2324 = fa_world_pos.y - _394_fa_fog_b.z;\n                bool _2327 = _2319 <= 0.0f;\n                bool _2328 = !_2327;\n                bool _2334;\n                if (_2328)\n                {\n                    _2334 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2334 = _2327;\n                }\n                float _2335;\n                if (_2334)\n                {\n                    _2335 = _394_fa_fog_b.y;\n                }\n                else\n                {\n                    _2335 = _394_fa_fog_b.y * exp(-min(_394_fa_fog_b.w * _2319, 80.0f));\n                }\n                bool _2362;\n                if (_2328)\n                {\n                    _2362 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2362 = _2327;\n                }\n                float _2363;\n                if (_2362)\n                {\n                    _2363 = _394_fa_fog_b.y * _2319;\n                }\n                else\n                {\n                    _2363 = (_394_fa_fog_b.y * (1.0f - exp(-min(_394_fa_fog_b.w * _2319, 80.0f)))) / _394_fa_fog_b.w;\n                }\n                bool _2388 = _2324 <= 0.0f;\n                bool _2395;\n                if (!_2388)\n                {\n                    _2395 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2395 = _2388;\n                }\n                float _2396;\n                if (_2395)\n                {\n                    _2396 = _394_fa_fog_b.y * _2324;\n                }\n                else\n                {\n                    _2396 = (_394_fa_fog_b.y * (1.0f - exp(-min(_394_fa_fog_b.w * _2324, 80.0f)))) / _394_fa_fog_b.w;\n                }\n                float _2423;\n                if (abs(_2314) < 0.001000000047497451305389404296875f)\n                {\n                    _2423 = _2335;\n                }\n                else\n                {\n                    _2423 = (_2396 - _2363) / _2314;\n                }\n                tau += (_2264 * max(_2423, 0.0f));\n            }\n            result = lerp(result, _394_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2556);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_394",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_630",
            "hlsl_register_b_n": 7
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 6
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
              "hlsl_register_t_n": 7
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213_fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213_fa_layers_a.x;\n    float _752 = _213_fa_layers_a.y;\n    float _755 = _213_fa_layers_a.z;\n    float _754 = _213_fa_layers_b.w;\n    float _757 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    Surface _776 = { _241.xyz, _241.w, _746, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _751, _752, _213_fa_layers_b.xyz, _754, _755, _213_fa_layers_a.w, _757, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _776;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _670 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _670;\n    SurfaceInput _678 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _678;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213_fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213_fa_layers_a.x;\n    float _752 = _213_fa_layers_a.y;\n    float _755 = _213_fa_layers_a.z;\n    float _754 = _213_fa_layers_b.w;\n    float _757 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    Surface _776 = { _241.xyz, _241.w, _746, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _751, _752, _213_fa_layers_b.xyz, _754, _755, _213_fa_layers_a.w, _757, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _776;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _670 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _670;\n    SurfaceInput _678 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _678;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
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
