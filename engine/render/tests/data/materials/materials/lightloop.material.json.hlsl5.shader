{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "52eeaf5ca947e177a667baaefefbdd9e30bcf8f98f8759d8120ce8dc6aae8b9c",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _266 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _266;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _273 = _160.world_pos;\n    float4 _167 = float4(_273, 1.0f);\n    fa_world_pos = _273;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_shadow_pos = mul(_167, _131_fa_light_vp);\n    gl_Position = mul(_167, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstatic const LightSample _1877 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _363_fa_camera_pos : packoffset(c0);\n    float4 _363_fa_ambient : packoffset(c1);\n    float4 _363_fa_base_color : packoffset(c2);\n    float4 _363_fa_emissive : packoffset(c3);\n    float4 _363_fa_model_emissive : packoffset(c4);\n    float4 _363_fa_pbr : packoffset(c5);\n    float4 _363_fa_maps : packoffset(c6);\n    float4 _363_fa_fog : packoffset(c7);\n    float4 _363_fa_fog_b : packoffset(c8);\n    float4 _363_fa_fog_c : packoffset(c9);\n    float4 _363_fa_counts : packoffset(c10);\n    float4 _363_fa_env_sky : packoffset(c11);\n    float4 _363_fa_env_horizon : packoffset(c12);\n    float4 _363_fa_time : packoffset(c13);\n    float4 _363_fa_cl_vpx : packoffset(c14);\n    float4 _363_fa_cl_vpy : packoffset(c15);\n    float4 _363_fa_cl_vpw : packoffset(c16);\n    float4 _363_fa_cl_fwd : packoffset(c17);\n    float4 _363_fa_cl_grid : packoffset(c18);\n    float4 _363_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _1091_dark : packoffset(c0);\n    float _1091_fa_pad0 : packoffset(c0.y);\n    float _1091_fa_pad1 : packoffset(c0.z);\n    float _1091_fa_pad2 : packoffset(c0.w);\n    float _1091_skyAmount : packoffset(c1);\n    float _1091_fa_pad3 : packoffset(c1.y);\n    float _1091_fa_pad4 : packoffset(c1.z);\n    float _1091_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _368 = _363_fa_cl_info.x < 0.0f;\n    bool _375;\n    if (!_368)\n    {\n        _375 = _363_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _375 = _368;\n    }\n    bool _383;\n    if (!_375)\n    {\n        _383 = _363_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _383 = _375;\n    }\n    bool _390;\n    if (!_383)\n    {\n        _390 = _363_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _390 = _383;\n    }\n    bool _397;\n    if (!_390)\n    {\n        _397 = _363_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    if (_397)\n    {\n        return int2(0, 0);\n    }\n    float4 _407 = float4(world_pos, 1.0f);\n    float _414 = dot(_363_fa_cl_vpw, _407);\n    if (!(_414 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _437 = float2(dot(_363_fa_cl_vpx, _407), dot(_363_fa_cl_vpy, _407)) / _414.xx;\n    int _441 = int(_363_fa_cl_grid.x);\n    int _445 = int(_363_fa_cl_grid.y);\n    int param = (int(_363_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_363_fa_cl_fwd.xyz, world_pos) + _363_fa_cl_fwd.w, _363_fa_cl_grid.w) / _363_fa_cl_grid.w) * _363_fa_cl_grid.z)), 0, int(_363_fa_cl_info.y) - 1) * _445) + clamp(int(floor(((_437.y * 0.5f) + 0.5f) * _363_fa_cl_grid.y)), 0, _445 - 1)) * _441)) + clamp(int(floor(((_437.x * 0.5f) + 0.5f) * _363_fa_cl_grid.x)), 0, _441 - 1);\n    float4 _516 = fa_light_texel(param);\n    return int2(int(_516.x), int(_516.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_363_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _917 = fa_cluster_lookup(param);\n    fa_cl_slot = _917.x;\n    fa_cl_local = _917.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1163 = fa_linear_to_srgb(param);\n        c = _1163;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1171 = fa_srgb_to_linear(param_1);\n            c = _1171;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _143;\n    if (i.front_facing)\n    {\n        _143 = i.world_normal;\n    }\n    else\n    {\n        _143 = -i.world_normal;\n    }\n    float3 _167 = normalize(i.world_tangent.xyz - (_143 * dot(_143, i.world_tangent.xyz)));\n    float3 _195 = normalize(((_167 * m.x) + ((cross(_143, _167) * i.world_tangent.w) * m.y)) + (_143 * m.z));\n    float3 _198;\n    if (i.front_facing)\n    {\n        _198 = _195;\n    }\n    else\n    {\n        _198 = -_195;\n    }\n    return _198;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _363_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1203 = fa_tex_fix(param_2, param_3);\n    float4 _1856 = base_t;\n    _1856.x = _1203.x;\n    _1856.y = _1203.y;\n    _1856.z = _1203.z;\n    base_t = _1856;\n    float4 _1217 = (_1856 * _363_fa_base_color) * i.vertex_color;\n    float3 _1815 = i.world_normal;\n    if (_363_fa_maps.z > 0.5f)\n    {\n        float param_4 = _363_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1250 = fa_tex_fix(param_6, param_7);\n        float3 _1253 = (_1250 * 2.0f) - 1.0f.xxx;\n        float2 _1258 = _1253.xy * _363_fa_maps.x;\n        float3 _1864 = _1253;\n        _1864.x = _1258.x;\n        _1864.y = _1258.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1864;\n        _1815 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _363_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1287 = fa_tex_fix(param_12, param_13);\n    float4 _1867 = mrt;\n    _1867.x = _1287.x;\n    _1867.y = _1287.y;\n    _1867.z = _1287.z;\n    mrt = _1867;\n    float param_14 = _363_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1326 = fa_tex_fix(param_16, param_17);\n    float param_18 = _363_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1353 = fa_tex_fix(param_20, param_21);\n    Surface _1827 = { _1217.xyz, _1217.w, _1815, clamp(_363_fa_pbr.x * _1287.z, 0.0f, 1.0f), clamp(_363_fa_pbr.y * _1287.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_363_fa_maps.y * (_1326.x - 1.0f)), _363_fa_emissive.xyz + (_363_fa_model_emissive.xyz * _1353) };\n    return _1827;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _1877;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_363_fa_cl_info.x) + int(_363_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _235 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _241 = fa_light_texel(param_1);\n    float _244 = _241.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _251 = _244 < 0.5f;\n    float3 l;\n    if (_251)\n    {\n        l = normalize(_235.xyz);\n    }\n    else\n    {\n        float3 _263 = _235.xyz - world_pos;\n        float _265 = length(_263);\n        dist = _265;\n        l = _263 / max(_265, 9.9999997473787516355514526367188e-05f).xxx;\n        float _280 = _265 / max(_235.w, 0.001000000047497451305389404296875f);\n        float _286 = clamp(1.0f - (_280 * _280), 0.0f, 1.0f);\n        atten = _286 * _286;\n        if (_244 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _300 = fa_light_texel(param_2);\n            float _310 = _300.w;\n            int param_3 = (li * 4) + 3;\n            float4 _317 = fa_light_texel(param_3);\n            float _318 = _317.x;\n            float cos_inner = _318;\n            if (_318 > 1.5f)\n            {\n                cos_inner = lerp(_310, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_310, cos_inner, dot(-l, normalize(_300.xyz)));\n        }\n    }\n    int _349;\n    if (_251)\n    {\n        _349 = 0;\n    }\n    else\n    {\n        _349 = (_244 > 1.5f) ? 2 : 1;\n    }\n    LightSample _1771 = { l, _241.xyz * atten, atten, 1.0f, dist, _349 };\n    return _1771;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _1002 = n < 0;\n    bool _1009;\n    if (!_1002)\n    {\n        _1009 = n >= fa_light_count();\n    }\n    else\n    {\n        _1009 = _1002;\n    }\n    if (_1009)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2);\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_363_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _562 = coord.xyz / coord.w.xxx;\n    float3 p = _562;\n    float2 suv = (_562.xy * 0.5f) + 0.5f.xx;\n    if (_363_fa_counts.z > 0.5f)\n    {\n        float3 _1836 = p;\n        _1836.z = (_1836.z * 0.5f) + 0.5f;\n        p = _1836;\n    }\n    else\n    {\n        float2 _1839 = suv;\n        _1839.y = 1.0f - _1839.y;\n        suv = _1839;\n    }\n    bool _588 = suv.x < 0.0f;\n    bool _595;\n    if (!_588)\n    {\n        _595 = suv.x > 1.0f;\n    }\n    else\n    {\n        _595 = _588;\n    }\n    bool _602;\n    if (!_595)\n    {\n        _602 = suv.y < 0.0f;\n    }\n    else\n    {\n        _602 = _595;\n    }\n    bool _609;\n    if (!_602)\n    {\n        _609 = suv.y > 1.0f;\n    }\n    else\n    {\n        _609 = _602;\n    }\n    bool _616;\n    if (!_609)\n    {\n        _616 = p.z > 1.0f;\n    }\n    else\n    {\n        _616 = _609;\n    }\n    if (_616)\n    {\n        return 1.0f;\n    }\n    float _631 = _363_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _631) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _363_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _945 = fa_light_sample(param, param_1);\n    float3 _1791 = _945.direction;\n    float3 _1786 = _945.color;\n    float _1788 = _945.shadow;\n    int _1796 = _945.type;\n    if ((_1796 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1791;\n        float _959 = fa_shadow_factor(param_2, param_3);\n        _1788 = _959;\n        _1786 *= _959;\n    }\n    LightSample _1803 = { _1791, _1786, _945.attenuation, _1788, _945._distance, _1796 };\n    return _1803;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _976 = n < 0;\n    bool _983;\n    if (!_976)\n    {\n        _983 = n >= fa_light_count();\n    }\n    else\n    {\n        _983 = _976;\n    }\n    if (_983)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _804 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _807 = _804.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_807 * _807, exp2((-9.27999973297119140625f) * ndv)) * _807) + _804.y)) + _804.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_363_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _363_fa_env_horizon.w).xyz;\n    }\n    float _725 = rough * rough;\n    float _756 = 0.60000002384185791015625f * _725;\n    return lerp(lerp(_363_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_363_fa_env_horizon.xyz, _363_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _725)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _756, 0.0500000007450580596923828125f + _756, d.y).xxx), ((_363_fa_env_sky.xyz + _363_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_725 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _846 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _846.x) + _846.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float3 param = normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = lerp(0.039999999105930328369140625f.xxx, s.albedo, clamp(s.metallic, 0.0f, 1.0f).xxx);\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1048 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_1048 > bestPower)\n        {\n            bestPower = _1048;\n            best = n;\n        }\n    }\n    float3 lit = (_363_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1077 = fa_light(param_2, param_3);\n        float _1085;\n        if (dot(s.normal, _1077.direction) > 0.5f)\n        {\n            _1085 = 1.0f;\n        }\n        else\n        {\n            _1085 = _1091_dark;\n        }\n        lit += ((s.albedo * _1077.color) * _1085);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _1091_skyAmount);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1691 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1691 = -_1691;\n    }\n    float3 _1398 = normalize(_363_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _1704 = { fa_world_pos, _1691, fa_world_tangent, fa_uv, fa_vertex_color, _1398, gl_FrontFacing };\n    SurfaceInput param_1 = _1704;\n    Surface _1406 = fa_standard_surface(param_1);\n    float3 _1722 = _1406.albedo;\n    float _1723 = _1406.alpha;\n    float3 _1724 = _1406.normal;\n    float _1725 = _1406.metallic;\n    float _1726 = _1406.roughness;\n    float _1727 = _1406.occlusion;\n    float3 _1728 = _1406.emission;\n    SurfaceInput _1712 = { fa_world_pos, _1691, fa_world_tangent, fa_uv, fa_vertex_color, _1398, gl_FrontFacing };\n    SurfaceInput param_2 = _1712;\n    Surface param_3 = _1406;\n    surface(param_2, param_3);\n    _1722 = param_3.albedo;\n    _1723 = param_3.alpha;\n    _1724 = param_3.normal;\n    _1725 = param_3.metallic;\n    _1726 = param_3.roughness;\n    _1727 = param_3.occlusion;\n    _1728 = param_3.emission;\n    float3 result;\n    if (_363_fa_emissive.w > 0.5f)\n    {\n        result = _1722;\n    }\n    else\n    {\n        float3 _1427 = _1724;\n        float3 _1428 = normalize(_1427);\n        _1724 = _1428;\n        SurfaceInput _1720 = { fa_world_pos, _1691, fa_world_tangent, fa_uv, fa_vertex_color, _1398, gl_FrontFacing };\n        SurfaceInput param_4 = _1720;\n        Surface _1758 = { _1722, _1723, _1428, _1725, _1726, _1727, _1728 };\n        Surface param_5 = _1758;\n        result = lighting(param_4, param_5);\n    }\n    result += _1728;\n    bool _1448 = _363_fa_fog.w > 0.0f;\n    bool _1456;\n    if (!_1448)\n    {\n        _1456 = _363_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1456 = _1448;\n    }\n    if (_1456)\n    {\n        float3 _1465 = fa_world_pos - _363_fa_camera_pos.xyz;\n        float _1472 = dot(_1465, _363_fa_fog_c.xyz);\n        bool _1476 = _363_fa_fog_c.w > 0.5f;\n        float _1477;\n        if (_1476)\n        {\n            _1477 = _1472;\n        }\n        else\n        {\n            _1477 = length(_1465);\n        }\n        float _1489 = _1477 - _363_fa_fog_b.x;\n        if (_1489 > 0.0f)\n        {\n            float _1498 = _363_fa_fog.w * _1489;\n            float tau = _1498 * _1498;\n            if (_363_fa_fog_b.y > 0.0f)\n            {\n                float _1514;\n                if (_1476)\n                {\n                    _1514 = fa_world_pos.y - (_363_fa_fog_c.y * _1472);\n                }\n                else\n                {\n                    _1514 = _363_fa_camera_pos.y;\n                }\n                float _1535 = lerp(_1514, fa_world_pos.y, clamp(_363_fa_fog_b.x / _1477, 0.0f, 1.0f));\n                float _1539 = fa_world_pos.y - _1535;\n                float _1544 = _1535 - _363_fa_fog_b.z;\n                float _1549 = fa_world_pos.y - _363_fa_fog_b.z;\n                bool _1552 = _1544 <= 0.0f;\n                bool _1553 = !_1552;\n                bool _1559;\n                if (_1553)\n                {\n                    _1559 = _363_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1559 = _1552;\n                }\n                float _1560;\n                if (_1559)\n                {\n                    _1560 = _363_fa_fog_b.y;\n                }\n                else\n                {\n                    _1560 = _363_fa_fog_b.y * exp(-min(_363_fa_fog_b.w * _1544, 80.0f));\n                }\n                bool _1587;\n                if (_1553)\n                {\n                    _1587 = _363_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1587 = _1552;\n                }\n                float _1588;\n                if (_1587)\n                {\n                    _1588 = _363_fa_fog_b.y * _1544;\n                }\n                else\n                {\n                    _1588 = (_363_fa_fog_b.y * (1.0f - exp(-min(_363_fa_fog_b.w * _1544, 80.0f)))) / _363_fa_fog_b.w;\n                }\n                bool _1613 = _1549 <= 0.0f;\n                bool _1620;\n                if (!_1613)\n                {\n                    _1620 = _363_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1620 = _1613;\n                }\n                float _1621;\n                if (_1620)\n                {\n                    _1621 = _363_fa_fog_b.y * _1549;\n                }\n                else\n                {\n                    _1621 = (_363_fa_fog_b.y * (1.0f - exp(-min(_363_fa_fog_b.w * _1549, 80.0f)))) / _363_fa_fog_b.w;\n                }\n                float _1648;\n                if (abs(_1539) < 0.001000000047497451305389404296875f)\n                {\n                    _1648 = _1560;\n                }\n                else\n                {\n                    _1648 = (_1621 - _1588) / _1539;\n                }\n                tau += (_1489 * max(_1648, 0.0f));\n            }\n            result = lerp(result, _363_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1723);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_363",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1091",
            "hlsl_register_b_n": 5
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 7,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _387 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _387;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _394 = _273.world_pos;\n    float4 _280 = float4(_394, 1.0f);\n    fa_world_pos = _394;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_shadow_pos = mul(_280, _136_fa_light_vp);\n    gl_Position = mul(_280, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstatic const LightSample _1877 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _363_fa_camera_pos : packoffset(c0);\n    float4 _363_fa_ambient : packoffset(c1);\n    float4 _363_fa_base_color : packoffset(c2);\n    float4 _363_fa_emissive : packoffset(c3);\n    float4 _363_fa_model_emissive : packoffset(c4);\n    float4 _363_fa_pbr : packoffset(c5);\n    float4 _363_fa_maps : packoffset(c6);\n    float4 _363_fa_fog : packoffset(c7);\n    float4 _363_fa_fog_b : packoffset(c8);\n    float4 _363_fa_fog_c : packoffset(c9);\n    float4 _363_fa_counts : packoffset(c10);\n    float4 _363_fa_env_sky : packoffset(c11);\n    float4 _363_fa_env_horizon : packoffset(c12);\n    float4 _363_fa_time : packoffset(c13);\n    float4 _363_fa_cl_vpx : packoffset(c14);\n    float4 _363_fa_cl_vpy : packoffset(c15);\n    float4 _363_fa_cl_vpw : packoffset(c16);\n    float4 _363_fa_cl_fwd : packoffset(c17);\n    float4 _363_fa_cl_grid : packoffset(c18);\n    float4 _363_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _1091_dark : packoffset(c0);\n    float _1091_fa_pad0 : packoffset(c0.y);\n    float _1091_fa_pad1 : packoffset(c0.z);\n    float _1091_fa_pad2 : packoffset(c0.w);\n    float _1091_skyAmount : packoffset(c1);\n    float _1091_fa_pad3 : packoffset(c1.y);\n    float _1091_fa_pad4 : packoffset(c1.z);\n    float _1091_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _368 = _363_fa_cl_info.x < 0.0f;\n    bool _375;\n    if (!_368)\n    {\n        _375 = _363_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _375 = _368;\n    }\n    bool _383;\n    if (!_375)\n    {\n        _383 = _363_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _383 = _375;\n    }\n    bool _390;\n    if (!_383)\n    {\n        _390 = _363_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _390 = _383;\n    }\n    bool _397;\n    if (!_390)\n    {\n        _397 = _363_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    if (_397)\n    {\n        return int2(0, 0);\n    }\n    float4 _407 = float4(world_pos, 1.0f);\n    float _414 = dot(_363_fa_cl_vpw, _407);\n    if (!(_414 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _437 = float2(dot(_363_fa_cl_vpx, _407), dot(_363_fa_cl_vpy, _407)) / _414.xx;\n    int _441 = int(_363_fa_cl_grid.x);\n    int _445 = int(_363_fa_cl_grid.y);\n    int param = (int(_363_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_363_fa_cl_fwd.xyz, world_pos) + _363_fa_cl_fwd.w, _363_fa_cl_grid.w) / _363_fa_cl_grid.w) * _363_fa_cl_grid.z)), 0, int(_363_fa_cl_info.y) - 1) * _445) + clamp(int(floor(((_437.y * 0.5f) + 0.5f) * _363_fa_cl_grid.y)), 0, _445 - 1)) * _441)) + clamp(int(floor(((_437.x * 0.5f) + 0.5f) * _363_fa_cl_grid.x)), 0, _441 - 1);\n    float4 _516 = fa_light_texel(param);\n    return int2(int(_516.x), int(_516.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_363_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _917 = fa_cluster_lookup(param);\n    fa_cl_slot = _917.x;\n    fa_cl_local = _917.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1163 = fa_linear_to_srgb(param);\n        c = _1163;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1171 = fa_srgb_to_linear(param_1);\n            c = _1171;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _143;\n    if (i.front_facing)\n    {\n        _143 = i.world_normal;\n    }\n    else\n    {\n        _143 = -i.world_normal;\n    }\n    float3 _167 = normalize(i.world_tangent.xyz - (_143 * dot(_143, i.world_tangent.xyz)));\n    float3 _195 = normalize(((_167 * m.x) + ((cross(_143, _167) * i.world_tangent.w) * m.y)) + (_143 * m.z));\n    float3 _198;\n    if (i.front_facing)\n    {\n        _198 = _195;\n    }\n    else\n    {\n        _198 = -_195;\n    }\n    return _198;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _363_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1203 = fa_tex_fix(param_2, param_3);\n    float4 _1856 = base_t;\n    _1856.x = _1203.x;\n    _1856.y = _1203.y;\n    _1856.z = _1203.z;\n    base_t = _1856;\n    float4 _1217 = (_1856 * _363_fa_base_color) * i.vertex_color;\n    float3 _1815 = i.world_normal;\n    if (_363_fa_maps.z > 0.5f)\n    {\n        float param_4 = _363_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1250 = fa_tex_fix(param_6, param_7);\n        float3 _1253 = (_1250 * 2.0f) - 1.0f.xxx;\n        float2 _1258 = _1253.xy * _363_fa_maps.x;\n        float3 _1864 = _1253;\n        _1864.x = _1258.x;\n        _1864.y = _1258.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1864;\n        _1815 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _363_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1287 = fa_tex_fix(param_12, param_13);\n    float4 _1867 = mrt;\n    _1867.x = _1287.x;\n    _1867.y = _1287.y;\n    _1867.z = _1287.z;\n    mrt = _1867;\n    float param_14 = _363_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1326 = fa_tex_fix(param_16, param_17);\n    float param_18 = _363_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1353 = fa_tex_fix(param_20, param_21);\n    Surface _1827 = { _1217.xyz, _1217.w, _1815, clamp(_363_fa_pbr.x * _1287.z, 0.0f, 1.0f), clamp(_363_fa_pbr.y * _1287.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_363_fa_maps.y * (_1326.x - 1.0f)), _363_fa_emissive.xyz + (_363_fa_model_emissive.xyz * _1353) };\n    return _1827;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _1877;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_363_fa_cl_info.x) + int(_363_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _235 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _241 = fa_light_texel(param_1);\n    float _244 = _241.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _251 = _244 < 0.5f;\n    float3 l;\n    if (_251)\n    {\n        l = normalize(_235.xyz);\n    }\n    else\n    {\n        float3 _263 = _235.xyz - world_pos;\n        float _265 = length(_263);\n        dist = _265;\n        l = _263 / max(_265, 9.9999997473787516355514526367188e-05f).xxx;\n        float _280 = _265 / max(_235.w, 0.001000000047497451305389404296875f);\n        float _286 = clamp(1.0f - (_280 * _280), 0.0f, 1.0f);\n        atten = _286 * _286;\n        if (_244 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _300 = fa_light_texel(param_2);\n            float _310 = _300.w;\n            int param_3 = (li * 4) + 3;\n            float4 _317 = fa_light_texel(param_3);\n            float _318 = _317.x;\n            float cos_inner = _318;\n            if (_318 > 1.5f)\n            {\n                cos_inner = lerp(_310, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_310, cos_inner, dot(-l, normalize(_300.xyz)));\n        }\n    }\n    int _349;\n    if (_251)\n    {\n        _349 = 0;\n    }\n    else\n    {\n        _349 = (_244 > 1.5f) ? 2 : 1;\n    }\n    LightSample _1771 = { l, _241.xyz * atten, atten, 1.0f, dist, _349 };\n    return _1771;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _1002 = n < 0;\n    bool _1009;\n    if (!_1002)\n    {\n        _1009 = n >= fa_light_count();\n    }\n    else\n    {\n        _1009 = _1002;\n    }\n    if (_1009)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2);\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_363_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _562 = coord.xyz / coord.w.xxx;\n    float3 p = _562;\n    float2 suv = (_562.xy * 0.5f) + 0.5f.xx;\n    if (_363_fa_counts.z > 0.5f)\n    {\n        float3 _1836 = p;\n        _1836.z = (_1836.z * 0.5f) + 0.5f;\n        p = _1836;\n    }\n    else\n    {\n        float2 _1839 = suv;\n        _1839.y = 1.0f - _1839.y;\n        suv = _1839;\n    }\n    bool _588 = suv.x < 0.0f;\n    bool _595;\n    if (!_588)\n    {\n        _595 = suv.x > 1.0f;\n    }\n    else\n    {\n        _595 = _588;\n    }\n    bool _602;\n    if (!_595)\n    {\n        _602 = suv.y < 0.0f;\n    }\n    else\n    {\n        _602 = _595;\n    }\n    bool _609;\n    if (!_602)\n    {\n        _609 = suv.y > 1.0f;\n    }\n    else\n    {\n        _609 = _602;\n    }\n    bool _616;\n    if (!_609)\n    {\n        _616 = p.z > 1.0f;\n    }\n    else\n    {\n        _616 = _609;\n    }\n    if (_616)\n    {\n        return 1.0f;\n    }\n    float _631 = _363_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _631) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _363_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _945 = fa_light_sample(param, param_1);\n    float3 _1791 = _945.direction;\n    float3 _1786 = _945.color;\n    float _1788 = _945.shadow;\n    int _1796 = _945.type;\n    if ((_1796 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1791;\n        float _959 = fa_shadow_factor(param_2, param_3);\n        _1788 = _959;\n        _1786 *= _959;\n    }\n    LightSample _1803 = { _1791, _1786, _945.attenuation, _1788, _945._distance, _1796 };\n    return _1803;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _976 = n < 0;\n    bool _983;\n    if (!_976)\n    {\n        _983 = n >= fa_light_count();\n    }\n    else\n    {\n        _983 = _976;\n    }\n    if (_983)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _804 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _807 = _804.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_807 * _807, exp2((-9.27999973297119140625f) * ndv)) * _807) + _804.y)) + _804.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_363_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _363_fa_env_horizon.w).xyz;\n    }\n    float _725 = rough * rough;\n    float _756 = 0.60000002384185791015625f * _725;\n    return lerp(lerp(_363_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_363_fa_env_horizon.xyz, _363_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _725)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _756, 0.0500000007450580596923828125f + _756, d.y).xxx), ((_363_fa_env_sky.xyz + _363_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_725 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _846 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _846.x) + _846.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float3 param = normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = lerp(0.039999999105930328369140625f.xxx, s.albedo, clamp(s.metallic, 0.0f, 1.0f).xxx);\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1048 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_1048 > bestPower)\n        {\n            bestPower = _1048;\n            best = n;\n        }\n    }\n    float3 lit = (_363_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1077 = fa_light(param_2, param_3);\n        float _1085;\n        if (dot(s.normal, _1077.direction) > 0.5f)\n        {\n            _1085 = 1.0f;\n        }\n        else\n        {\n            _1085 = _1091_dark;\n        }\n        lit += ((s.albedo * _1077.color) * _1085);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _1091_skyAmount);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1691 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1691 = -_1691;\n    }\n    float3 _1398 = normalize(_363_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _1704 = { fa_world_pos, _1691, fa_world_tangent, fa_uv, fa_vertex_color, _1398, gl_FrontFacing };\n    SurfaceInput param_1 = _1704;\n    Surface _1406 = fa_standard_surface(param_1);\n    float3 _1722 = _1406.albedo;\n    float _1723 = _1406.alpha;\n    float3 _1724 = _1406.normal;\n    float _1725 = _1406.metallic;\n    float _1726 = _1406.roughness;\n    float _1727 = _1406.occlusion;\n    float3 _1728 = _1406.emission;\n    SurfaceInput _1712 = { fa_world_pos, _1691, fa_world_tangent, fa_uv, fa_vertex_color, _1398, gl_FrontFacing };\n    SurfaceInput param_2 = _1712;\n    Surface param_3 = _1406;\n    surface(param_2, param_3);\n    _1722 = param_3.albedo;\n    _1723 = param_3.alpha;\n    _1724 = param_3.normal;\n    _1725 = param_3.metallic;\n    _1726 = param_3.roughness;\n    _1727 = param_3.occlusion;\n    _1728 = param_3.emission;\n    float3 result;\n    if (_363_fa_emissive.w > 0.5f)\n    {\n        result = _1722;\n    }\n    else\n    {\n        float3 _1427 = _1724;\n        float3 _1428 = normalize(_1427);\n        _1724 = _1428;\n        SurfaceInput _1720 = { fa_world_pos, _1691, fa_world_tangent, fa_uv, fa_vertex_color, _1398, gl_FrontFacing };\n        SurfaceInput param_4 = _1720;\n        Surface _1758 = { _1722, _1723, _1428, _1725, _1726, _1727, _1728 };\n        Surface param_5 = _1758;\n        result = lighting(param_4, param_5);\n    }\n    result += _1728;\n    bool _1448 = _363_fa_fog.w > 0.0f;\n    bool _1456;\n    if (!_1448)\n    {\n        _1456 = _363_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1456 = _1448;\n    }\n    if (_1456)\n    {\n        float3 _1465 = fa_world_pos - _363_fa_camera_pos.xyz;\n        float _1472 = dot(_1465, _363_fa_fog_c.xyz);\n        bool _1476 = _363_fa_fog_c.w > 0.5f;\n        float _1477;\n        if (_1476)\n        {\n            _1477 = _1472;\n        }\n        else\n        {\n            _1477 = length(_1465);\n        }\n        float _1489 = _1477 - _363_fa_fog_b.x;\n        if (_1489 > 0.0f)\n        {\n            float _1498 = _363_fa_fog.w * _1489;\n            float tau = _1498 * _1498;\n            if (_363_fa_fog_b.y > 0.0f)\n            {\n                float _1514;\n                if (_1476)\n                {\n                    _1514 = fa_world_pos.y - (_363_fa_fog_c.y * _1472);\n                }\n                else\n                {\n                    _1514 = _363_fa_camera_pos.y;\n                }\n                float _1535 = lerp(_1514, fa_world_pos.y, clamp(_363_fa_fog_b.x / _1477, 0.0f, 1.0f));\n                float _1539 = fa_world_pos.y - _1535;\n                float _1544 = _1535 - _363_fa_fog_b.z;\n                float _1549 = fa_world_pos.y - _363_fa_fog_b.z;\n                bool _1552 = _1544 <= 0.0f;\n                bool _1553 = !_1552;\n                bool _1559;\n                if (_1553)\n                {\n                    _1559 = _363_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1559 = _1552;\n                }\n                float _1560;\n                if (_1559)\n                {\n                    _1560 = _363_fa_fog_b.y;\n                }\n                else\n                {\n                    _1560 = _363_fa_fog_b.y * exp(-min(_363_fa_fog_b.w * _1544, 80.0f));\n                }\n                bool _1587;\n                if (_1553)\n                {\n                    _1587 = _363_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1587 = _1552;\n                }\n                float _1588;\n                if (_1587)\n                {\n                    _1588 = _363_fa_fog_b.y * _1544;\n                }\n                else\n                {\n                    _1588 = (_363_fa_fog_b.y * (1.0f - exp(-min(_363_fa_fog_b.w * _1544, 80.0f)))) / _363_fa_fog_b.w;\n                }\n                bool _1613 = _1549 <= 0.0f;\n                bool _1620;\n                if (!_1613)\n                {\n                    _1620 = _363_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1620 = _1613;\n                }\n                float _1621;\n                if (_1620)\n                {\n                    _1621 = _363_fa_fog_b.y * _1549;\n                }\n                else\n                {\n                    _1621 = (_363_fa_fog_b.y * (1.0f - exp(-min(_363_fa_fog_b.w * _1549, 80.0f)))) / _363_fa_fog_b.w;\n                }\n                float _1648;\n                if (abs(_1539) < 0.001000000047497451305389404296875f)\n                {\n                    _1648 = _1560;\n                }\n                else\n                {\n                    _1648 = (_1621 - _1588) / _1539;\n                }\n                tau += (_1489 * max(_1648, 0.0f));\n            }\n            result = lerp(result, _363_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1723);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_363",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1091",
            "hlsl_register_b_n": 5
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 7,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _295 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _295;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0f);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _590 = base_t;\n    _590.x = _225.x;\n    _590.y = _225.y;\n    _590.z = _225.z;\n    base_t = _590;\n    float4 _241 = (_590 * _213_fa_base_color) * i.vertex_color;\n    float3 _571 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _598 = _279;\n        _598.x = _284.x;\n        _598.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _598;\n        _571 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _601 = mrt;\n    _601.x = _313.x;\n    _601.y = _313.y;\n    _601.z = _313.z;\n    mrt = _601;\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    Surface _583 = { _241.xyz, _241.w, _571, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_354.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _381) };\n    return _583;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _518 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _518 = -_518;\n    }\n    float3 _427 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _531 = { fa_world_pos, _518, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param = _531;\n    SurfaceInput _539 = { fa_world_pos, _518, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param_1 = _539;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _442 = normalize(param_2.normal);\n    float3 _457 = normalize(float3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / ((abs(_457.x) + abs(_457.y)) + abs(_469)).xx;\n    if (_469 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _416 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _416;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0f);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _590 = base_t;\n    _590.x = _225.x;\n    _590.y = _225.y;\n    _590.z = _225.z;\n    base_t = _590;\n    float4 _241 = (_590 * _213_fa_base_color) * i.vertex_color;\n    float3 _571 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _598 = _279;\n        _598.x = _284.x;\n        _598.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _598;\n        _571 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _601 = mrt;\n    _601.x = _313.x;\n    _601.y = _313.y;\n    _601.z = _313.z;\n    mrt = _601;\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    Surface _583 = { _241.xyz, _241.w, _571, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_354.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _381) };\n    return _583;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _518 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _518 = -_518;\n    }\n    float3 _427 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _531 = { fa_world_pos, _518, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param = _531;\n    SurfaceInput _539 = { fa_world_pos, _518, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param_1 = _539;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _442 = normalize(param_2.normal);\n    float3 _457 = normalize(float3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / ((abs(_457.x) + abs(_457.y)) + abs(_469)).xx;\n    if (_469 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
