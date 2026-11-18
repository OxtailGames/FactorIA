{
  "format": "factoria.shader/1",
  "engine": "0.30.1",
  "template": "616705bcddf9b6a98bc0277c05f4815433dd40e61efe9f55376421e3ba39eecd",
  "slang": "hlsl5",
  "params": [
    "alphaCutoff"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _129_fa_view_proj : packoffset(c0);\n    row_major float4x4 _129_fa_light_vp : packoffset(c4);\n    float4 _129_fa_uv_scale : packoffset(c8);\n    float4 _129_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * _129_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _158.world_pos;\n    float4 _165 = float4(_270, 1.0f);\n    fa_world_pos = _270;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_shadow_pos = mul(_165, _129_fa_light_vp);\n    gl_Position = mul(_165, _129_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _225_fa_camera_pos : packoffset(c0);\n    float4 _225_fa_ambient : packoffset(c1);\n    float4 _225_fa_base_color : packoffset(c2);\n    float4 _225_fa_emissive : packoffset(c3);\n    float4 _225_fa_model_emissive : packoffset(c4);\n    float4 _225_fa_pbr : packoffset(c5);\n    float4 _225_fa_maps : packoffset(c6);\n    float4 _225_fa_fog : packoffset(c7);\n    float4 _225_fa_counts : packoffset(c8);\n    float4 _225_fa_env_sky : packoffset(c9);\n    float4 _225_fa_env_horizon : packoffset(c10);\n    float4 _225_fa_time : packoffset(c11);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _705_alphaCutoff : packoffset(c0);\n    float _705_fa_pad0 : packoffset(c0.y);\n    float _705_fa_pad1 : packoffset(c0.z);\n    float _705_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _802_fa_light_pos[32] : packoffset(c0);\n    float4 _802_fa_light_color[32] : packoffset(c32);\n    float4 _802_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _184 = fa_linear_to_srgb(param);\n        c = _184;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _193 = fa_srgb_to_linear(param_1);\n            c = _193;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _68;\n    if (i.front_facing)\n    {\n        _68 = i.world_normal;\n    }\n    else\n    {\n        _68 = -i.world_normal;\n    }\n    float3 _93 = normalize(i.world_tangent.xyz - (_68 * dot(_68, i.world_tangent.xyz)));\n    float3 _121 = normalize(((_93 * m.x) + ((cross(_68, _93) * i.world_tangent.w) * m.y)) + (_68 * m.z));\n    float3 _124;\n    if (i.front_facing)\n    {\n        _124 = _121;\n    }\n    else\n    {\n        _124 = -_121;\n    }\n    return _124;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _225_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _1125 = base_t;\n    _1125.x = _237.x;\n    _1125.y = _237.y;\n    _1125.z = _237.z;\n    base_t = _1125;\n    float4 _253 = (_1125 * _225_fa_base_color) * i.vertex_color;\n    float3 _1110 = i.world_normal;\n    if (_225_fa_maps.z > 0.5f)\n    {\n        float param_4 = _225_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _291 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _296 = _291.xy * _225_fa_maps.x;\n        float3 _1133 = _291;\n        _1133.x = _296.x;\n        _1133.y = _296.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1133;\n        _1110 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _225_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _325 = fa_tex_fix(param_12, param_13);\n    float4 _1136 = mrt;\n    _1136.x = _325.x;\n    _1136.y = _325.y;\n    _1136.z = _325.z;\n    mrt = _1136;\n    float param_14 = _225_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _393 = fa_tex_fix(param_20, param_21);\n    Surface _1122 = { _253.xyz, _253.w, _1110, clamp(_225_fa_pbr.x * _325.z, 0.0f, 1.0f), clamp(_225_fa_pbr.y * _325.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_225_fa_maps.y * (_366.x - 1.0f)), _225_fa_emissive.xyz + (_225_fa_model_emissive.xyz * _393) };\n    return _1122;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_225_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _415 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _415;\n    float2 suv = (_415.xy * 0.5f) + 0.5f.xx;\n    if (_225_fa_counts.z > 0.5f)\n    {\n        float3 _1144 = p;\n        _1144.z = (_1144.z * 0.5f) + 0.5f;\n        p = _1144;\n    }\n    else\n    {\n        float2 _1147 = suv;\n        _1147.y = 1.0f - _1147.y;\n        suv = _1147;\n    }\n    bool _442 = suv.x < 0.0f;\n    bool _449;\n    if (!_442)\n    {\n        _449 = suv.x > 1.0f;\n    }\n    else\n    {\n        _449 = _442;\n    }\n    bool _456;\n    if (!_449)\n    {\n        _456 = suv.y < 0.0f;\n    }\n    else\n    {\n        _456 = _449;\n    }\n    bool _463;\n    if (!_456)\n    {\n        _463 = suv.y > 1.0f;\n    }\n    else\n    {\n        _463 = _456;\n    }\n    bool _470;\n    if (!_463)\n    {\n        _470 = p.z > 1.0f;\n    }\n    else\n    {\n        _470 = _463;\n    }\n    if (_470)\n    {\n        return 1.0f;\n    }\n    float _484 = _225_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _484) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _225_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _625 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _628 = _625.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_628 * _628, exp2((-9.27999973297119140625f) * ndv)) * _628) + _625.y)) + _625.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _545 = rough * rough;\n    float _578 = 0.60000002384185791015625f * _545;\n    return lerp(lerp(_225_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_225_fa_env_horizon.xyz, _225_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _545)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _578, 0.0500000007450580596923828125f + _578, d.y).xxx), ((_225_fa_env_sky.xyz + _225_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_545 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    float3 _1057 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1057 = -_1057;\n    }\n    float3 _688 = _225_fa_camera_pos.xyz - fa_world_pos;\n    float3 _689 = normalize(_688);\n    SurfaceInput _1070 = { fa_world_pos, _1057, fa_world_tangent, fa_uv, fa_vertex_color, _689, gl_FrontFacing };\n    SurfaceInput param = _1070;\n    Surface _694 = fa_standard_surface(param);\n    float3 _1079 = _694.albedo;\n    float _1080 = _694.alpha;\n    float3 _1081 = _694.normal;\n    float _1082 = _694.metallic;\n    float _1083 = _694.roughness;\n    float _1084 = _694.occlusion;\n    float3 _1085 = _694.emission;\n    SurfaceInput _1078 = { fa_world_pos, _1057, fa_world_tangent, fa_uv, fa_vertex_color, _689, gl_FrontFacing };\n    SurfaceInput param_1 = _1078;\n    Surface param_2 = _694;\n    surface(param_1, param_2);\n    _1079 = param_2.albedo;\n    _1080 = param_2.alpha;\n    _1081 = param_2.normal;\n    _1082 = param_2.metallic;\n    _1083 = param_2.roughness;\n    _1084 = param_2.occlusion;\n    _1085 = param_2.emission;\n    if (param_2.alpha < _705_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_225_fa_emissive.w > 0.5f)\n    {\n        result = _1079;\n    }\n    else\n    {\n        float3 _727 = normalize(_1081);\n        float _734 = clamp(_1082, 0.0f, 1.0f);\n        float _738 = clamp(_1083, 0.0500000007450580596923828125f, 1.0f);\n        float _742 = _738 * _738;\n        float _746 = _742 * _742;\n        float _752 = max(dot(_727, _689), 9.9999997473787516355514526367188e-05f);\n        float3 _758 = _1079 * (1.0f - _734);\n        float3 _766 = lerp(0.039999999105930328369140625f.xxx, _1079, _734.xxx);\n        float3 lit = (_225_fa_ambient.xyz * _758) * _1084;\n        int _779 = int(_225_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _779)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _808 = _802_fa_light_color[li].w < 0.5f;\n            if (_808)\n            {\n                l = normalize(_802_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _825 = _802_fa_light_pos[li].xyz - fa_world_pos;\n                float _828 = length(_825);\n                l = _825 / max(_828, 9.9999997473787516355514526367188e-05f).xxx;\n                float _843 = _828 / max(_802_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _849 = clamp(1.0f - (_843 * _843), 0.0f, 1.0f);\n                atten = _849 * _849;\n                if (_802_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_802_fa_light_dir[li].w, lerp(_802_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_802_fa_light_dir[li].xyz)));\n                }\n            }\n            float _882 = max(dot(_727, l), 0.0f);\n            if (_808 && (li == 0))\n            {\n                float3 param_3 = _1057;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            float3 _901 = normalize(l + _689);\n            float _906 = max(dot(_727, _901), 0.0f);\n            float _919 = ((_906 * _906) * (_746 - 1.0f)) + 1.0f;\n            lit += (((_758 + (((_766 + ((1.0f.xxx - _766) * pow(1.0f - max(dot(_689, _901), 0.0f), 5.0f))) * (((_746 / ((3.1415927410125732421875f * _919) * _919)) * (0.5f / max(lerp((2.0f * _882) * _752, _882 + _752, _742), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _882))) * _802_fa_light_color[li].xyz) * (_882 * atten));\n        }\n        float param_5 = _738;\n        float param_6 = _752;\n        float2 _987 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_689, _727);\n        float param_8 = _738;\n        float3 _1005 = lit;\n        float3 _1006 = _1005 + ((fa_environment(param_7, param_8) * ((_766 * _987.x) + _987.y.xxx)) * _1084);\n        lit = _1006;\n        result = _1006;\n    }\n    result += _1085;\n    if (_225_fa_fog.w > 0.0f)\n    {\n        float _1030 = _225_fa_fog.w * length(_688);\n        result = lerp(result, _225_fa_fog.xyz, clamp(1.0f - exp((-_1030) * _1030), 0.0f, 1.0f).xxx);\n    }\n    fa_frag_color = float4(result, _1080);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_705",
            "hlsl_register_b_n": 5
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_802",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _225_fa_camera_pos : packoffset(c0);\n    float4 _225_fa_ambient : packoffset(c1);\n    float4 _225_fa_base_color : packoffset(c2);\n    float4 _225_fa_emissive : packoffset(c3);\n    float4 _225_fa_model_emissive : packoffset(c4);\n    float4 _225_fa_pbr : packoffset(c5);\n    float4 _225_fa_maps : packoffset(c6);\n    float4 _225_fa_fog : packoffset(c7);\n    float4 _225_fa_counts : packoffset(c8);\n    float4 _225_fa_env_sky : packoffset(c9);\n    float4 _225_fa_env_horizon : packoffset(c10);\n    float4 _225_fa_time : packoffset(c11);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _705_alphaCutoff : packoffset(c0);\n    float _705_fa_pad0 : packoffset(c0.y);\n    float _705_fa_pad1 : packoffset(c0.z);\n    float _705_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _802_fa_light_pos[32] : packoffset(c0);\n    float4 _802_fa_light_color[32] : packoffset(c32);\n    float4 _802_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _184 = fa_linear_to_srgb(param);\n        c = _184;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _193 = fa_srgb_to_linear(param_1);\n            c = _193;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _68;\n    if (i.front_facing)\n    {\n        _68 = i.world_normal;\n    }\n    else\n    {\n        _68 = -i.world_normal;\n    }\n    float3 _93 = normalize(i.world_tangent.xyz - (_68 * dot(_68, i.world_tangent.xyz)));\n    float3 _121 = normalize(((_93 * m.x) + ((cross(_68, _93) * i.world_tangent.w) * m.y)) + (_68 * m.z));\n    float3 _124;\n    if (i.front_facing)\n    {\n        _124 = _121;\n    }\n    else\n    {\n        _124 = -_121;\n    }\n    return _124;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _225_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _1125 = base_t;\n    _1125.x = _237.x;\n    _1125.y = _237.y;\n    _1125.z = _237.z;\n    base_t = _1125;\n    float4 _253 = (_1125 * _225_fa_base_color) * i.vertex_color;\n    float3 _1110 = i.world_normal;\n    if (_225_fa_maps.z > 0.5f)\n    {\n        float param_4 = _225_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _291 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _296 = _291.xy * _225_fa_maps.x;\n        float3 _1133 = _291;\n        _1133.x = _296.x;\n        _1133.y = _296.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1133;\n        _1110 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _225_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _325 = fa_tex_fix(param_12, param_13);\n    float4 _1136 = mrt;\n    _1136.x = _325.x;\n    _1136.y = _325.y;\n    _1136.z = _325.z;\n    mrt = _1136;\n    float param_14 = _225_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _393 = fa_tex_fix(param_20, param_21);\n    Surface _1122 = { _253.xyz, _253.w, _1110, clamp(_225_fa_pbr.x * _325.z, 0.0f, 1.0f), clamp(_225_fa_pbr.y * _325.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_225_fa_maps.y * (_366.x - 1.0f)), _225_fa_emissive.xyz + (_225_fa_model_emissive.xyz * _393) };\n    return _1122;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_225_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _415 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _415;\n    float2 suv = (_415.xy * 0.5f) + 0.5f.xx;\n    if (_225_fa_counts.z > 0.5f)\n    {\n        float3 _1144 = p;\n        _1144.z = (_1144.z * 0.5f) + 0.5f;\n        p = _1144;\n    }\n    else\n    {\n        float2 _1147 = suv;\n        _1147.y = 1.0f - _1147.y;\n        suv = _1147;\n    }\n    bool _442 = suv.x < 0.0f;\n    bool _449;\n    if (!_442)\n    {\n        _449 = suv.x > 1.0f;\n    }\n    else\n    {\n        _449 = _442;\n    }\n    bool _456;\n    if (!_449)\n    {\n        _456 = suv.y < 0.0f;\n    }\n    else\n    {\n        _456 = _449;\n    }\n    bool _463;\n    if (!_456)\n    {\n        _463 = suv.y > 1.0f;\n    }\n    else\n    {\n        _463 = _456;\n    }\n    bool _470;\n    if (!_463)\n    {\n        _470 = p.z > 1.0f;\n    }\n    else\n    {\n        _470 = _463;\n    }\n    if (_470)\n    {\n        return 1.0f;\n    }\n    float _484 = _225_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _484) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _225_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _625 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _628 = _625.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_628 * _628, exp2((-9.27999973297119140625f) * ndv)) * _628) + _625.y)) + _625.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _545 = rough * rough;\n    float _578 = 0.60000002384185791015625f * _545;\n    return lerp(lerp(_225_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_225_fa_env_horizon.xyz, _225_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _545)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _578, 0.0500000007450580596923828125f + _578, d.y).xxx), ((_225_fa_env_sky.xyz + _225_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_545 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    float3 _1057 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1057 = -_1057;\n    }\n    float3 _688 = _225_fa_camera_pos.xyz - fa_world_pos;\n    float3 _689 = normalize(_688);\n    SurfaceInput _1070 = { fa_world_pos, _1057, fa_world_tangent, fa_uv, fa_vertex_color, _689, gl_FrontFacing };\n    SurfaceInput param = _1070;\n    Surface _694 = fa_standard_surface(param);\n    float3 _1079 = _694.albedo;\n    float _1080 = _694.alpha;\n    float3 _1081 = _694.normal;\n    float _1082 = _694.metallic;\n    float _1083 = _694.roughness;\n    float _1084 = _694.occlusion;\n    float3 _1085 = _694.emission;\n    SurfaceInput _1078 = { fa_world_pos, _1057, fa_world_tangent, fa_uv, fa_vertex_color, _689, gl_FrontFacing };\n    SurfaceInput param_1 = _1078;\n    Surface param_2 = _694;\n    surface(param_1, param_2);\n    _1079 = param_2.albedo;\n    _1080 = param_2.alpha;\n    _1081 = param_2.normal;\n    _1082 = param_2.metallic;\n    _1083 = param_2.roughness;\n    _1084 = param_2.occlusion;\n    _1085 = param_2.emission;\n    if (param_2.alpha < _705_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_225_fa_emissive.w > 0.5f)\n    {\n        result = _1079;\n    }\n    else\n    {\n        float3 _727 = normalize(_1081);\n        float _734 = clamp(_1082, 0.0f, 1.0f);\n        float _738 = clamp(_1083, 0.0500000007450580596923828125f, 1.0f);\n        float _742 = _738 * _738;\n        float _746 = _742 * _742;\n        float _752 = max(dot(_727, _689), 9.9999997473787516355514526367188e-05f);\n        float3 _758 = _1079 * (1.0f - _734);\n        float3 _766 = lerp(0.039999999105930328369140625f.xxx, _1079, _734.xxx);\n        float3 lit = (_225_fa_ambient.xyz * _758) * _1084;\n        int _779 = int(_225_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _779)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _808 = _802_fa_light_color[li].w < 0.5f;\n            if (_808)\n            {\n                l = normalize(_802_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _825 = _802_fa_light_pos[li].xyz - fa_world_pos;\n                float _828 = length(_825);\n                l = _825 / max(_828, 9.9999997473787516355514526367188e-05f).xxx;\n                float _843 = _828 / max(_802_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _849 = clamp(1.0f - (_843 * _843), 0.0f, 1.0f);\n                atten = _849 * _849;\n                if (_802_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_802_fa_light_dir[li].w, lerp(_802_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_802_fa_light_dir[li].xyz)));\n                }\n            }\n            float _882 = max(dot(_727, l), 0.0f);\n            if (_808 && (li == 0))\n            {\n                float3 param_3 = _1057;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            float3 _901 = normalize(l + _689);\n            float _906 = max(dot(_727, _901), 0.0f);\n            float _919 = ((_906 * _906) * (_746 - 1.0f)) + 1.0f;\n            lit += (((_758 + (((_766 + ((1.0f.xxx - _766) * pow(1.0f - max(dot(_689, _901), 0.0f), 5.0f))) * (((_746 / ((3.1415927410125732421875f * _919) * _919)) * (0.5f / max(lerp((2.0f * _882) * _752, _882 + _752, _742), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _882))) * _802_fa_light_color[li].xyz) * (_882 * atten));\n        }\n        float param_5 = _738;\n        float param_6 = _752;\n        float2 _987 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_689, _727);\n        float param_8 = _738;\n        float3 _1005 = lit;\n        float3 _1006 = _1005 + ((fa_environment(param_7, param_8) * ((_766 * _987.x) + _987.y.xxx)) * _1084);\n        lit = _1006;\n        result = _1006;\n    }\n    result += _1085;\n    if (_225_fa_fog.w > 0.0f)\n    {\n        float _1030 = _225_fa_fog.w * length(_688);\n        result = lerp(result, _225_fa_fog.xyz, clamp(1.0f - exp((-_1030) * _1030), 0.0f, 1.0f).xxx);\n    }\n    fa_frag_color = float4(result, _1080);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_705",
            "hlsl_register_b_n": 5
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_802",
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
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _120_fa_view_proj : packoffset(c0);\n    row_major float4x4 _120_fa_light_vp : packoffset(c4);\n    float4 _120_fa_uv_scale : packoffset(c8);\n    float4 _120_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _58 = cross(model[1].xyz, model[2].xyz);\n    float _64 = (dot(model[0].xyz, _58) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _247 = { mul(float4(position, 1.0f), model).xyz, (((_58 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _64, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _64), texcoord0 * _120_fa_uv_scale.xy, color, position };\n    return _247;\n}\n\nvoid vert_main()\n{\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData _187 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _230 = _187.world_pos;\n    fa_world_pos = _230;\n    fa_world_normal = _187.world_normal;\n    fa_world_tangent = _187.world_tangent;\n    fa_uv = _187.uv;\n    fa_vertex_color = _187.color;\n    gl_Position = mul(float4(_230, 1.0f), _120_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _211_fa_camera_pos : packoffset(c0);\n    float4 _211_fa_ambient : packoffset(c1);\n    float4 _211_fa_base_color : packoffset(c2);\n    float4 _211_fa_emissive : packoffset(c3);\n    float4 _211_fa_model_emissive : packoffset(c4);\n    float4 _211_fa_pbr : packoffset(c5);\n    float4 _211_fa_maps : packoffset(c6);\n    float4 _211_fa_fog : packoffset(c7);\n    float4 _211_fa_counts : packoffset(c8);\n    float4 _211_fa_env_sky : packoffset(c9);\n    float4 _211_fa_env_horizon : packoffset(c10);\n    float4 _211_fa_time : packoffset(c11);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _440_alphaCutoff : packoffset(c0);\n    float _440_fa_pad0 : packoffset(c0.y);\n    float _440_fa_pad1 : packoffset(c0.z);\n    float _440_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _170 = fa_linear_to_srgb(param);\n        c = _170;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _179 = fa_srgb_to_linear(param_1);\n            c = _179;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _54;\n    if (i.front_facing)\n    {\n        _54 = i.world_normal;\n    }\n    else\n    {\n        _54 = -i.world_normal;\n    }\n    float3 _79 = normalize(i.world_tangent.xyz - (_54 * dot(_54, i.world_tangent.xyz)));\n    float3 _107 = normalize(((_79 * m.x) + ((cross(_54, _79) * i.world_tangent.w) * m.y)) + (_54 * m.z));\n    float3 _110;\n    if (i.front_facing)\n    {\n        _110 = _107;\n    }\n    else\n    {\n        _110 = -_107;\n    }\n    return _110;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _211_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _223 = fa_tex_fix(param_2, param_3);\n    float4 _523 = base_t;\n    _523.x = _223.x;\n    _523.y = _223.y;\n    _523.z = _223.z;\n    base_t = _523;\n    float4 _239 = (_523 * _211_fa_base_color) * i.vertex_color;\n    float3 _510 = i.world_normal;\n    if (_211_fa_maps.z > 0.5f)\n    {\n        float param_4 = _211_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _273 = fa_tex_fix(param_6, param_7);\n        float3 _277 = (_273 * 2.0f) - 1.0f.xxx;\n        float2 _282 = _277.xy * _211_fa_maps.x;\n        float3 _531 = _277;\n        _531.x = _282.x;\n        _531.y = _282.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _531;\n        _510 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _211_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _311 = fa_tex_fix(param_12, param_13);\n    float4 _534 = mrt;\n    _534.x = _311.x;\n    _534.y = _311.y;\n    _534.z = _311.z;\n    mrt = _534;\n    float param_14 = _211_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _352 = fa_tex_fix(param_16, param_17);\n    float param_18 = _211_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _379 = fa_tex_fix(param_20, param_21);\n    Surface _522 = { _239.xyz, _239.w, _510, clamp(_211_fa_pbr.x * _311.z, 0.0f, 1.0f), clamp(_211_fa_pbr.y * _311.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_211_fa_maps.y * (_352.x - 1.0f)), _211_fa_emissive.xyz + (_211_fa_model_emissive.xyz * _379) };\n    return _522;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    float3 _457 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _457 = -_457;\n    }\n    float3 _424 = normalize(_211_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _470 = { fa_world_pos, _457, fa_world_tangent, fa_uv, fa_vertex_color, _424, gl_FrontFacing };\n    SurfaceInput param = _470;\n    SurfaceInput _478 = { fa_world_pos, _457, fa_world_tangent, fa_uv, fa_vertex_color, _424, gl_FrontFacing };\n    SurfaceInput param_1 = _478;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _440_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec2",
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
            "inst_name": "_120",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_211",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_440",
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
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _125_fa_view_proj : packoffset(c0);\n    row_major float4x4 _125_fa_light_vp : packoffset(c4);\n    float4 _125_fa_uv_scale : packoffset(c8);\n    float4 _125_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _172_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _163 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_172_fa_joint_rows[_163] * weights[i]);\n        r1 += (_172_fa_joint_rows[_163 + 1] * weights[i]);\n        r2 += (_172_fa_joint_rows[_163 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _63 = cross(model[1].xyz, model[2].xyz);\n    float _69 = (dot(model[0].xyz, _63) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _368 = { mul(float4(position, 1.0f), model).xyz, (((_63 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _69, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _69), texcoord0 * _125_fa_uv_scale.xy, color, position };\n    return _368;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData _308 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    float3 _351 = _308.world_pos;\n    fa_world_pos = _351;\n    fa_world_normal = _308.world_normal;\n    fa_world_tangent = _308.world_tangent;\n    fa_uv = _308.uv;\n    fa_vertex_color = _308.color;\n    gl_Position = mul(float4(_351, 1.0f), _125_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _211_fa_camera_pos : packoffset(c0);\n    float4 _211_fa_ambient : packoffset(c1);\n    float4 _211_fa_base_color : packoffset(c2);\n    float4 _211_fa_emissive : packoffset(c3);\n    float4 _211_fa_model_emissive : packoffset(c4);\n    float4 _211_fa_pbr : packoffset(c5);\n    float4 _211_fa_maps : packoffset(c6);\n    float4 _211_fa_fog : packoffset(c7);\n    float4 _211_fa_counts : packoffset(c8);\n    float4 _211_fa_env_sky : packoffset(c9);\n    float4 _211_fa_env_horizon : packoffset(c10);\n    float4 _211_fa_time : packoffset(c11);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _440_alphaCutoff : packoffset(c0);\n    float _440_fa_pad0 : packoffset(c0.y);\n    float _440_fa_pad1 : packoffset(c0.z);\n    float _440_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _170 = fa_linear_to_srgb(param);\n        c = _170;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _179 = fa_srgb_to_linear(param_1);\n            c = _179;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _54;\n    if (i.front_facing)\n    {\n        _54 = i.world_normal;\n    }\n    else\n    {\n        _54 = -i.world_normal;\n    }\n    float3 _79 = normalize(i.world_tangent.xyz - (_54 * dot(_54, i.world_tangent.xyz)));\n    float3 _107 = normalize(((_79 * m.x) + ((cross(_54, _79) * i.world_tangent.w) * m.y)) + (_54 * m.z));\n    float3 _110;\n    if (i.front_facing)\n    {\n        _110 = _107;\n    }\n    else\n    {\n        _110 = -_107;\n    }\n    return _110;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _211_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _223 = fa_tex_fix(param_2, param_3);\n    float4 _523 = base_t;\n    _523.x = _223.x;\n    _523.y = _223.y;\n    _523.z = _223.z;\n    base_t = _523;\n    float4 _239 = (_523 * _211_fa_base_color) * i.vertex_color;\n    float3 _510 = i.world_normal;\n    if (_211_fa_maps.z > 0.5f)\n    {\n        float param_4 = _211_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _273 = fa_tex_fix(param_6, param_7);\n        float3 _277 = (_273 * 2.0f) - 1.0f.xxx;\n        float2 _282 = _277.xy * _211_fa_maps.x;\n        float3 _531 = _277;\n        _531.x = _282.x;\n        _531.y = _282.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _531;\n        _510 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _211_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _311 = fa_tex_fix(param_12, param_13);\n    float4 _534 = mrt;\n    _534.x = _311.x;\n    _534.y = _311.y;\n    _534.z = _311.z;\n    mrt = _534;\n    float param_14 = _211_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _352 = fa_tex_fix(param_16, param_17);\n    float param_18 = _211_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _379 = fa_tex_fix(param_20, param_21);\n    Surface _522 = { _239.xyz, _239.w, _510, clamp(_211_fa_pbr.x * _311.z, 0.0f, 1.0f), clamp(_211_fa_pbr.y * _311.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_211_fa_maps.y * (_352.x - 1.0f)), _211_fa_emissive.xyz + (_211_fa_model_emissive.xyz * _379) };\n    return _522;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    float3 _457 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _457 = -_457;\n    }\n    float3 _424 = normalize(_211_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _470 = { fa_world_pos, _457, fa_world_tangent, fa_uv, fa_vertex_color, _424, gl_FrontFacing };\n    SurfaceInput param = _470;\n    SurfaceInput _478 = { fa_world_pos, _457, fa_world_tangent, fa_uv, fa_vertex_color, _424, gl_FrontFacing };\n    SurfaceInput param_1 = _478;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _440_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec2",
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
            "inst_name": "_125",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_172",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_211",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_440",
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
