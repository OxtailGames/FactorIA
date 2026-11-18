{
  "format": "factoria.shader/1",
  "engine": "0.30.1",
  "template": "613baa5de3e7fc21dce8c136754e8fcf0d062b3be3638910563d6cfc24aa4842",
  "slang": "hlsl5",
  "params": [
    "glow"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _129_fa_view_proj : packoffset(c0);\n    row_major float4x4 _129_fa_light_vp : packoffset(c4);\n    float4 _129_fa_uv_scale : packoffset(c8);\n    float4 _129_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * _129_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _158.world_pos;\n    float4 _165 = float4(_270, 1.0f);\n    fa_world_pos = _270;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_shadow_pos = mul(_165, _129_fa_light_vp);\n    gl_Position = mul(_165, _129_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _136_glow : packoffset(c0);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _241_fa_camera_pos : packoffset(c0);\n    float4 _241_fa_ambient : packoffset(c1);\n    float4 _241_fa_base_color : packoffset(c2);\n    float4 _241_fa_emissive : packoffset(c3);\n    float4 _241_fa_model_emissive : packoffset(c4);\n    float4 _241_fa_pbr : packoffset(c5);\n    float4 _241_fa_maps : packoffset(c6);\n    float4 _241_fa_fog : packoffset(c7);\n    float4 _241_fa_fog_b : packoffset(c8);\n    float4 _241_fa_fog_c : packoffset(c9);\n    float4 _241_fa_counts : packoffset(c10);\n    float4 _241_fa_env_sky : packoffset(c11);\n    float4 _241_fa_env_horizon : packoffset(c12);\n    float4 _241_fa_time : packoffset(c13);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _804_fa_light_pos[32] : packoffset(c0);\n    float4 _804_fa_light_color[32] : packoffset(c32);\n    float4 _804_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _200 = fa_linear_to_srgb(param);\n        c = _200;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _209 = fa_srgb_to_linear(param_1);\n            c = _209;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _68;\n    if (i.front_facing)\n    {\n        _68 = i.world_normal;\n    }\n    else\n    {\n        _68 = -i.world_normal;\n    }\n    float3 _93 = normalize(i.world_tangent.xyz - (_68 * dot(_68, i.world_tangent.xyz)));\n    float3 _121 = normalize(((_93 * m.x) + ((cross(_68, _93) * i.world_tangent.w) * m.y)) + (_68 * m.z));\n    float3 _124;\n    if (i.front_facing)\n    {\n        _124 = _121;\n    }\n    else\n    {\n        _124 = -_121;\n    }\n    return _124;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _241_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _252 = fa_tex_fix(param_2, param_3);\n    float4 _1328 = base_t;\n    _1328.x = _252.x;\n    _1328.y = _252.y;\n    _1328.z = _252.z;\n    base_t = _1328;\n    float4 _267 = (_1328 * _241_fa_base_color) * i.vertex_color;\n    float3 _1312 = i.world_normal;\n    if (_241_fa_maps.z > 0.5f)\n    {\n        float param_4 = _241_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _300 = fa_tex_fix(param_6, param_7);\n        float3 _304 = (_300 * 2.0f) - 1.0f.xxx;\n        float2 _309 = _304.xy * _241_fa_maps.x;\n        float3 _1336 = _304;\n        _1336.x = _309.x;\n        _1336.y = _309.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1336;\n        _1312 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _241_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _338 = fa_tex_fix(param_12, param_13);\n    float4 _1339 = mrt;\n    _1339.x = _338.x;\n    _1339.y = _338.y;\n    _1339.z = _338.z;\n    mrt = _1339;\n    float param_14 = _241_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _379 = fa_tex_fix(param_16, param_17);\n    float param_18 = _241_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _406 = fa_tex_fix(param_20, param_21);\n    Surface _1324 = { _267.xyz, _267.w, _1312, clamp(_241_fa_pbr.x * _338.z, 0.0f, 1.0f), clamp(_241_fa_pbr.y * _338.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_241_fa_maps.y * (_379.x - 1.0f)), _241_fa_emissive.xyz + (_241_fa_model_emissive.xyz * _406) };\n    return _1324;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (_136_glow.xyz * _136_glow.w);\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_241_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _428 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _428;\n    float2 suv = (_428.xy * 0.5f) + 0.5f.xx;\n    if (_241_fa_counts.z > 0.5f)\n    {\n        float3 _1347 = p;\n        _1347.z = (_1347.z * 0.5f) + 0.5f;\n        p = _1347;\n    }\n    else\n    {\n        float2 _1350 = suv;\n        _1350.y = 1.0f - _1350.y;\n        suv = _1350;\n    }\n    bool _455 = suv.x < 0.0f;\n    bool _462;\n    if (!_455)\n    {\n        _462 = suv.x > 1.0f;\n    }\n    else\n    {\n        _462 = _455;\n    }\n    bool _469;\n    if (!_462)\n    {\n        _469 = suv.y < 0.0f;\n    }\n    else\n    {\n        _469 = _462;\n    }\n    bool _476;\n    if (!_469)\n    {\n        _476 = suv.y > 1.0f;\n    }\n    else\n    {\n        _476 = _469;\n    }\n    bool _483;\n    if (!_476)\n    {\n        _483 = p.z > 1.0f;\n    }\n    else\n    {\n        _483 = _476;\n    }\n    if (_483)\n    {\n        return 1.0f;\n    }\n    float _497 = _241_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _497) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _241_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _638 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _641 = _638.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_641 * _641, exp2((-9.27999973297119140625f) * ndv)) * _641) + _638.y)) + _638.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _558 = rough * rough;\n    float _591 = 0.60000002384185791015625f * _558;\n    return lerp(lerp(_241_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_241_fa_env_horizon.xyz, _241_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _558)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _591, 0.0500000007450580596923828125f + _591, d.y).xxx), ((_241_fa_env_sky.xyz + _241_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_558 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    float3 _1258 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1258 = -_1258;\n    }\n    float3 _702 = normalize(_241_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _1271 = { fa_world_pos, _1258, fa_world_tangent, fa_uv, fa_vertex_color, _702, gl_FrontFacing };\n    SurfaceInput param = _1271;\n    Surface _707 = fa_standard_surface(param);\n    float3 _1281 = _707.albedo;\n    float _1282 = _707.alpha;\n    float3 _1283 = _707.normal;\n    float _1284 = _707.metallic;\n    float _1285 = _707.roughness;\n    float _1286 = _707.occlusion;\n    float3 _1287 = _707.emission;\n    SurfaceInput _1279 = { fa_world_pos, _1258, fa_world_tangent, fa_uv, fa_vertex_color, _702, gl_FrontFacing };\n    SurfaceInput param_1 = _1279;\n    Surface param_2 = _707;\n    surface(param_1, param_2);\n    _1281 = param_2.albedo;\n    _1282 = param_2.alpha;\n    _1283 = param_2.normal;\n    _1284 = param_2.metallic;\n    _1285 = param_2.roughness;\n    _1286 = param_2.occlusion;\n    _1287 = param_2.emission;\n    float3 result;\n    if (_241_fa_emissive.w > 0.5f)\n    {\n        result = _1281;\n    }\n    else\n    {\n        float3 _729 = normalize(_1283);\n        float _736 = clamp(_1284, 0.0f, 1.0f);\n        float _740 = clamp(_1285, 0.0500000007450580596923828125f, 1.0f);\n        float _744 = _740 * _740;\n        float _748 = _744 * _744;\n        float _754 = max(dot(_729, _702), 9.9999997473787516355514526367188e-05f);\n        float3 _760 = _1281 * (1.0f - _736);\n        float3 _768 = lerp(0.039999999105930328369140625f.xxx, _1281, _736.xxx);\n        float3 lit = (_241_fa_ambient.xyz * _760) * _1286;\n        int _781 = int(_241_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _781)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _810 = _804_fa_light_color[li].w < 0.5f;\n            if (_810)\n            {\n                l = normalize(_804_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _827 = _804_fa_light_pos[li].xyz - fa_world_pos;\n                float _830 = length(_827);\n                l = _827 / max(_830, 9.9999997473787516355514526367188e-05f).xxx;\n                float _845 = _830 / max(_804_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _851 = clamp(1.0f - (_845 * _845), 0.0f, 1.0f);\n                atten = _851 * _851;\n                if (_804_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_804_fa_light_dir[li].w, lerp(_804_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_804_fa_light_dir[li].xyz)));\n                }\n            }\n            float _884 = max(dot(_729, l), 0.0f);\n            if (_810 && (li == 0))\n            {\n                float3 param_3 = _1258;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            float3 _903 = normalize(l + _702);\n            float _908 = max(dot(_729, _903), 0.0f);\n            float _921 = ((_908 * _908) * (_748 - 1.0f)) + 1.0f;\n            lit += (((_760 + (((_768 + ((1.0f.xxx - _768) * pow(1.0f - max(dot(_702, _903), 0.0f), 5.0f))) * (((_748 / ((3.1415927410125732421875f * _921) * _921)) * (0.5f / max(lerp((2.0f * _884) * _754, _884 + _754, _744), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _884))) * _804_fa_light_color[li].xyz) * (_884 * atten));\n        }\n        float param_5 = _740;\n        float param_6 = _754;\n        float2 _989 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_702, _729);\n        float param_8 = _740;\n        float3 _1007 = lit;\n        float3 _1008 = _1007 + ((fa_environment(param_7, param_8) * ((_768 * _989.x) + _989.y.xxx)) * _1286);\n        lit = _1008;\n        result = _1008;\n    }\n    result += _1287;\n    bool _1017 = _241_fa_fog.w > 0.0f;\n    bool _1025;\n    if (!_1017)\n    {\n        _1025 = _241_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1025 = _1017;\n    }\n    if (_1025)\n    {\n        float3 _1034 = fa_world_pos - _241_fa_camera_pos.xyz;\n        float _1041 = dot(_1034, _241_fa_fog_c.xyz);\n        bool _1045 = _241_fa_fog_c.w > 0.5f;\n        float _1046;\n        if (_1045)\n        {\n            _1046 = _1041;\n        }\n        else\n        {\n            _1046 = length(_1034);\n        }\n        float _1058 = _1046 - _241_fa_fog_b.x;\n        if (_1058 > 0.0f)\n        {\n            float _1067 = _241_fa_fog.w * _1058;\n            float tau = _1067 * _1067;\n            if (_241_fa_fog_b.y > 0.0f)\n            {\n                float _1083;\n                if (_1045)\n                {\n                    _1083 = fa_world_pos.y - (_241_fa_fog_c.y * _1041);\n                }\n                else\n                {\n                    _1083 = _241_fa_camera_pos.y;\n                }\n                float _1104 = lerp(_1083, fa_world_pos.y, clamp(_241_fa_fog_b.x / _1046, 0.0f, 1.0f));\n                float _1108 = fa_world_pos.y - _1104;\n                float _1113 = _1104 - _241_fa_fog_b.z;\n                float _1118 = fa_world_pos.y - _241_fa_fog_b.z;\n                bool _1121 = _1113 <= 0.0f;\n                bool _1122 = !_1121;\n                bool _1128;\n                if (_1122)\n                {\n                    _1128 = _241_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1128 = _1121;\n                }\n                float _1129;\n                if (_1128)\n                {\n                    _1129 = _241_fa_fog_b.y;\n                }\n                else\n                {\n                    _1129 = _241_fa_fog_b.y * exp(-min(_241_fa_fog_b.w * _1113, 80.0f));\n                }\n                bool _1156;\n                if (_1122)\n                {\n                    _1156 = _241_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1156 = _1121;\n                }\n                float _1157;\n                if (_1156)\n                {\n                    _1157 = _241_fa_fog_b.y * _1113;\n                }\n                else\n                {\n                    _1157 = (_241_fa_fog_b.y * (1.0f - exp(-min(_241_fa_fog_b.w * _1113, 80.0f)))) / _241_fa_fog_b.w;\n                }\n                bool _1182 = _1118 <= 0.0f;\n                bool _1189;\n                if (!_1182)\n                {\n                    _1189 = _241_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1189 = _1182;\n                }\n                float _1190;\n                if (_1189)\n                {\n                    _1190 = _241_fa_fog_b.y * _1118;\n                }\n                else\n                {\n                    _1190 = (_241_fa_fog_b.y * (1.0f - exp(-min(_241_fa_fog_b.w * _1118, 80.0f)))) / _241_fa_fog_b.w;\n                }\n                float _1217;\n                if (abs(_1108) < 0.001000000047497451305389404296875f)\n                {\n                    _1217 = _1129;\n                }\n                else\n                {\n                    _1217 = (_1190 - _1157) / _1108;\n                }\n                tau += (_1058 * max(_1217, 0.0f));\n            }\n            result = lerp(result, _241_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1282);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_129",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_136",
            "hlsl_register_b_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_241",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_804",
            "hlsl_register_b_n": 2
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
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
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
          },
          {
            "slot": 5,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _134_fa_view_proj : packoffset(c0);\n    row_major float4x4 _134_fa_light_vp : packoffset(c4);\n    float4 _134_fa_uv_scale : packoffset(c8);\n    float4 _134_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _181_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _172 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_181_fa_joint_rows[_172] * weights[i]);\n        r1 += (_181_fa_joint_rows[_172 + 1] * weights[i]);\n        r2 += (_181_fa_joint_rows[_172 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _384 = { mul(float4(position, 1.0f), model).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * _134_fa_uv_scale.xy, color, position };\n    return _384;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _271 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _391 = _271.world_pos;\n    float4 _278 = float4(_391, 1.0f);\n    fa_world_pos = _391;\n    fa_world_normal = _271.world_normal;\n    fa_world_tangent = _271.world_tangent;\n    fa_uv = _271.uv;\n    fa_vertex_color = _271.color;\n    fa_shadow_pos = mul(_278, _134_fa_light_vp);\n    gl_Position = mul(_278, _134_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _136_glow : packoffset(c0);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _241_fa_camera_pos : packoffset(c0);\n    float4 _241_fa_ambient : packoffset(c1);\n    float4 _241_fa_base_color : packoffset(c2);\n    float4 _241_fa_emissive : packoffset(c3);\n    float4 _241_fa_model_emissive : packoffset(c4);\n    float4 _241_fa_pbr : packoffset(c5);\n    float4 _241_fa_maps : packoffset(c6);\n    float4 _241_fa_fog : packoffset(c7);\n    float4 _241_fa_fog_b : packoffset(c8);\n    float4 _241_fa_fog_c : packoffset(c9);\n    float4 _241_fa_counts : packoffset(c10);\n    float4 _241_fa_env_sky : packoffset(c11);\n    float4 _241_fa_env_horizon : packoffset(c12);\n    float4 _241_fa_time : packoffset(c13);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _804_fa_light_pos[32] : packoffset(c0);\n    float4 _804_fa_light_color[32] : packoffset(c32);\n    float4 _804_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _200 = fa_linear_to_srgb(param);\n        c = _200;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _209 = fa_srgb_to_linear(param_1);\n            c = _209;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _68;\n    if (i.front_facing)\n    {\n        _68 = i.world_normal;\n    }\n    else\n    {\n        _68 = -i.world_normal;\n    }\n    float3 _93 = normalize(i.world_tangent.xyz - (_68 * dot(_68, i.world_tangent.xyz)));\n    float3 _121 = normalize(((_93 * m.x) + ((cross(_68, _93) * i.world_tangent.w) * m.y)) + (_68 * m.z));\n    float3 _124;\n    if (i.front_facing)\n    {\n        _124 = _121;\n    }\n    else\n    {\n        _124 = -_121;\n    }\n    return _124;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _241_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _252 = fa_tex_fix(param_2, param_3);\n    float4 _1328 = base_t;\n    _1328.x = _252.x;\n    _1328.y = _252.y;\n    _1328.z = _252.z;\n    base_t = _1328;\n    float4 _267 = (_1328 * _241_fa_base_color) * i.vertex_color;\n    float3 _1312 = i.world_normal;\n    if (_241_fa_maps.z > 0.5f)\n    {\n        float param_4 = _241_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _300 = fa_tex_fix(param_6, param_7);\n        float3 _304 = (_300 * 2.0f) - 1.0f.xxx;\n        float2 _309 = _304.xy * _241_fa_maps.x;\n        float3 _1336 = _304;\n        _1336.x = _309.x;\n        _1336.y = _309.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1336;\n        _1312 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _241_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _338 = fa_tex_fix(param_12, param_13);\n    float4 _1339 = mrt;\n    _1339.x = _338.x;\n    _1339.y = _338.y;\n    _1339.z = _338.z;\n    mrt = _1339;\n    float param_14 = _241_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _379 = fa_tex_fix(param_16, param_17);\n    float param_18 = _241_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _406 = fa_tex_fix(param_20, param_21);\n    Surface _1324 = { _267.xyz, _267.w, _1312, clamp(_241_fa_pbr.x * _338.z, 0.0f, 1.0f), clamp(_241_fa_pbr.y * _338.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_241_fa_maps.y * (_379.x - 1.0f)), _241_fa_emissive.xyz + (_241_fa_model_emissive.xyz * _406) };\n    return _1324;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (_136_glow.xyz * _136_glow.w);\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_241_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _428 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _428;\n    float2 suv = (_428.xy * 0.5f) + 0.5f.xx;\n    if (_241_fa_counts.z > 0.5f)\n    {\n        float3 _1347 = p;\n        _1347.z = (_1347.z * 0.5f) + 0.5f;\n        p = _1347;\n    }\n    else\n    {\n        float2 _1350 = suv;\n        _1350.y = 1.0f - _1350.y;\n        suv = _1350;\n    }\n    bool _455 = suv.x < 0.0f;\n    bool _462;\n    if (!_455)\n    {\n        _462 = suv.x > 1.0f;\n    }\n    else\n    {\n        _462 = _455;\n    }\n    bool _469;\n    if (!_462)\n    {\n        _469 = suv.y < 0.0f;\n    }\n    else\n    {\n        _469 = _462;\n    }\n    bool _476;\n    if (!_469)\n    {\n        _476 = suv.y > 1.0f;\n    }\n    else\n    {\n        _476 = _469;\n    }\n    bool _483;\n    if (!_476)\n    {\n        _483 = p.z > 1.0f;\n    }\n    else\n    {\n        _483 = _476;\n    }\n    if (_483)\n    {\n        return 1.0f;\n    }\n    float _497 = _241_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _497) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _241_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _638 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _641 = _638.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_641 * _641, exp2((-9.27999973297119140625f) * ndv)) * _641) + _638.y)) + _638.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _558 = rough * rough;\n    float _591 = 0.60000002384185791015625f * _558;\n    return lerp(lerp(_241_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_241_fa_env_horizon.xyz, _241_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _558)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _591, 0.0500000007450580596923828125f + _591, d.y).xxx), ((_241_fa_env_sky.xyz + _241_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_558 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    float3 _1258 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1258 = -_1258;\n    }\n    float3 _702 = normalize(_241_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _1271 = { fa_world_pos, _1258, fa_world_tangent, fa_uv, fa_vertex_color, _702, gl_FrontFacing };\n    SurfaceInput param = _1271;\n    Surface _707 = fa_standard_surface(param);\n    float3 _1281 = _707.albedo;\n    float _1282 = _707.alpha;\n    float3 _1283 = _707.normal;\n    float _1284 = _707.metallic;\n    float _1285 = _707.roughness;\n    float _1286 = _707.occlusion;\n    float3 _1287 = _707.emission;\n    SurfaceInput _1279 = { fa_world_pos, _1258, fa_world_tangent, fa_uv, fa_vertex_color, _702, gl_FrontFacing };\n    SurfaceInput param_1 = _1279;\n    Surface param_2 = _707;\n    surface(param_1, param_2);\n    _1281 = param_2.albedo;\n    _1282 = param_2.alpha;\n    _1283 = param_2.normal;\n    _1284 = param_2.metallic;\n    _1285 = param_2.roughness;\n    _1286 = param_2.occlusion;\n    _1287 = param_2.emission;\n    float3 result;\n    if (_241_fa_emissive.w > 0.5f)\n    {\n        result = _1281;\n    }\n    else\n    {\n        float3 _729 = normalize(_1283);\n        float _736 = clamp(_1284, 0.0f, 1.0f);\n        float _740 = clamp(_1285, 0.0500000007450580596923828125f, 1.0f);\n        float _744 = _740 * _740;\n        float _748 = _744 * _744;\n        float _754 = max(dot(_729, _702), 9.9999997473787516355514526367188e-05f);\n        float3 _760 = _1281 * (1.0f - _736);\n        float3 _768 = lerp(0.039999999105930328369140625f.xxx, _1281, _736.xxx);\n        float3 lit = (_241_fa_ambient.xyz * _760) * _1286;\n        int _781 = int(_241_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _781)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _810 = _804_fa_light_color[li].w < 0.5f;\n            if (_810)\n            {\n                l = normalize(_804_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _827 = _804_fa_light_pos[li].xyz - fa_world_pos;\n                float _830 = length(_827);\n                l = _827 / max(_830, 9.9999997473787516355514526367188e-05f).xxx;\n                float _845 = _830 / max(_804_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _851 = clamp(1.0f - (_845 * _845), 0.0f, 1.0f);\n                atten = _851 * _851;\n                if (_804_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_804_fa_light_dir[li].w, lerp(_804_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_804_fa_light_dir[li].xyz)));\n                }\n            }\n            float _884 = max(dot(_729, l), 0.0f);\n            if (_810 && (li == 0))\n            {\n                float3 param_3 = _1258;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            float3 _903 = normalize(l + _702);\n            float _908 = max(dot(_729, _903), 0.0f);\n            float _921 = ((_908 * _908) * (_748 - 1.0f)) + 1.0f;\n            lit += (((_760 + (((_768 + ((1.0f.xxx - _768) * pow(1.0f - max(dot(_702, _903), 0.0f), 5.0f))) * (((_748 / ((3.1415927410125732421875f * _921) * _921)) * (0.5f / max(lerp((2.0f * _884) * _754, _884 + _754, _744), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _884))) * _804_fa_light_color[li].xyz) * (_884 * atten));\n        }\n        float param_5 = _740;\n        float param_6 = _754;\n        float2 _989 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_702, _729);\n        float param_8 = _740;\n        float3 _1007 = lit;\n        float3 _1008 = _1007 + ((fa_environment(param_7, param_8) * ((_768 * _989.x) + _989.y.xxx)) * _1286);\n        lit = _1008;\n        result = _1008;\n    }\n    result += _1287;\n    bool _1017 = _241_fa_fog.w > 0.0f;\n    bool _1025;\n    if (!_1017)\n    {\n        _1025 = _241_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1025 = _1017;\n    }\n    if (_1025)\n    {\n        float3 _1034 = fa_world_pos - _241_fa_camera_pos.xyz;\n        float _1041 = dot(_1034, _241_fa_fog_c.xyz);\n        bool _1045 = _241_fa_fog_c.w > 0.5f;\n        float _1046;\n        if (_1045)\n        {\n            _1046 = _1041;\n        }\n        else\n        {\n            _1046 = length(_1034);\n        }\n        float _1058 = _1046 - _241_fa_fog_b.x;\n        if (_1058 > 0.0f)\n        {\n            float _1067 = _241_fa_fog.w * _1058;\n            float tau = _1067 * _1067;\n            if (_241_fa_fog_b.y > 0.0f)\n            {\n                float _1083;\n                if (_1045)\n                {\n                    _1083 = fa_world_pos.y - (_241_fa_fog_c.y * _1041);\n                }\n                else\n                {\n                    _1083 = _241_fa_camera_pos.y;\n                }\n                float _1104 = lerp(_1083, fa_world_pos.y, clamp(_241_fa_fog_b.x / _1046, 0.0f, 1.0f));\n                float _1108 = fa_world_pos.y - _1104;\n                float _1113 = _1104 - _241_fa_fog_b.z;\n                float _1118 = fa_world_pos.y - _241_fa_fog_b.z;\n                bool _1121 = _1113 <= 0.0f;\n                bool _1122 = !_1121;\n                bool _1128;\n                if (_1122)\n                {\n                    _1128 = _241_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1128 = _1121;\n                }\n                float _1129;\n                if (_1128)\n                {\n                    _1129 = _241_fa_fog_b.y;\n                }\n                else\n                {\n                    _1129 = _241_fa_fog_b.y * exp(-min(_241_fa_fog_b.w * _1113, 80.0f));\n                }\n                bool _1156;\n                if (_1122)\n                {\n                    _1156 = _241_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1156 = _1121;\n                }\n                float _1157;\n                if (_1156)\n                {\n                    _1157 = _241_fa_fog_b.y * _1113;\n                }\n                else\n                {\n                    _1157 = (_241_fa_fog_b.y * (1.0f - exp(-min(_241_fa_fog_b.w * _1113, 80.0f)))) / _241_fa_fog_b.w;\n                }\n                bool _1182 = _1118 <= 0.0f;\n                bool _1189;\n                if (!_1182)\n                {\n                    _1189 = _241_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1189 = _1182;\n                }\n                float _1190;\n                if (_1189)\n                {\n                    _1190 = _241_fa_fog_b.y * _1118;\n                }\n                else\n                {\n                    _1190 = (_241_fa_fog_b.y * (1.0f - exp(-min(_241_fa_fog_b.w * _1118, 80.0f)))) / _241_fa_fog_b.w;\n                }\n                float _1217;\n                if (abs(_1108) < 0.001000000047497451305389404296875f)\n                {\n                    _1217 = _1129;\n                }\n                else\n                {\n                    _1217 = (_1190 - _1157) / _1108;\n                }\n                tau += (_1058 * max(_1217, 0.0f));\n            }\n            result = lerp(result, _241_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1282);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_134",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_181",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_136",
            "hlsl_register_b_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_241",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_804",
            "hlsl_register_b_n": 2
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
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
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
          },
          {
            "slot": 5,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _129_fa_view_proj : packoffset(c0);\n    row_major float4x4 _129_fa_light_vp : packoffset(c4);\n    float4 _129_fa_uv_scale : packoffset(c8);\n    float4 _129_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * _129_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _158.world_pos;\n    float4 _169 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_pre_depth = -mul(_169, _129_fa_light_vp).z;\n    fa_pre_r0 = float3(_129_fa_light_vp[0].x, _129_fa_light_vp[1].x, _129_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_129_fa_light_vp[0].y, _129_fa_light_vp[1].y, _129_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_129_fa_light_vp[0].z, _129_fa_light_vp[1].z, _129_fa_light_vp[2].z);\n    gl_Position = mul(_169, _129_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _122_glow : packoffset(c0);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _227_fa_camera_pos : packoffset(c0);\n    float4 _227_fa_ambient : packoffset(c1);\n    float4 _227_fa_base_color : packoffset(c2);\n    float4 _227_fa_emissive : packoffset(c3);\n    float4 _227_fa_model_emissive : packoffset(c4);\n    float4 _227_fa_pbr : packoffset(c5);\n    float4 _227_fa_maps : packoffset(c6);\n    float4 _227_fa_fog : packoffset(c7);\n    float4 _227_fa_fog_b : packoffset(c8);\n    float4 _227_fa_fog_c : packoffset(c9);\n    float4 _227_fa_counts : packoffset(c10);\n    float4 _227_fa_env_sky : packoffset(c11);\n    float4 _227_fa_env_horizon : packoffset(c12);\n    float4 _227_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _54;\n    if (i.front_facing)\n    {\n        _54 = i.world_normal;\n    }\n    else\n    {\n        _54 = -i.world_normal;\n    }\n    float3 _79 = normalize(i.world_tangent.xyz - (_54 * dot(_54, i.world_tangent.xyz)));\n    float3 _107 = normalize(((_79 * m.x) + ((cross(_54, _79) * i.world_tangent.w) * m.y)) + (_54 * m.z));\n    float3 _110;\n    if (i.front_facing)\n    {\n        _110 = _107;\n    }\n    else\n    {\n        _110 = -_107;\n    }\n    return _110;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _227_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _238 = fa_tex_fix(param_2, param_3);\n    float4 _591 = base_t;\n    _591.x = _238.x;\n    _591.y = _238.y;\n    _591.z = _238.z;\n    base_t = _591;\n    float4 _253 = (_591 * _227_fa_base_color) * i.vertex_color;\n    float3 _572 = i.world_normal;\n    if (_227_fa_maps.z > 0.5f)\n    {\n        float param_4 = _227_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _286 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_286 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _227_fa_maps.x;\n        float3 _599 = _290;\n        _599.x = _295.x;\n        _599.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _599;\n        _572 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _227_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _602 = mrt;\n    _602.x = _324.x;\n    _602.y = _324.y;\n    _602.z = _324.z;\n    mrt = _602;\n    float param_14 = _227_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _365 = fa_tex_fix(param_16, param_17);\n    float param_18 = _227_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _392 = fa_tex_fix(param_20, param_21);\n    Surface _584 = { _253.xyz, _253.w, _572, clamp(_227_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_227_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_227_fa_maps.y * (_365.x - 1.0f)), _227_fa_emissive.xyz + (_227_fa_model_emissive.xyz * _392) };\n    return _584;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (_122_glow.xyz * _122_glow.w);\n}\n\nvoid frag_main()\n{\n    float3 _519 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _519 = -_519;\n    }\n    float3 _437 = normalize(_227_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _532 = { fa_world_pos, _519, fa_world_tangent, fa_uv, fa_vertex_color, _437, gl_FrontFacing };\n    SurfaceInput param = _532;\n    SurfaceInput _540 = { fa_world_pos, _519, fa_world_tangent, fa_uv, fa_vertex_color, _437, gl_FrontFacing };\n    SurfaceInput param_1 = _540;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _452 = normalize(param_2.normal);\n    float3 _467 = normalize(float3(dot(fa_pre_r0, _452), dot(fa_pre_r1, _452), dot(fa_pre_r2, _452)));\n    float _479 = _467.z;\n    float2 e = _467.xy / ((abs(_467.x) + abs(_467.y)) + abs(_479)).xx;\n    if (_479 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_129",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_122",
            "hlsl_register_b_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_227",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _134_fa_view_proj : packoffset(c0);\n    row_major float4x4 _134_fa_light_vp : packoffset(c4);\n    float4 _134_fa_uv_scale : packoffset(c8);\n    float4 _134_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _181_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _172 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_181_fa_joint_rows[_172] * weights[i]);\n        r1 += (_181_fa_joint_rows[_172 + 1] * weights[i]);\n        r2 += (_181_fa_joint_rows[_172 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _413 = { mul(float4(position, 1.0f), model).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * _134_fa_uv_scale.xy, color, position };\n    return _413;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _271 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _420 = _271.world_pos;\n    float4 _282 = float4(_420, 1.0f);\n    fa_world_pos = _420;\n    fa_world_normal = _271.world_normal;\n    fa_world_tangent = _271.world_tangent;\n    fa_uv = _271.uv;\n    fa_vertex_color = _271.color;\n    fa_pre_depth = -mul(_282, _134_fa_light_vp).z;\n    fa_pre_r0 = float3(_134_fa_light_vp[0].x, _134_fa_light_vp[1].x, _134_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_134_fa_light_vp[0].y, _134_fa_light_vp[1].y, _134_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_134_fa_light_vp[0].z, _134_fa_light_vp[1].z, _134_fa_light_vp[2].z);\n    gl_Position = mul(_282, _134_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _122_glow : packoffset(c0);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _227_fa_camera_pos : packoffset(c0);\n    float4 _227_fa_ambient : packoffset(c1);\n    float4 _227_fa_base_color : packoffset(c2);\n    float4 _227_fa_emissive : packoffset(c3);\n    float4 _227_fa_model_emissive : packoffset(c4);\n    float4 _227_fa_pbr : packoffset(c5);\n    float4 _227_fa_maps : packoffset(c6);\n    float4 _227_fa_fog : packoffset(c7);\n    float4 _227_fa_fog_b : packoffset(c8);\n    float4 _227_fa_fog_c : packoffset(c9);\n    float4 _227_fa_counts : packoffset(c10);\n    float4 _227_fa_env_sky : packoffset(c11);\n    float4 _227_fa_env_horizon : packoffset(c12);\n    float4 _227_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _54;\n    if (i.front_facing)\n    {\n        _54 = i.world_normal;\n    }\n    else\n    {\n        _54 = -i.world_normal;\n    }\n    float3 _79 = normalize(i.world_tangent.xyz - (_54 * dot(_54, i.world_tangent.xyz)));\n    float3 _107 = normalize(((_79 * m.x) + ((cross(_54, _79) * i.world_tangent.w) * m.y)) + (_54 * m.z));\n    float3 _110;\n    if (i.front_facing)\n    {\n        _110 = _107;\n    }\n    else\n    {\n        _110 = -_107;\n    }\n    return _110;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _227_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _238 = fa_tex_fix(param_2, param_3);\n    float4 _591 = base_t;\n    _591.x = _238.x;\n    _591.y = _238.y;\n    _591.z = _238.z;\n    base_t = _591;\n    float4 _253 = (_591 * _227_fa_base_color) * i.vertex_color;\n    float3 _572 = i.world_normal;\n    if (_227_fa_maps.z > 0.5f)\n    {\n        float param_4 = _227_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _286 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_286 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _227_fa_maps.x;\n        float3 _599 = _290;\n        _599.x = _295.x;\n        _599.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _599;\n        _572 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _227_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _602 = mrt;\n    _602.x = _324.x;\n    _602.y = _324.y;\n    _602.z = _324.z;\n    mrt = _602;\n    float param_14 = _227_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _365 = fa_tex_fix(param_16, param_17);\n    float param_18 = _227_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _392 = fa_tex_fix(param_20, param_21);\n    Surface _584 = { _253.xyz, _253.w, _572, clamp(_227_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_227_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_227_fa_maps.y * (_365.x - 1.0f)), _227_fa_emissive.xyz + (_227_fa_model_emissive.xyz * _392) };\n    return _584;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (_122_glow.xyz * _122_glow.w);\n}\n\nvoid frag_main()\n{\n    float3 _519 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _519 = -_519;\n    }\n    float3 _437 = normalize(_227_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _532 = { fa_world_pos, _519, fa_world_tangent, fa_uv, fa_vertex_color, _437, gl_FrontFacing };\n    SurfaceInput param = _532;\n    SurfaceInput _540 = { fa_world_pos, _519, fa_world_tangent, fa_uv, fa_vertex_color, _437, gl_FrontFacing };\n    SurfaceInput param_1 = _540;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _452 = normalize(param_2.normal);\n    float3 _467 = normalize(float3(dot(fa_pre_r0, _452), dot(fa_pre_r1, _452), dot(fa_pre_r2, _452)));\n    float _479 = _467.z;\n    float2 e = _467.xy / ((abs(_467.x) + abs(_467.y)) + abs(_479)).xx;\n    if (_479 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_134",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_181",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_122",
            "hlsl_register_b_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_227",
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
