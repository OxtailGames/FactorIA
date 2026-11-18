{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "5dd0da916b10a9a6f999383491342fc1c21819329ed9afcc0f9d0e7d6522a261",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _129_fa_view_proj : packoffset(c0);\n    row_major float4x4 _129_fa_light_vp : packoffset(c4);\n    float4 _129_fa_uv_scale : packoffset(c8);\n    float4 _129_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * _129_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _158.world_pos;\n    float4 _165 = float4(_267, 1.0f);\n    fa_world_pos = _267;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_shadow_pos = mul(_165, _129_fa_light_vp);\n    gl_Position = mul(_165, _129_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _225_fa_camera_pos : packoffset(c0);\n    float4 _225_fa_ambient : packoffset(c1);\n    float4 _225_fa_base_color : packoffset(c2);\n    float4 _225_fa_emissive : packoffset(c3);\n    float4 _225_fa_model_emissive : packoffset(c4);\n    float4 _225_fa_pbr : packoffset(c5);\n    float4 _225_fa_maps : packoffset(c6);\n    float4 _225_fa_fog : packoffset(c7);\n    float4 _225_fa_fog_b : packoffset(c8);\n    float4 _225_fa_fog_c : packoffset(c9);\n    float4 _225_fa_counts : packoffset(c10);\n    float4 _225_fa_env_sky : packoffset(c11);\n    float4 _225_fa_env_horizon : packoffset(c12);\n    float4 _225_fa_time : packoffset(c13);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _791_fa_light_pos[32] : packoffset(c0);\n    float4 _791_fa_light_color[32] : packoffset(c32);\n    float4 _791_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _184 = fa_linear_to_srgb(param);\n        c = _184;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _193 = fa_srgb_to_linear(param_1);\n            c = _193;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _68;\n    if (i.front_facing)\n    {\n        _68 = i.world_normal;\n    }\n    else\n    {\n        _68 = -i.world_normal;\n    }\n    float3 _93 = normalize(i.world_tangent.xyz - (_68 * dot(_68, i.world_tangent.xyz)));\n    float3 _121 = normalize(((_93 * m.x) + ((cross(_68, _93) * i.world_tangent.w) * m.y)) + (_68 * m.z));\n    float3 _124;\n    if (i.front_facing)\n    {\n        _124 = _121;\n    }\n    else\n    {\n        _124 = -_121;\n    }\n    return _124;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _225_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _1317 = base_t;\n    _1317.x = _237.x;\n    _1317.y = _237.y;\n    _1317.z = _237.z;\n    base_t = _1317;\n    float4 _253 = (_1317 * _225_fa_base_color) * i.vertex_color;\n    float3 _1301 = i.world_normal;\n    if (_225_fa_maps.z > 0.5f)\n    {\n        float param_4 = _225_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _291 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _296 = _291.xy * _225_fa_maps.x;\n        float3 _1325 = _291;\n        _1325.x = _296.x;\n        _1325.y = _296.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1325;\n        _1301 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _225_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _325 = fa_tex_fix(param_12, param_13);\n    float4 _1328 = mrt;\n    _1328.x = _325.x;\n    _1328.y = _325.y;\n    _1328.z = _325.z;\n    mrt = _1328;\n    float param_14 = _225_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _393 = fa_tex_fix(param_20, param_21);\n    Surface _1313 = { _253.xyz, _253.w, _1301, clamp(_225_fa_pbr.x * _325.z, 0.0f, 1.0f), clamp(_225_fa_pbr.y * _325.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_225_fa_maps.y * (_366.x - 1.0f)), _225_fa_emissive.xyz + (_225_fa_model_emissive.xyz * _393) };\n    return _1313;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_225_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _415 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _415;\n    float2 suv = (_415.xy * 0.5f) + 0.5f.xx;\n    if (_225_fa_counts.z > 0.5f)\n    {\n        float3 _1336 = p;\n        _1336.z = (_1336.z * 0.5f) + 0.5f;\n        p = _1336;\n    }\n    else\n    {\n        float2 _1339 = suv;\n        _1339.y = 1.0f - _1339.y;\n        suv = _1339;\n    }\n    bool _442 = suv.x < 0.0f;\n    bool _449;\n    if (!_442)\n    {\n        _449 = suv.x > 1.0f;\n    }\n    else\n    {\n        _449 = _442;\n    }\n    bool _456;\n    if (!_449)\n    {\n        _456 = suv.y < 0.0f;\n    }\n    else\n    {\n        _456 = _449;\n    }\n    bool _463;\n    if (!_456)\n    {\n        _463 = suv.y > 1.0f;\n    }\n    else\n    {\n        _463 = _456;\n    }\n    bool _470;\n    if (!_463)\n    {\n        _470 = p.z > 1.0f;\n    }\n    else\n    {\n        _470 = _463;\n    }\n    if (_470)\n    {\n        return 1.0f;\n    }\n    float _484 = _225_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _484) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _225_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _625 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _628 = _625.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_628 * _628, exp2((-9.27999973297119140625f) * ndv)) * _628) + _625.y)) + _625.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _545 = rough * rough;\n    float _578 = 0.60000002384185791015625f * _545;\n    return lerp(lerp(_225_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_225_fa_env_horizon.xyz, _225_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _545)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _578, 0.0500000007450580596923828125f + _578, d.y).xxx), ((_225_fa_env_sky.xyz + _225_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_545 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    float3 _1247 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1247 = -_1247;\n    }\n    float3 _689 = normalize(_225_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _1260 = { fa_world_pos, _1247, fa_world_tangent, fa_uv, fa_vertex_color, _689, gl_FrontFacing };\n    SurfaceInput param = _1260;\n    Surface _694 = fa_standard_surface(param);\n    float3 _1270 = _694.albedo;\n    float _1271 = _694.alpha;\n    float3 _1272 = _694.normal;\n    float _1273 = _694.metallic;\n    float _1274 = _694.roughness;\n    float _1275 = _694.occlusion;\n    float3 _1276 = _694.emission;\n    SurfaceInput _1268 = { fa_world_pos, _1247, fa_world_tangent, fa_uv, fa_vertex_color, _689, gl_FrontFacing };\n    SurfaceInput param_1 = _1268;\n    Surface param_2 = _694;\n    surface(param_1, param_2);\n    _1270 = param_2.albedo;\n    _1271 = param_2.alpha;\n    _1272 = param_2.normal;\n    _1273 = param_2.metallic;\n    _1274 = param_2.roughness;\n    _1275 = param_2.occlusion;\n    _1276 = param_2.emission;\n    float3 result;\n    if (_225_fa_emissive.w > 0.5f)\n    {\n        result = _1270;\n    }\n    else\n    {\n        float3 _716 = normalize(_1272);\n        float _723 = clamp(_1273, 0.0f, 1.0f);\n        float _727 = clamp(_1274, 0.0500000007450580596923828125f, 1.0f);\n        float _731 = _727 * _727;\n        float _735 = _731 * _731;\n        float _741 = max(dot(_716, _689), 9.9999997473787516355514526367188e-05f);\n        float3 _747 = _1270 * (1.0f - _723);\n        float3 _755 = lerp(0.039999999105930328369140625f.xxx, _1270, _723.xxx);\n        float3 lit = (_225_fa_ambient.xyz * _747) * _1275;\n        int _768 = int(_225_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _768)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _798 = _791_fa_light_color[li].w < 0.5f;\n            if (_798)\n            {\n                l = normalize(_791_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _815 = _791_fa_light_pos[li].xyz - fa_world_pos;\n                float _817 = length(_815);\n                l = _815 / max(_817, 9.9999997473787516355514526367188e-05f).xxx;\n                float _832 = _817 / max(_791_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _838 = clamp(1.0f - (_832 * _832), 0.0f, 1.0f);\n                atten = _838 * _838;\n                if (_791_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_791_fa_light_dir[li].w, lerp(_791_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_791_fa_light_dir[li].xyz)));\n                }\n            }\n            float shadow = 1.0f;\n            if (_798 && (li == 0))\n            {\n                float3 param_3 = _1247;\n                float3 param_4 = l;\n                shadow = fa_shadow_factor(param_3, param_4);\n            }\n            float _884 = max(dot(_716, l), 0.0f);\n            float _886 = atten;\n            float _887 = _886 * shadow;\n            atten = _887;\n            float3 _892 = normalize(l + _689);\n            float _897 = max(dot(_716, _892), 0.0f);\n            float _910 = ((_897 * _897) * (_735 - 1.0f)) + 1.0f;\n            lit += (((_747 + (((_755 + ((1.0f.xxx - _755) * pow(1.0f - max(dot(_689, _892), 0.0f), 5.0f))) * (((_735 / ((3.1415927410125732421875f * _910) * _910)) * (0.5f / max(lerp((2.0f * _884) * _741, _884 + _741, _731), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _884))) * _791_fa_light_color[li].xyz) * (_884 * _887));\n        }\n        float param_5 = _727;\n        float param_6 = _741;\n        float2 _978 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_689, _716);\n        float param_8 = _727;\n        float3 _996 = lit;\n        float3 _997 = _996 + ((fa_environment(param_7, param_8) * ((_755 * _978.x) + _978.y.xxx)) * _1275);\n        lit = _997;\n        result = _997;\n    }\n    result += _1276;\n    bool _1006 = _225_fa_fog.w > 0.0f;\n    bool _1014;\n    if (!_1006)\n    {\n        _1014 = _225_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1014 = _1006;\n    }\n    if (_1014)\n    {\n        float3 _1023 = fa_world_pos - _225_fa_camera_pos.xyz;\n        float _1030 = dot(_1023, _225_fa_fog_c.xyz);\n        bool _1034 = _225_fa_fog_c.w > 0.5f;\n        float _1035;\n        if (_1034)\n        {\n            _1035 = _1030;\n        }\n        else\n        {\n            _1035 = length(_1023);\n        }\n        float _1047 = _1035 - _225_fa_fog_b.x;\n        if (_1047 > 0.0f)\n        {\n            float _1056 = _225_fa_fog.w * _1047;\n            float tau = _1056 * _1056;\n            if (_225_fa_fog_b.y > 0.0f)\n            {\n                float _1072;\n                if (_1034)\n                {\n                    _1072 = fa_world_pos.y - (_225_fa_fog_c.y * _1030);\n                }\n                else\n                {\n                    _1072 = _225_fa_camera_pos.y;\n                }\n                float _1093 = lerp(_1072, fa_world_pos.y, clamp(_225_fa_fog_b.x / _1035, 0.0f, 1.0f));\n                float _1097 = fa_world_pos.y - _1093;\n                float _1102 = _1093 - _225_fa_fog_b.z;\n                float _1107 = fa_world_pos.y - _225_fa_fog_b.z;\n                bool _1110 = _1102 <= 0.0f;\n                bool _1111 = !_1110;\n                bool _1117;\n                if (_1111)\n                {\n                    _1117 = _225_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1117 = _1110;\n                }\n                float _1118;\n                if (_1117)\n                {\n                    _1118 = _225_fa_fog_b.y;\n                }\n                else\n                {\n                    _1118 = _225_fa_fog_b.y * exp(-min(_225_fa_fog_b.w * _1102, 80.0f));\n                }\n                bool _1145;\n                if (_1111)\n                {\n                    _1145 = _225_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1145 = _1110;\n                }\n                float _1146;\n                if (_1145)\n                {\n                    _1146 = _225_fa_fog_b.y * _1102;\n                }\n                else\n                {\n                    _1146 = (_225_fa_fog_b.y * (1.0f - exp(-min(_225_fa_fog_b.w * _1102, 80.0f)))) / _225_fa_fog_b.w;\n                }\n                bool _1171 = _1107 <= 0.0f;\n                bool _1178;\n                if (!_1171)\n                {\n                    _1178 = _225_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1178 = _1171;\n                }\n                float _1179;\n                if (_1178)\n                {\n                    _1179 = _225_fa_fog_b.y * _1107;\n                }\n                else\n                {\n                    _1179 = (_225_fa_fog_b.y * (1.0f - exp(-min(_225_fa_fog_b.w * _1107, 80.0f)))) / _225_fa_fog_b.w;\n                }\n                float _1206;\n                if (abs(_1097) < 0.001000000047497451305389404296875f)\n                {\n                    _1206 = _1118;\n                }\n                else\n                {\n                    _1206 = (_1179 - _1146) / _1097;\n                }\n                tau += (_1047 * max(_1206, 0.0f));\n            }\n            result = lerp(result, _225_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1271);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_791",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _134_fa_view_proj : packoffset(c0);\n    row_major float4x4 _134_fa_light_vp : packoffset(c4);\n    float4 _134_fa_uv_scale : packoffset(c8);\n    float4 _134_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _181_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _172 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_181_fa_joint_rows[_172] * weights[i]);\n        r1 += (_181_fa_joint_rows[_172 + 1] * weights[i]);\n        r2 += (_181_fa_joint_rows[_172 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * _134_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _271 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _271.world_pos;\n    float4 _278 = float4(_388, 1.0f);\n    fa_world_pos = _388;\n    fa_world_normal = _271.world_normal;\n    fa_world_tangent = _271.world_tangent;\n    fa_uv = _271.uv;\n    fa_vertex_color = _271.color;\n    fa_shadow_pos = mul(_278, _134_fa_light_vp);\n    gl_Position = mul(_278, _134_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _225_fa_camera_pos : packoffset(c0);\n    float4 _225_fa_ambient : packoffset(c1);\n    float4 _225_fa_base_color : packoffset(c2);\n    float4 _225_fa_emissive : packoffset(c3);\n    float4 _225_fa_model_emissive : packoffset(c4);\n    float4 _225_fa_pbr : packoffset(c5);\n    float4 _225_fa_maps : packoffset(c6);\n    float4 _225_fa_fog : packoffset(c7);\n    float4 _225_fa_fog_b : packoffset(c8);\n    float4 _225_fa_fog_c : packoffset(c9);\n    float4 _225_fa_counts : packoffset(c10);\n    float4 _225_fa_env_sky : packoffset(c11);\n    float4 _225_fa_env_horizon : packoffset(c12);\n    float4 _225_fa_time : packoffset(c13);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _791_fa_light_pos[32] : packoffset(c0);\n    float4 _791_fa_light_color[32] : packoffset(c32);\n    float4 _791_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _184 = fa_linear_to_srgb(param);\n        c = _184;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _193 = fa_srgb_to_linear(param_1);\n            c = _193;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _68;\n    if (i.front_facing)\n    {\n        _68 = i.world_normal;\n    }\n    else\n    {\n        _68 = -i.world_normal;\n    }\n    float3 _93 = normalize(i.world_tangent.xyz - (_68 * dot(_68, i.world_tangent.xyz)));\n    float3 _121 = normalize(((_93 * m.x) + ((cross(_68, _93) * i.world_tangent.w) * m.y)) + (_68 * m.z));\n    float3 _124;\n    if (i.front_facing)\n    {\n        _124 = _121;\n    }\n    else\n    {\n        _124 = -_121;\n    }\n    return _124;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _225_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _1317 = base_t;\n    _1317.x = _237.x;\n    _1317.y = _237.y;\n    _1317.z = _237.z;\n    base_t = _1317;\n    float4 _253 = (_1317 * _225_fa_base_color) * i.vertex_color;\n    float3 _1301 = i.world_normal;\n    if (_225_fa_maps.z > 0.5f)\n    {\n        float param_4 = _225_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _291 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _296 = _291.xy * _225_fa_maps.x;\n        float3 _1325 = _291;\n        _1325.x = _296.x;\n        _1325.y = _296.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1325;\n        _1301 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _225_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _325 = fa_tex_fix(param_12, param_13);\n    float4 _1328 = mrt;\n    _1328.x = _325.x;\n    _1328.y = _325.y;\n    _1328.z = _325.z;\n    mrt = _1328;\n    float param_14 = _225_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _393 = fa_tex_fix(param_20, param_21);\n    Surface _1313 = { _253.xyz, _253.w, _1301, clamp(_225_fa_pbr.x * _325.z, 0.0f, 1.0f), clamp(_225_fa_pbr.y * _325.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_225_fa_maps.y * (_366.x - 1.0f)), _225_fa_emissive.xyz + (_225_fa_model_emissive.xyz * _393) };\n    return _1313;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_225_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _415 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _415;\n    float2 suv = (_415.xy * 0.5f) + 0.5f.xx;\n    if (_225_fa_counts.z > 0.5f)\n    {\n        float3 _1336 = p;\n        _1336.z = (_1336.z * 0.5f) + 0.5f;\n        p = _1336;\n    }\n    else\n    {\n        float2 _1339 = suv;\n        _1339.y = 1.0f - _1339.y;\n        suv = _1339;\n    }\n    bool _442 = suv.x < 0.0f;\n    bool _449;\n    if (!_442)\n    {\n        _449 = suv.x > 1.0f;\n    }\n    else\n    {\n        _449 = _442;\n    }\n    bool _456;\n    if (!_449)\n    {\n        _456 = suv.y < 0.0f;\n    }\n    else\n    {\n        _456 = _449;\n    }\n    bool _463;\n    if (!_456)\n    {\n        _463 = suv.y > 1.0f;\n    }\n    else\n    {\n        _463 = _456;\n    }\n    bool _470;\n    if (!_463)\n    {\n        _470 = p.z > 1.0f;\n    }\n    else\n    {\n        _470 = _463;\n    }\n    if (_470)\n    {\n        return 1.0f;\n    }\n    float _484 = _225_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _484) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _225_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _625 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _628 = _625.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_628 * _628, exp2((-9.27999973297119140625f) * ndv)) * _628) + _625.y)) + _625.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _545 = rough * rough;\n    float _578 = 0.60000002384185791015625f * _545;\n    return lerp(lerp(_225_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_225_fa_env_horizon.xyz, _225_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _545)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _578, 0.0500000007450580596923828125f + _578, d.y).xxx), ((_225_fa_env_sky.xyz + _225_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_545 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    float3 _1247 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1247 = -_1247;\n    }\n    float3 _689 = normalize(_225_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _1260 = { fa_world_pos, _1247, fa_world_tangent, fa_uv, fa_vertex_color, _689, gl_FrontFacing };\n    SurfaceInput param = _1260;\n    Surface _694 = fa_standard_surface(param);\n    float3 _1270 = _694.albedo;\n    float _1271 = _694.alpha;\n    float3 _1272 = _694.normal;\n    float _1273 = _694.metallic;\n    float _1274 = _694.roughness;\n    float _1275 = _694.occlusion;\n    float3 _1276 = _694.emission;\n    SurfaceInput _1268 = { fa_world_pos, _1247, fa_world_tangent, fa_uv, fa_vertex_color, _689, gl_FrontFacing };\n    SurfaceInput param_1 = _1268;\n    Surface param_2 = _694;\n    surface(param_1, param_2);\n    _1270 = param_2.albedo;\n    _1271 = param_2.alpha;\n    _1272 = param_2.normal;\n    _1273 = param_2.metallic;\n    _1274 = param_2.roughness;\n    _1275 = param_2.occlusion;\n    _1276 = param_2.emission;\n    float3 result;\n    if (_225_fa_emissive.w > 0.5f)\n    {\n        result = _1270;\n    }\n    else\n    {\n        float3 _716 = normalize(_1272);\n        float _723 = clamp(_1273, 0.0f, 1.0f);\n        float _727 = clamp(_1274, 0.0500000007450580596923828125f, 1.0f);\n        float _731 = _727 * _727;\n        float _735 = _731 * _731;\n        float _741 = max(dot(_716, _689), 9.9999997473787516355514526367188e-05f);\n        float3 _747 = _1270 * (1.0f - _723);\n        float3 _755 = lerp(0.039999999105930328369140625f.xxx, _1270, _723.xxx);\n        float3 lit = (_225_fa_ambient.xyz * _747) * _1275;\n        int _768 = int(_225_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _768)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _798 = _791_fa_light_color[li].w < 0.5f;\n            if (_798)\n            {\n                l = normalize(_791_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _815 = _791_fa_light_pos[li].xyz - fa_world_pos;\n                float _817 = length(_815);\n                l = _815 / max(_817, 9.9999997473787516355514526367188e-05f).xxx;\n                float _832 = _817 / max(_791_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _838 = clamp(1.0f - (_832 * _832), 0.0f, 1.0f);\n                atten = _838 * _838;\n                if (_791_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_791_fa_light_dir[li].w, lerp(_791_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_791_fa_light_dir[li].xyz)));\n                }\n            }\n            float shadow = 1.0f;\n            if (_798 && (li == 0))\n            {\n                float3 param_3 = _1247;\n                float3 param_4 = l;\n                shadow = fa_shadow_factor(param_3, param_4);\n            }\n            float _884 = max(dot(_716, l), 0.0f);\n            float _886 = atten;\n            float _887 = _886 * shadow;\n            atten = _887;\n            float3 _892 = normalize(l + _689);\n            float _897 = max(dot(_716, _892), 0.0f);\n            float _910 = ((_897 * _897) * (_735 - 1.0f)) + 1.0f;\n            lit += (((_747 + (((_755 + ((1.0f.xxx - _755) * pow(1.0f - max(dot(_689, _892), 0.0f), 5.0f))) * (((_735 / ((3.1415927410125732421875f * _910) * _910)) * (0.5f / max(lerp((2.0f * _884) * _741, _884 + _741, _731), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _884))) * _791_fa_light_color[li].xyz) * (_884 * _887));\n        }\n        float param_5 = _727;\n        float param_6 = _741;\n        float2 _978 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_689, _716);\n        float param_8 = _727;\n        float3 _996 = lit;\n        float3 _997 = _996 + ((fa_environment(param_7, param_8) * ((_755 * _978.x) + _978.y.xxx)) * _1275);\n        lit = _997;\n        result = _997;\n    }\n    result += _1276;\n    bool _1006 = _225_fa_fog.w > 0.0f;\n    bool _1014;\n    if (!_1006)\n    {\n        _1014 = _225_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1014 = _1006;\n    }\n    if (_1014)\n    {\n        float3 _1023 = fa_world_pos - _225_fa_camera_pos.xyz;\n        float _1030 = dot(_1023, _225_fa_fog_c.xyz);\n        bool _1034 = _225_fa_fog_c.w > 0.5f;\n        float _1035;\n        if (_1034)\n        {\n            _1035 = _1030;\n        }\n        else\n        {\n            _1035 = length(_1023);\n        }\n        float _1047 = _1035 - _225_fa_fog_b.x;\n        if (_1047 > 0.0f)\n        {\n            float _1056 = _225_fa_fog.w * _1047;\n            float tau = _1056 * _1056;\n            if (_225_fa_fog_b.y > 0.0f)\n            {\n                float _1072;\n                if (_1034)\n                {\n                    _1072 = fa_world_pos.y - (_225_fa_fog_c.y * _1030);\n                }\n                else\n                {\n                    _1072 = _225_fa_camera_pos.y;\n                }\n                float _1093 = lerp(_1072, fa_world_pos.y, clamp(_225_fa_fog_b.x / _1035, 0.0f, 1.0f));\n                float _1097 = fa_world_pos.y - _1093;\n                float _1102 = _1093 - _225_fa_fog_b.z;\n                float _1107 = fa_world_pos.y - _225_fa_fog_b.z;\n                bool _1110 = _1102 <= 0.0f;\n                bool _1111 = !_1110;\n                bool _1117;\n                if (_1111)\n                {\n                    _1117 = _225_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1117 = _1110;\n                }\n                float _1118;\n                if (_1117)\n                {\n                    _1118 = _225_fa_fog_b.y;\n                }\n                else\n                {\n                    _1118 = _225_fa_fog_b.y * exp(-min(_225_fa_fog_b.w * _1102, 80.0f));\n                }\n                bool _1145;\n                if (_1111)\n                {\n                    _1145 = _225_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1145 = _1110;\n                }\n                float _1146;\n                if (_1145)\n                {\n                    _1146 = _225_fa_fog_b.y * _1102;\n                }\n                else\n                {\n                    _1146 = (_225_fa_fog_b.y * (1.0f - exp(-min(_225_fa_fog_b.w * _1102, 80.0f)))) / _225_fa_fog_b.w;\n                }\n                bool _1171 = _1107 <= 0.0f;\n                bool _1178;\n                if (!_1171)\n                {\n                    _1178 = _225_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1178 = _1171;\n                }\n                float _1179;\n                if (_1178)\n                {\n                    _1179 = _225_fa_fog_b.y * _1107;\n                }\n                else\n                {\n                    _1179 = (_225_fa_fog_b.y * (1.0f - exp(-min(_225_fa_fog_b.w * _1107, 80.0f)))) / _225_fa_fog_b.w;\n                }\n                float _1206;\n                if (abs(_1097) < 0.001000000047497451305389404296875f)\n                {\n                    _1206 = _1118;\n                }\n                else\n                {\n                    _1206 = (_1179 - _1146) / _1097;\n                }\n                tau += (_1047 * max(_1206, 0.0f));\n            }\n            result = lerp(result, _225_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1271);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_791",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _129_fa_view_proj : packoffset(c0);\n    row_major float4x4 _129_fa_light_vp : packoffset(c4);\n    float4 _129_fa_uv_scale : packoffset(c8);\n    float4 _129_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _289 = { mul(float4(position, 1.0f), model).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * _129_fa_uv_scale.xy, color, position };\n    return _289;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _296 = _158.world_pos;\n    float4 _169 = float4(_296, 1.0f);\n    fa_world_pos = _296;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_pre_depth = -mul(_169, _129_fa_light_vp).z;\n    fa_pre_r0 = float3(_129_fa_light_vp[0].x, _129_fa_light_vp[1].x, _129_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_129_fa_light_vp[0].y, _129_fa_light_vp[1].y, _129_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_129_fa_light_vp[0].z, _129_fa_light_vp[1].z, _129_fa_light_vp[2].z);\n    gl_Position = mul(_169, _129_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _211_fa_camera_pos : packoffset(c0);\n    float4 _211_fa_ambient : packoffset(c1);\n    float4 _211_fa_base_color : packoffset(c2);\n    float4 _211_fa_emissive : packoffset(c3);\n    float4 _211_fa_model_emissive : packoffset(c4);\n    float4 _211_fa_pbr : packoffset(c5);\n    float4 _211_fa_maps : packoffset(c6);\n    float4 _211_fa_fog : packoffset(c7);\n    float4 _211_fa_fog_b : packoffset(c8);\n    float4 _211_fa_fog_c : packoffset(c9);\n    float4 _211_fa_counts : packoffset(c10);\n    float4 _211_fa_env_sky : packoffset(c11);\n    float4 _211_fa_env_horizon : packoffset(c12);\n    float4 _211_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _170 = fa_linear_to_srgb(param);\n        c = _170;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _179 = fa_srgb_to_linear(param_1);\n            c = _179;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _54;\n    if (i.front_facing)\n    {\n        _54 = i.world_normal;\n    }\n    else\n    {\n        _54 = -i.world_normal;\n    }\n    float3 _79 = normalize(i.world_tangent.xyz - (_54 * dot(_54, i.world_tangent.xyz)));\n    float3 _107 = normalize(((_79 * m.x) + ((cross(_54, _79) * i.world_tangent.w) * m.y)) + (_54 * m.z));\n    float3 _110;\n    if (i.front_facing)\n    {\n        _110 = _107;\n    }\n    else\n    {\n        _110 = -_107;\n    }\n    return _110;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _211_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _223 = fa_tex_fix(param_2, param_3);\n    float4 _578 = base_t;\n    _578.x = _223.x;\n    _578.y = _223.y;\n    _578.z = _223.z;\n    base_t = _578;\n    float4 _239 = (_578 * _211_fa_base_color) * i.vertex_color;\n    float3 _559 = i.world_normal;\n    if (_211_fa_maps.z > 0.5f)\n    {\n        float param_4 = _211_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _273 = fa_tex_fix(param_6, param_7);\n        float3 _277 = (_273 * 2.0f) - 1.0f.xxx;\n        float2 _282 = _277.xy * _211_fa_maps.x;\n        float3 _586 = _277;\n        _586.x = _282.x;\n        _586.y = _282.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _586;\n        _559 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _211_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _311 = fa_tex_fix(param_12, param_13);\n    float4 _589 = mrt;\n    _589.x = _311.x;\n    _589.y = _311.y;\n    _589.z = _311.z;\n    mrt = _589;\n    float param_14 = _211_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _352 = fa_tex_fix(param_16, param_17);\n    float param_18 = _211_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _379 = fa_tex_fix(param_20, param_21);\n    Surface _571 = { _239.xyz, _239.w, _559, clamp(_211_fa_pbr.x * _311.z, 0.0f, 1.0f), clamp(_211_fa_pbr.y * _311.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_211_fa_maps.y * (_352.x - 1.0f)), _211_fa_emissive.xyz + (_211_fa_model_emissive.xyz * _379) };\n    return _571;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    float3 _506 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _506 = -_506;\n    }\n    float3 _424 = normalize(_211_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _519 = { fa_world_pos, _506, fa_world_tangent, fa_uv, fa_vertex_color, _424, gl_FrontFacing };\n    SurfaceInput param = _519;\n    SurfaceInput _527 = { fa_world_pos, _506, fa_world_tangent, fa_uv, fa_vertex_color, _424, gl_FrontFacing };\n    SurfaceInput param_1 = _527;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _439 = normalize(param_2.normal);\n    float3 _454 = normalize(float3(dot(fa_pre_r0, _439), dot(fa_pre_r1, _439), dot(fa_pre_r2, _439)));\n    float _466 = _454.z;\n    float2 e = _454.xy / ((abs(_454.x) + abs(_454.y)) + abs(_466)).xx;\n    if (_466 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_211",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _134_fa_view_proj : packoffset(c0);\n    row_major float4x4 _134_fa_light_vp : packoffset(c4);\n    float4 _134_fa_uv_scale : packoffset(c8);\n    float4 _134_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _181_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _172 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_181_fa_joint_rows[_172] * weights[i]);\n        r1 += (_181_fa_joint_rows[_172 + 1] * weights[i]);\n        r2 += (_181_fa_joint_rows[_172 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _410 = { mul(float4(position, 1.0f), model).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * _134_fa_uv_scale.xy, color, position };\n    return _410;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _271 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _417 = _271.world_pos;\n    float4 _282 = float4(_417, 1.0f);\n    fa_world_pos = _417;\n    fa_world_normal = _271.world_normal;\n    fa_world_tangent = _271.world_tangent;\n    fa_uv = _271.uv;\n    fa_vertex_color = _271.color;\n    fa_pre_depth = -mul(_282, _134_fa_light_vp).z;\n    fa_pre_r0 = float3(_134_fa_light_vp[0].x, _134_fa_light_vp[1].x, _134_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_134_fa_light_vp[0].y, _134_fa_light_vp[1].y, _134_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_134_fa_light_vp[0].z, _134_fa_light_vp[1].z, _134_fa_light_vp[2].z);\n    gl_Position = mul(_282, _134_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _211_fa_camera_pos : packoffset(c0);\n    float4 _211_fa_ambient : packoffset(c1);\n    float4 _211_fa_base_color : packoffset(c2);\n    float4 _211_fa_emissive : packoffset(c3);\n    float4 _211_fa_model_emissive : packoffset(c4);\n    float4 _211_fa_pbr : packoffset(c5);\n    float4 _211_fa_maps : packoffset(c6);\n    float4 _211_fa_fog : packoffset(c7);\n    float4 _211_fa_fog_b : packoffset(c8);\n    float4 _211_fa_fog_c : packoffset(c9);\n    float4 _211_fa_counts : packoffset(c10);\n    float4 _211_fa_env_sky : packoffset(c11);\n    float4 _211_fa_env_horizon : packoffset(c12);\n    float4 _211_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _170 = fa_linear_to_srgb(param);\n        c = _170;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _179 = fa_srgb_to_linear(param_1);\n            c = _179;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _54;\n    if (i.front_facing)\n    {\n        _54 = i.world_normal;\n    }\n    else\n    {\n        _54 = -i.world_normal;\n    }\n    float3 _79 = normalize(i.world_tangent.xyz - (_54 * dot(_54, i.world_tangent.xyz)));\n    float3 _107 = normalize(((_79 * m.x) + ((cross(_54, _79) * i.world_tangent.w) * m.y)) + (_54 * m.z));\n    float3 _110;\n    if (i.front_facing)\n    {\n        _110 = _107;\n    }\n    else\n    {\n        _110 = -_107;\n    }\n    return _110;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _211_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _223 = fa_tex_fix(param_2, param_3);\n    float4 _578 = base_t;\n    _578.x = _223.x;\n    _578.y = _223.y;\n    _578.z = _223.z;\n    base_t = _578;\n    float4 _239 = (_578 * _211_fa_base_color) * i.vertex_color;\n    float3 _559 = i.world_normal;\n    if (_211_fa_maps.z > 0.5f)\n    {\n        float param_4 = _211_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _273 = fa_tex_fix(param_6, param_7);\n        float3 _277 = (_273 * 2.0f) - 1.0f.xxx;\n        float2 _282 = _277.xy * _211_fa_maps.x;\n        float3 _586 = _277;\n        _586.x = _282.x;\n        _586.y = _282.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _586;\n        _559 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _211_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _311 = fa_tex_fix(param_12, param_13);\n    float4 _589 = mrt;\n    _589.x = _311.x;\n    _589.y = _311.y;\n    _589.z = _311.z;\n    mrt = _589;\n    float param_14 = _211_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _352 = fa_tex_fix(param_16, param_17);\n    float param_18 = _211_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _379 = fa_tex_fix(param_20, param_21);\n    Surface _571 = { _239.xyz, _239.w, _559, clamp(_211_fa_pbr.x * _311.z, 0.0f, 1.0f), clamp(_211_fa_pbr.y * _311.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_211_fa_maps.y * (_352.x - 1.0f)), _211_fa_emissive.xyz + (_211_fa_model_emissive.xyz * _379) };\n    return _571;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    float3 _506 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _506 = -_506;\n    }\n    float3 _424 = normalize(_211_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _519 = { fa_world_pos, _506, fa_world_tangent, fa_uv, fa_vertex_color, _424, gl_FrontFacing };\n    SurfaceInput param = _519;\n    SurfaceInput _527 = { fa_world_pos, _506, fa_world_tangent, fa_uv, fa_vertex_color, _424, gl_FrontFacing };\n    SurfaceInput param_1 = _527;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _439 = normalize(param_2.normal);\n    float3 _454 = normalize(float3(dot(fa_pre_r0, _439), dot(fa_pre_r1, _439), dot(fa_pre_r2, _439)));\n    float _466 = _454.z;\n    float2 e = _454.xy / ((abs(_454.x) + abs(_454.y)) + abs(_466)).xx;\n    if (_466 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_211",
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
