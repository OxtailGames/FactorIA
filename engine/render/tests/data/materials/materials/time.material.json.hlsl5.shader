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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _354_fa_camera_pos : packoffset(c0);\n    float4 _354_fa_ambient : packoffset(c1);\n    float4 _354_fa_base_color : packoffset(c2);\n    float4 _354_fa_emissive : packoffset(c3);\n    float4 _354_fa_model_emissive : packoffset(c4);\n    float4 _354_fa_pbr : packoffset(c5);\n    float4 _354_fa_maps : packoffset(c6);\n    float4 _354_fa_fog : packoffset(c7);\n    float4 _354_fa_fog_b : packoffset(c8);\n    float4 _354_fa_fog_c : packoffset(c9);\n    float4 _354_fa_counts : packoffset(c10);\n    float4 _354_fa_env_sky : packoffset(c11);\n    float4 _354_fa_env_horizon : packoffset(c12);\n    float4 _354_fa_time : packoffset(c13);\n    float4 _354_fa_cl_vpx : packoffset(c14);\n    float4 _354_fa_cl_vpy : packoffset(c15);\n    float4 _354_fa_cl_vpw : packoffset(c16);\n    float4 _354_fa_cl_fwd : packoffset(c17);\n    float4 _354_fa_cl_grid : packoffset(c18);\n    float4 _354_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _359 = _354_fa_cl_info.x < 0.0f;\n    bool _366;\n    if (!_359)\n    {\n        _366 = _354_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _366 = _359;\n    }\n    bool _374;\n    if (!_366)\n    {\n        _374 = _354_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _374 = _366;\n    }\n    bool _381;\n    if (!_374)\n    {\n        _381 = _354_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _381 = _374;\n    }\n    bool _388;\n    if (!_381)\n    {\n        _388 = _354_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _388 = _381;\n    }\n    if (_388)\n    {\n        return int2(0, 0);\n    }\n    float4 _398 = float4(world_pos, 1.0f);\n    float _405 = dot(_354_fa_cl_vpw, _398);\n    if (!(_405 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _428 = float2(dot(_354_fa_cl_vpx, _398), dot(_354_fa_cl_vpy, _398)) / _405.xx;\n    int _432 = int(_354_fa_cl_grid.x);\n    int _436 = int(_354_fa_cl_grid.y);\n    int param = (int(_354_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_354_fa_cl_fwd.xyz, world_pos) + _354_fa_cl_fwd.w, _354_fa_cl_grid.w) / _354_fa_cl_grid.w) * _354_fa_cl_grid.z)), 0, int(_354_fa_cl_info.y) - 1) * _436) + clamp(int(floor(((_428.y * 0.5f) + 0.5f) * _354_fa_cl_grid.y)), 0, _436 - 1)) * _432)) + clamp(int(floor(((_428.x * 0.5f) + 0.5f) * _354_fa_cl_grid.x)), 0, _432 - 1);\n    float4 _507 = fa_light_texel(param);\n    return int2(int(_507.x), int(_507.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_354_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _881 = fa_cluster_lookup(param);\n    fa_cl_slot = _881.x;\n    fa_cl_local = _881.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _999 = fa_linear_to_srgb(param);\n        c = _999;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1007 = fa_srgb_to_linear(param_1);\n            c = _1007;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _126;\n    if (i.front_facing)\n    {\n        _126 = i.world_normal;\n    }\n    else\n    {\n        _126 = -i.world_normal;\n    }\n    float3 _150 = normalize(i.world_tangent.xyz - (_126 * dot(_126, i.world_tangent.xyz)));\n    float3 _178 = normalize(((_150 * m.x) + ((cross(_126, _150) * i.world_tangent.w) * m.y)) + (_126 * m.z));\n    float3 _181;\n    if (i.front_facing)\n    {\n        _181 = _178;\n    }\n    else\n    {\n        _181 = -_178;\n    }\n    return _181;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _354_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1039 = fa_tex_fix(param_2, param_3);\n    float4 _1830 = base_t;\n    _1830.x = _1039.x;\n    _1830.y = _1039.y;\n    _1830.z = _1039.z;\n    base_t = _1830;\n    float4 _1053 = (_1830 * _354_fa_base_color) * i.vertex_color;\n    float3 _1789 = i.world_normal;\n    if (_354_fa_maps.z > 0.5f)\n    {\n        float param_4 = _354_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1086 = fa_tex_fix(param_6, param_7);\n        float3 _1089 = (_1086 * 2.0f) - 1.0f.xxx;\n        float2 _1094 = _1089.xy * _354_fa_maps.x;\n        float3 _1838 = _1089;\n        _1838.x = _1094.x;\n        _1838.y = _1094.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1838;\n        _1789 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _354_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1123 = fa_tex_fix(param_12, param_13);\n    float4 _1841 = mrt;\n    _1841.x = _1123.x;\n    _1841.y = _1123.y;\n    _1841.z = _1123.z;\n    mrt = _1841;\n    float param_14 = _354_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1162 = fa_tex_fix(param_16, param_17);\n    float param_18 = _354_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1189 = fa_tex_fix(param_20, param_21);\n    Surface _1801 = { _1053.xyz, _1053.w, _1789, clamp(_354_fa_pbr.x * _1123.z, 0.0f, 1.0f), clamp(_354_fa_pbr.y * _1123.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_354_fa_maps.y * (_1162.x - 1.0f)), _354_fa_emissive.xyz + (_354_fa_model_emissive.xyz * _1189) };\n    return _1801;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += float3(0.5f + (0.5f * sin(_354_fa_time.x * 3.0f)), 0.25f * frac(_354_fa_time.x), 0.0f);\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_354_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _354_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_354_fa_cl_info.x) + int(_354_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _226 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _232 = fa_light_texel(param_1);\n    float _235 = _232.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _242 = _235 < 0.5f;\n    float3 l;\n    if (_242)\n    {\n        l = normalize(_226.xyz);\n    }\n    else\n    {\n        float3 _254 = _226.xyz - world_pos;\n        float _256 = length(_254);\n        dist = _256;\n        l = _254 / max(_256, 9.9999997473787516355514526367188e-05f).xxx;\n        float _271 = _256 / max(_226.w, 0.001000000047497451305389404296875f);\n        float _277 = clamp(1.0f - (_271 * _271), 0.0f, 1.0f);\n        atten = _277 * _277;\n        if (_235 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _291 = fa_light_texel(param_2);\n            float _301 = _291.w;\n            int param_3 = (li * 4) + 3;\n            float4 _308 = fa_light_texel(param_3);\n            float _309 = _308.x;\n            float cos_inner = _309;\n            if (_309 > 1.5f)\n            {\n                cos_inner = lerp(_301, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_301, cos_inner, dot(-l, normalize(_291.xyz)));\n        }\n    }\n    int _340;\n    if (_242)\n    {\n        _340 = 0;\n    }\n    else\n    {\n        _340 = (_235 > 1.5f) ? 2 : 1;\n    }\n    LightSample _1767 = { l, _232.xyz * atten, atten, 1.0f, dist, _340 };\n    return _1767;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_354_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _553 = coord.xyz / coord.w.xxx;\n    float3 p = _553;\n    float2 suv = (_553.xy * 0.5f) + 0.5f.xx;\n    if (_354_fa_counts.z > 0.5f)\n    {\n        float3 _1810 = p;\n        _1810.z = (_1810.z * 0.5f) + 0.5f;\n        p = _1810;\n    }\n    else\n    {\n        float2 _1813 = suv;\n        _1813.y = 1.0f - _1813.y;\n        suv = _1813;\n    }\n    bool _579 = suv.x < 0.0f;\n    bool _586;\n    if (!_579)\n    {\n        _586 = suv.x > 1.0f;\n    }\n    else\n    {\n        _586 = _579;\n    }\n    bool _593;\n    if (!_586)\n    {\n        _593 = suv.y < 0.0f;\n    }\n    else\n    {\n        _593 = _586;\n    }\n    bool _600;\n    if (!_593)\n    {\n        _600 = suv.y > 1.0f;\n    }\n    else\n    {\n        _600 = _593;\n    }\n    bool _607;\n    if (!_600)\n    {\n        _607 = p.z > 1.0f;\n    }\n    else\n    {\n        _607 = _600;\n    }\n    if (_607)\n    {\n        return 1.0f;\n    }\n    float _622 = _354_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _622) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _354_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _909 = fa_light_sample(param, param_1);\n    float3 _1774 = _909.direction;\n    float3 _1769 = _909.color;\n    float _1771 = _909.shadow;\n    int _1779 = _909.type;\n    if ((_1779 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1774;\n        float _923 = fa_shadow_factor(param_2, param_3);\n        _1771 = _923;\n        _1769 *= _923;\n    }\n    LightSample _1786 = { _1774, _1769, _909.attenuation, _1771, _909._distance, _1779 };\n    return _1786;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _813 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _816 = _813.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_816 * _816, exp2((-9.27999973297119140625f) * ndv)) * _816) + _813.y)) + _813.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_354_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _354_fa_env_horizon.w).xyz;\n    }\n    float _716 = rough * rough;\n    float _747 = 0.60000002384185791015625f * _716;\n    return lerp(lerp(_354_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_354_fa_env_horizon.xyz, _354_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _716)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _747, 0.0500000007450580596923828125f + _747, d.y).xxx), ((_354_fa_env_sky.xyz + _354_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_716 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _855 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _855.x) + _855.y.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1694 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1694 = -_1694;\n    }\n    float3 _1234 = normalize(_354_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _1707 = { fa_world_pos, _1694, fa_world_tangent, fa_uv, fa_vertex_color, _1234, gl_FrontFacing };\n    SurfaceInput param_1 = _1707;\n    Surface _1242 = fa_standard_surface(param_1);\n    float3 _1717 = _1242.albedo;\n    float _1718 = _1242.alpha;\n    float3 _1719 = _1242.normal;\n    float _1720 = _1242.metallic;\n    float _1721 = _1242.roughness;\n    float _1722 = _1242.occlusion;\n    float3 _1723 = _1242.emission;\n    SurfaceInput _1715 = { fa_world_pos, _1694, fa_world_tangent, fa_uv, fa_vertex_color, _1234, gl_FrontFacing };\n    SurfaceInput param_2 = _1715;\n    Surface param_3 = _1242;\n    surface(param_2, param_3);\n    _1717 = param_3.albedo;\n    _1718 = param_3.alpha;\n    _1719 = param_3.normal;\n    _1720 = param_3.metallic;\n    _1721 = param_3.roughness;\n    _1722 = param_3.occlusion;\n    _1723 = param_3.emission;\n    float3 result;\n    if (_354_fa_emissive.w > 0.5f)\n    {\n        result = _1717;\n    }\n    else\n    {\n        float3 _1264 = normalize(_1719);\n        float _1271 = clamp(_1720, 0.0f, 1.0f);\n        float _1275 = clamp(_1721, 0.0500000007450580596923828125f, 1.0f);\n        float _1279 = _1275 * _1275;\n        float _1283 = _1279 * _1279;\n        float _1288 = max(dot(_1264, _1234), 9.9999997473787516355514526367188e-05f);\n        float3 _1294 = _1717 * (1.0f - _1271);\n        float3 _1302 = lerp(0.039999999105930328369140625f.xxx, _1717, _1271.xxx);\n        float3 param_4 = _1264;\n        float3 lit = (fa_ambient_light(param_4) * _1294) * _1722;\n        int _1315 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1315; ln++)\n        {\n            int param_5 = ln;\n            int _1328 = fa_cl_light(param_5);\n            int param_6 = _1328;\n            float3 param_7 = fa_world_pos;\n            float3 param_8 = _1694;\n            LightSample _1337 = fa_light_shadowed(param_6, param_7, param_8);\n            float3 _1752 = _1337.direction;\n            float _1345 = max(dot(_1264, _1752), 0.0f);\n            float3 _1356 = normalize(_1752 + _1234);\n            float _1361 = max(dot(_1264, _1356), 0.0f);\n            float _1374 = ((_1361 * _1361) * (_1283 - 1.0f)) + 1.0f;\n            int param_9 = _1328;\n            lit += (((_1294 + (((_1302 + ((1.0f.xxx - _1302) * pow(1.0f - max(dot(_1234, _1356), 0.0f), 5.0f))) * (((_1283 / ((3.1415927410125732421875f * _1374) * _1374)) * (0.5f / max(lerp((2.0f * _1345) * _1288, _1345 + _1288, _1279), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _1345))) * fa_light_rgb(param_9)) * (_1345 * (_1337.attenuation * _1337.shadow)));\n        }\n        float3 param_10 = _1264;\n        float3 param_11 = _1234;\n        float3 param_12 = _1302;\n        float param_13 = _1275;\n        float3 _1443 = lit;\n        float3 _1444 = _1443 + (fa_sky_reflection(param_10, param_11, param_12, param_13) * _1722);\n        lit = _1444;\n        result = _1444;\n    }\n    result += _1723;\n    bool _1453 = _354_fa_fog.w > 0.0f;\n    bool _1461;\n    if (!_1453)\n    {\n        _1461 = _354_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1461 = _1453;\n    }\n    if (_1461)\n    {\n        float3 _1470 = fa_world_pos - _354_fa_camera_pos.xyz;\n        float _1477 = dot(_1470, _354_fa_fog_c.xyz);\n        bool _1481 = _354_fa_fog_c.w > 0.5f;\n        float _1482;\n        if (_1481)\n        {\n            _1482 = _1477;\n        }\n        else\n        {\n            _1482 = length(_1470);\n        }\n        float _1494 = _1482 - _354_fa_fog_b.x;\n        if (_1494 > 0.0f)\n        {\n            float _1503 = _354_fa_fog.w * _1494;\n            float tau = _1503 * _1503;\n            if (_354_fa_fog_b.y > 0.0f)\n            {\n                float _1519;\n                if (_1481)\n                {\n                    _1519 = fa_world_pos.y - (_354_fa_fog_c.y * _1477);\n                }\n                else\n                {\n                    _1519 = _354_fa_camera_pos.y;\n                }\n                float _1540 = lerp(_1519, fa_world_pos.y, clamp(_354_fa_fog_b.x / _1482, 0.0f, 1.0f));\n                float _1544 = fa_world_pos.y - _1540;\n                float _1549 = _1540 - _354_fa_fog_b.z;\n                float _1554 = fa_world_pos.y - _354_fa_fog_b.z;\n                bool _1557 = _1549 <= 0.0f;\n                bool _1558 = !_1557;\n                bool _1564;\n                if (_1558)\n                {\n                    _1564 = _354_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1564 = _1557;\n                }\n                float _1565;\n                if (_1564)\n                {\n                    _1565 = _354_fa_fog_b.y;\n                }\n                else\n                {\n                    _1565 = _354_fa_fog_b.y * exp(-min(_354_fa_fog_b.w * _1549, 80.0f));\n                }\n                bool _1592;\n                if (_1558)\n                {\n                    _1592 = _354_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1592 = _1557;\n                }\n                float _1593;\n                if (_1592)\n                {\n                    _1593 = _354_fa_fog_b.y * _1549;\n                }\n                else\n                {\n                    _1593 = (_354_fa_fog_b.y * (1.0f - exp(-min(_354_fa_fog_b.w * _1549, 80.0f)))) / _354_fa_fog_b.w;\n                }\n                bool _1618 = _1554 <= 0.0f;\n                bool _1625;\n                if (!_1618)\n                {\n                    _1625 = _354_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1625 = _1618;\n                }\n                float _1626;\n                if (_1625)\n                {\n                    _1626 = _354_fa_fog_b.y * _1554;\n                }\n                else\n                {\n                    _1626 = (_354_fa_fog_b.y * (1.0f - exp(-min(_354_fa_fog_b.w * _1554, 80.0f)))) / _354_fa_fog_b.w;\n                }\n                float _1653;\n                if (abs(_1544) < 0.001000000047497451305389404296875f)\n                {\n                    _1653 = _1565;\n                }\n                else\n                {\n                    _1653 = (_1626 - _1593) / _1544;\n                }\n                tau += (_1494 * max(_1653, 0.0f));\n            }\n            result = lerp(result, _354_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1718);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_354",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _384 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _384;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _391 = _273.world_pos;\n    float4 _280 = float4(_391, 1.0f);\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_shadow_pos = mul(_280, _136_fa_light_vp);\n    gl_Position = mul(_280, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _354_fa_camera_pos : packoffset(c0);\n    float4 _354_fa_ambient : packoffset(c1);\n    float4 _354_fa_base_color : packoffset(c2);\n    float4 _354_fa_emissive : packoffset(c3);\n    float4 _354_fa_model_emissive : packoffset(c4);\n    float4 _354_fa_pbr : packoffset(c5);\n    float4 _354_fa_maps : packoffset(c6);\n    float4 _354_fa_fog : packoffset(c7);\n    float4 _354_fa_fog_b : packoffset(c8);\n    float4 _354_fa_fog_c : packoffset(c9);\n    float4 _354_fa_counts : packoffset(c10);\n    float4 _354_fa_env_sky : packoffset(c11);\n    float4 _354_fa_env_horizon : packoffset(c12);\n    float4 _354_fa_time : packoffset(c13);\n    float4 _354_fa_cl_vpx : packoffset(c14);\n    float4 _354_fa_cl_vpy : packoffset(c15);\n    float4 _354_fa_cl_vpw : packoffset(c16);\n    float4 _354_fa_cl_fwd : packoffset(c17);\n    float4 _354_fa_cl_grid : packoffset(c18);\n    float4 _354_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _359 = _354_fa_cl_info.x < 0.0f;\n    bool _366;\n    if (!_359)\n    {\n        _366 = _354_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _366 = _359;\n    }\n    bool _374;\n    if (!_366)\n    {\n        _374 = _354_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _374 = _366;\n    }\n    bool _381;\n    if (!_374)\n    {\n        _381 = _354_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _381 = _374;\n    }\n    bool _388;\n    if (!_381)\n    {\n        _388 = _354_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _388 = _381;\n    }\n    if (_388)\n    {\n        return int2(0, 0);\n    }\n    float4 _398 = float4(world_pos, 1.0f);\n    float _405 = dot(_354_fa_cl_vpw, _398);\n    if (!(_405 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _428 = float2(dot(_354_fa_cl_vpx, _398), dot(_354_fa_cl_vpy, _398)) / _405.xx;\n    int _432 = int(_354_fa_cl_grid.x);\n    int _436 = int(_354_fa_cl_grid.y);\n    int param = (int(_354_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_354_fa_cl_fwd.xyz, world_pos) + _354_fa_cl_fwd.w, _354_fa_cl_grid.w) / _354_fa_cl_grid.w) * _354_fa_cl_grid.z)), 0, int(_354_fa_cl_info.y) - 1) * _436) + clamp(int(floor(((_428.y * 0.5f) + 0.5f) * _354_fa_cl_grid.y)), 0, _436 - 1)) * _432)) + clamp(int(floor(((_428.x * 0.5f) + 0.5f) * _354_fa_cl_grid.x)), 0, _432 - 1);\n    float4 _507 = fa_light_texel(param);\n    return int2(int(_507.x), int(_507.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_354_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _881 = fa_cluster_lookup(param);\n    fa_cl_slot = _881.x;\n    fa_cl_local = _881.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _999 = fa_linear_to_srgb(param);\n        c = _999;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1007 = fa_srgb_to_linear(param_1);\n            c = _1007;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _126;\n    if (i.front_facing)\n    {\n        _126 = i.world_normal;\n    }\n    else\n    {\n        _126 = -i.world_normal;\n    }\n    float3 _150 = normalize(i.world_tangent.xyz - (_126 * dot(_126, i.world_tangent.xyz)));\n    float3 _178 = normalize(((_150 * m.x) + ((cross(_126, _150) * i.world_tangent.w) * m.y)) + (_126 * m.z));\n    float3 _181;\n    if (i.front_facing)\n    {\n        _181 = _178;\n    }\n    else\n    {\n        _181 = -_178;\n    }\n    return _181;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _354_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1039 = fa_tex_fix(param_2, param_3);\n    float4 _1830 = base_t;\n    _1830.x = _1039.x;\n    _1830.y = _1039.y;\n    _1830.z = _1039.z;\n    base_t = _1830;\n    float4 _1053 = (_1830 * _354_fa_base_color) * i.vertex_color;\n    float3 _1789 = i.world_normal;\n    if (_354_fa_maps.z > 0.5f)\n    {\n        float param_4 = _354_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1086 = fa_tex_fix(param_6, param_7);\n        float3 _1089 = (_1086 * 2.0f) - 1.0f.xxx;\n        float2 _1094 = _1089.xy * _354_fa_maps.x;\n        float3 _1838 = _1089;\n        _1838.x = _1094.x;\n        _1838.y = _1094.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1838;\n        _1789 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _354_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1123 = fa_tex_fix(param_12, param_13);\n    float4 _1841 = mrt;\n    _1841.x = _1123.x;\n    _1841.y = _1123.y;\n    _1841.z = _1123.z;\n    mrt = _1841;\n    float param_14 = _354_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1162 = fa_tex_fix(param_16, param_17);\n    float param_18 = _354_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1189 = fa_tex_fix(param_20, param_21);\n    Surface _1801 = { _1053.xyz, _1053.w, _1789, clamp(_354_fa_pbr.x * _1123.z, 0.0f, 1.0f), clamp(_354_fa_pbr.y * _1123.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_354_fa_maps.y * (_1162.x - 1.0f)), _354_fa_emissive.xyz + (_354_fa_model_emissive.xyz * _1189) };\n    return _1801;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += float3(0.5f + (0.5f * sin(_354_fa_time.x * 3.0f)), 0.25f * frac(_354_fa_time.x), 0.0f);\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_354_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _354_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_354_fa_cl_info.x) + int(_354_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _226 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _232 = fa_light_texel(param_1);\n    float _235 = _232.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _242 = _235 < 0.5f;\n    float3 l;\n    if (_242)\n    {\n        l = normalize(_226.xyz);\n    }\n    else\n    {\n        float3 _254 = _226.xyz - world_pos;\n        float _256 = length(_254);\n        dist = _256;\n        l = _254 / max(_256, 9.9999997473787516355514526367188e-05f).xxx;\n        float _271 = _256 / max(_226.w, 0.001000000047497451305389404296875f);\n        float _277 = clamp(1.0f - (_271 * _271), 0.0f, 1.0f);\n        atten = _277 * _277;\n        if (_235 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _291 = fa_light_texel(param_2);\n            float _301 = _291.w;\n            int param_3 = (li * 4) + 3;\n            float4 _308 = fa_light_texel(param_3);\n            float _309 = _308.x;\n            float cos_inner = _309;\n            if (_309 > 1.5f)\n            {\n                cos_inner = lerp(_301, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_301, cos_inner, dot(-l, normalize(_291.xyz)));\n        }\n    }\n    int _340;\n    if (_242)\n    {\n        _340 = 0;\n    }\n    else\n    {\n        _340 = (_235 > 1.5f) ? 2 : 1;\n    }\n    LightSample _1767 = { l, _232.xyz * atten, atten, 1.0f, dist, _340 };\n    return _1767;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_354_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _553 = coord.xyz / coord.w.xxx;\n    float3 p = _553;\n    float2 suv = (_553.xy * 0.5f) + 0.5f.xx;\n    if (_354_fa_counts.z > 0.5f)\n    {\n        float3 _1810 = p;\n        _1810.z = (_1810.z * 0.5f) + 0.5f;\n        p = _1810;\n    }\n    else\n    {\n        float2 _1813 = suv;\n        _1813.y = 1.0f - _1813.y;\n        suv = _1813;\n    }\n    bool _579 = suv.x < 0.0f;\n    bool _586;\n    if (!_579)\n    {\n        _586 = suv.x > 1.0f;\n    }\n    else\n    {\n        _586 = _579;\n    }\n    bool _593;\n    if (!_586)\n    {\n        _593 = suv.y < 0.0f;\n    }\n    else\n    {\n        _593 = _586;\n    }\n    bool _600;\n    if (!_593)\n    {\n        _600 = suv.y > 1.0f;\n    }\n    else\n    {\n        _600 = _593;\n    }\n    bool _607;\n    if (!_600)\n    {\n        _607 = p.z > 1.0f;\n    }\n    else\n    {\n        _607 = _600;\n    }\n    if (_607)\n    {\n        return 1.0f;\n    }\n    float _622 = _354_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _622) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _354_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _909 = fa_light_sample(param, param_1);\n    float3 _1774 = _909.direction;\n    float3 _1769 = _909.color;\n    float _1771 = _909.shadow;\n    int _1779 = _909.type;\n    if ((_1779 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1774;\n        float _923 = fa_shadow_factor(param_2, param_3);\n        _1771 = _923;\n        _1769 *= _923;\n    }\n    LightSample _1786 = { _1774, _1769, _909.attenuation, _1771, _909._distance, _1779 };\n    return _1786;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _813 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _816 = _813.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_816 * _816, exp2((-9.27999973297119140625f) * ndv)) * _816) + _813.y)) + _813.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_354_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _354_fa_env_horizon.w).xyz;\n    }\n    float _716 = rough * rough;\n    float _747 = 0.60000002384185791015625f * _716;\n    return lerp(lerp(_354_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_354_fa_env_horizon.xyz, _354_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _716)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _747, 0.0500000007450580596923828125f + _747, d.y).xxx), ((_354_fa_env_sky.xyz + _354_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_716 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _855 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _855.x) + _855.y.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1694 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1694 = -_1694;\n    }\n    float3 _1234 = normalize(_354_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _1707 = { fa_world_pos, _1694, fa_world_tangent, fa_uv, fa_vertex_color, _1234, gl_FrontFacing };\n    SurfaceInput param_1 = _1707;\n    Surface _1242 = fa_standard_surface(param_1);\n    float3 _1717 = _1242.albedo;\n    float _1718 = _1242.alpha;\n    float3 _1719 = _1242.normal;\n    float _1720 = _1242.metallic;\n    float _1721 = _1242.roughness;\n    float _1722 = _1242.occlusion;\n    float3 _1723 = _1242.emission;\n    SurfaceInput _1715 = { fa_world_pos, _1694, fa_world_tangent, fa_uv, fa_vertex_color, _1234, gl_FrontFacing };\n    SurfaceInput param_2 = _1715;\n    Surface param_3 = _1242;\n    surface(param_2, param_3);\n    _1717 = param_3.albedo;\n    _1718 = param_3.alpha;\n    _1719 = param_3.normal;\n    _1720 = param_3.metallic;\n    _1721 = param_3.roughness;\n    _1722 = param_3.occlusion;\n    _1723 = param_3.emission;\n    float3 result;\n    if (_354_fa_emissive.w > 0.5f)\n    {\n        result = _1717;\n    }\n    else\n    {\n        float3 _1264 = normalize(_1719);\n        float _1271 = clamp(_1720, 0.0f, 1.0f);\n        float _1275 = clamp(_1721, 0.0500000007450580596923828125f, 1.0f);\n        float _1279 = _1275 * _1275;\n        float _1283 = _1279 * _1279;\n        float _1288 = max(dot(_1264, _1234), 9.9999997473787516355514526367188e-05f);\n        float3 _1294 = _1717 * (1.0f - _1271);\n        float3 _1302 = lerp(0.039999999105930328369140625f.xxx, _1717, _1271.xxx);\n        float3 param_4 = _1264;\n        float3 lit = (fa_ambient_light(param_4) * _1294) * _1722;\n        int _1315 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1315; ln++)\n        {\n            int param_5 = ln;\n            int _1328 = fa_cl_light(param_5);\n            int param_6 = _1328;\n            float3 param_7 = fa_world_pos;\n            float3 param_8 = _1694;\n            LightSample _1337 = fa_light_shadowed(param_6, param_7, param_8);\n            float3 _1752 = _1337.direction;\n            float _1345 = max(dot(_1264, _1752), 0.0f);\n            float3 _1356 = normalize(_1752 + _1234);\n            float _1361 = max(dot(_1264, _1356), 0.0f);\n            float _1374 = ((_1361 * _1361) * (_1283 - 1.0f)) + 1.0f;\n            int param_9 = _1328;\n            lit += (((_1294 + (((_1302 + ((1.0f.xxx - _1302) * pow(1.0f - max(dot(_1234, _1356), 0.0f), 5.0f))) * (((_1283 / ((3.1415927410125732421875f * _1374) * _1374)) * (0.5f / max(lerp((2.0f * _1345) * _1288, _1345 + _1288, _1279), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _1345))) * fa_light_rgb(param_9)) * (_1345 * (_1337.attenuation * _1337.shadow)));\n        }\n        float3 param_10 = _1264;\n        float3 param_11 = _1234;\n        float3 param_12 = _1302;\n        float param_13 = _1275;\n        float3 _1443 = lit;\n        float3 _1444 = _1443 + (fa_sky_reflection(param_10, param_11, param_12, param_13) * _1722);\n        lit = _1444;\n        result = _1444;\n    }\n    result += _1723;\n    bool _1453 = _354_fa_fog.w > 0.0f;\n    bool _1461;\n    if (!_1453)\n    {\n        _1461 = _354_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1461 = _1453;\n    }\n    if (_1461)\n    {\n        float3 _1470 = fa_world_pos - _354_fa_camera_pos.xyz;\n        float _1477 = dot(_1470, _354_fa_fog_c.xyz);\n        bool _1481 = _354_fa_fog_c.w > 0.5f;\n        float _1482;\n        if (_1481)\n        {\n            _1482 = _1477;\n        }\n        else\n        {\n            _1482 = length(_1470);\n        }\n        float _1494 = _1482 - _354_fa_fog_b.x;\n        if (_1494 > 0.0f)\n        {\n            float _1503 = _354_fa_fog.w * _1494;\n            float tau = _1503 * _1503;\n            if (_354_fa_fog_b.y > 0.0f)\n            {\n                float _1519;\n                if (_1481)\n                {\n                    _1519 = fa_world_pos.y - (_354_fa_fog_c.y * _1477);\n                }\n                else\n                {\n                    _1519 = _354_fa_camera_pos.y;\n                }\n                float _1540 = lerp(_1519, fa_world_pos.y, clamp(_354_fa_fog_b.x / _1482, 0.0f, 1.0f));\n                float _1544 = fa_world_pos.y - _1540;\n                float _1549 = _1540 - _354_fa_fog_b.z;\n                float _1554 = fa_world_pos.y - _354_fa_fog_b.z;\n                bool _1557 = _1549 <= 0.0f;\n                bool _1558 = !_1557;\n                bool _1564;\n                if (_1558)\n                {\n                    _1564 = _354_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1564 = _1557;\n                }\n                float _1565;\n                if (_1564)\n                {\n                    _1565 = _354_fa_fog_b.y;\n                }\n                else\n                {\n                    _1565 = _354_fa_fog_b.y * exp(-min(_354_fa_fog_b.w * _1549, 80.0f));\n                }\n                bool _1592;\n                if (_1558)\n                {\n                    _1592 = _354_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1592 = _1557;\n                }\n                float _1593;\n                if (_1592)\n                {\n                    _1593 = _354_fa_fog_b.y * _1549;\n                }\n                else\n                {\n                    _1593 = (_354_fa_fog_b.y * (1.0f - exp(-min(_354_fa_fog_b.w * _1549, 80.0f)))) / _354_fa_fog_b.w;\n                }\n                bool _1618 = _1554 <= 0.0f;\n                bool _1625;\n                if (!_1618)\n                {\n                    _1625 = _354_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1625 = _1618;\n                }\n                float _1626;\n                if (_1625)\n                {\n                    _1626 = _354_fa_fog_b.y * _1554;\n                }\n                else\n                {\n                    _1626 = (_354_fa_fog_b.y * (1.0f - exp(-min(_354_fa_fog_b.w * _1554, 80.0f)))) / _354_fa_fog_b.w;\n                }\n                float _1653;\n                if (abs(_1544) < 0.001000000047497451305389404296875f)\n                {\n                    _1653 = _1565;\n                }\n                else\n                {\n                    _1653 = (_1626 - _1593) / _1544;\n                }\n                tau += (_1494 * max(_1653, 0.0f));\n            }\n            result = lerp(result, _354_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1718);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_354",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _125_fa_camera_pos : packoffset(c0);\n    float4 _125_fa_ambient : packoffset(c1);\n    float4 _125_fa_base_color : packoffset(c2);\n    float4 _125_fa_emissive : packoffset(c3);\n    float4 _125_fa_model_emissive : packoffset(c4);\n    float4 _125_fa_pbr : packoffset(c5);\n    float4 _125_fa_maps : packoffset(c6);\n    float4 _125_fa_fog : packoffset(c7);\n    float4 _125_fa_fog_b : packoffset(c8);\n    float4 _125_fa_fog_c : packoffset(c9);\n    float4 _125_fa_counts : packoffset(c10);\n    float4 _125_fa_env_sky : packoffset(c11);\n    float4 _125_fa_env_horizon : packoffset(c12);\n    float4 _125_fa_time : packoffset(c13);\n    float4 _125_fa_cl_vpx : packoffset(c14);\n    float4 _125_fa_cl_vpy : packoffset(c15);\n    float4 _125_fa_cl_vpw : packoffset(c16);\n    float4 _125_fa_cl_fwd : packoffset(c17);\n    float4 _125_fa_cl_grid : packoffset(c18);\n    float4 _125_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _195 = fa_linear_to_srgb(param);\n        c = _195;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _203 = fa_srgb_to_linear(param_1);\n            c = _203;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _125_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _243 = fa_tex_fix(param_2, param_3);\n    float4 _605 = base_t;\n    _605.x = _243.x;\n    _605.y = _243.y;\n    _605.z = _243.z;\n    base_t = _605;\n    float4 _259 = (_605 * _125_fa_base_color) * i.vertex_color;\n    float3 _586 = i.world_normal;\n    if (_125_fa_maps.z > 0.5f)\n    {\n        float param_4 = _125_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _293 = fa_tex_fix(param_6, param_7);\n        float3 _297 = (_293 * 2.0f) - 1.0f.xxx;\n        float2 _302 = _297.xy * _125_fa_maps.x;\n        float3 _613 = _297;\n        _613.x = _302.x;\n        _613.y = _302.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _613;\n        _586 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _125_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _331 = fa_tex_fix(param_12, param_13);\n    float4 _616 = mrt;\n    _616.x = _331.x;\n    _616.y = _331.y;\n    _616.z = _331.z;\n    mrt = _616;\n    float param_14 = _125_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _372 = fa_tex_fix(param_16, param_17);\n    float param_18 = _125_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _399 = fa_tex_fix(param_20, param_21);\n    Surface _598 = { _259.xyz, _259.w, _586, clamp(_125_fa_pbr.x * _331.z, 0.0f, 1.0f), clamp(_125_fa_pbr.y * _331.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_125_fa_maps.y * (_372.x - 1.0f)), _125_fa_emissive.xyz + (_125_fa_model_emissive.xyz * _399) };\n    return _598;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += float3(0.5f + (0.5f * sin(_125_fa_time.x * 3.0f)), 0.25f * frac(_125_fa_time.x), 0.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _533 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _533 = -_533;\n    }\n    float3 _445 = normalize(_125_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _546 = { fa_world_pos, _533, fa_world_tangent, fa_uv, fa_vertex_color, _445, gl_FrontFacing };\n    SurfaceInput param = _546;\n    SurfaceInput _554 = { fa_world_pos, _533, fa_world_tangent, fa_uv, fa_vertex_color, _445, gl_FrontFacing };\n    SurfaceInput param_1 = _554;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _460 = normalize(param_2.normal);\n    float3 _475 = normalize(float3(dot(fa_pre_r0, _460), dot(fa_pre_r1, _460), dot(fa_pre_r2, _460)));\n    float _487 = _475.z;\n    float2 e = _475.xy / ((abs(_475.x) + abs(_475.y)) + abs(_487)).xx;\n    if (_487 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_125",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _125_fa_camera_pos : packoffset(c0);\n    float4 _125_fa_ambient : packoffset(c1);\n    float4 _125_fa_base_color : packoffset(c2);\n    float4 _125_fa_emissive : packoffset(c3);\n    float4 _125_fa_model_emissive : packoffset(c4);\n    float4 _125_fa_pbr : packoffset(c5);\n    float4 _125_fa_maps : packoffset(c6);\n    float4 _125_fa_fog : packoffset(c7);\n    float4 _125_fa_fog_b : packoffset(c8);\n    float4 _125_fa_fog_c : packoffset(c9);\n    float4 _125_fa_counts : packoffset(c10);\n    float4 _125_fa_env_sky : packoffset(c11);\n    float4 _125_fa_env_horizon : packoffset(c12);\n    float4 _125_fa_time : packoffset(c13);\n    float4 _125_fa_cl_vpx : packoffset(c14);\n    float4 _125_fa_cl_vpy : packoffset(c15);\n    float4 _125_fa_cl_vpw : packoffset(c16);\n    float4 _125_fa_cl_fwd : packoffset(c17);\n    float4 _125_fa_cl_grid : packoffset(c18);\n    float4 _125_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _195 = fa_linear_to_srgb(param);\n        c = _195;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _203 = fa_srgb_to_linear(param_1);\n            c = _203;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _125_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _243 = fa_tex_fix(param_2, param_3);\n    float4 _605 = base_t;\n    _605.x = _243.x;\n    _605.y = _243.y;\n    _605.z = _243.z;\n    base_t = _605;\n    float4 _259 = (_605 * _125_fa_base_color) * i.vertex_color;\n    float3 _586 = i.world_normal;\n    if (_125_fa_maps.z > 0.5f)\n    {\n        float param_4 = _125_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _293 = fa_tex_fix(param_6, param_7);\n        float3 _297 = (_293 * 2.0f) - 1.0f.xxx;\n        float2 _302 = _297.xy * _125_fa_maps.x;\n        float3 _613 = _297;\n        _613.x = _302.x;\n        _613.y = _302.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _613;\n        _586 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _125_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _331 = fa_tex_fix(param_12, param_13);\n    float4 _616 = mrt;\n    _616.x = _331.x;\n    _616.y = _331.y;\n    _616.z = _331.z;\n    mrt = _616;\n    float param_14 = _125_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _372 = fa_tex_fix(param_16, param_17);\n    float param_18 = _125_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _399 = fa_tex_fix(param_20, param_21);\n    Surface _598 = { _259.xyz, _259.w, _586, clamp(_125_fa_pbr.x * _331.z, 0.0f, 1.0f), clamp(_125_fa_pbr.y * _331.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_125_fa_maps.y * (_372.x - 1.0f)), _125_fa_emissive.xyz + (_125_fa_model_emissive.xyz * _399) };\n    return _598;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += float3(0.5f + (0.5f * sin(_125_fa_time.x * 3.0f)), 0.25f * frac(_125_fa_time.x), 0.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _533 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _533 = -_533;\n    }\n    float3 _445 = normalize(_125_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _546 = { fa_world_pos, _533, fa_world_tangent, fa_uv, fa_vertex_color, _445, gl_FrontFacing };\n    SurfaceInput param = _546;\n    SurfaceInput _554 = { fa_world_pos, _533, fa_world_tangent, fa_uv, fa_vertex_color, _445, gl_FrontFacing };\n    SurfaceInput param_1 = _554;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _460 = normalize(param_2.normal);\n    float3 _475 = normalize(float3(dot(fa_pre_r0, _460), dot(fa_pre_r1, _460), dot(fa_pre_r2, _460)));\n    float _487 = _475.z;\n    float2 e = _475.xy / ((abs(_475.x) + abs(_475.y)) + abs(_487)).xx;\n    if (_487 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_125",
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
