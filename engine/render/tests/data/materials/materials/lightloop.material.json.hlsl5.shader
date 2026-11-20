{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "3995aa0ba56be221fe15f8a0d00a1f706ae46d0f598c3711968fac755bdd80f5",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _266 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _266;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _273 = _160.world_pos;\n    float4 _167 = float4(_273, 1.0f);\n    fa_world_pos = _273;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_shadow_pos = mul(_167, _131_fa_light_vp);\n    gl_Position = mul(_167, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _743[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _2479 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _217_fa_light_pos[32] : packoffset(c0);\n    float4 _217_fa_light_color[32] : packoffset(c32);\n    float4 _217_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _335_fa_camera_pos : packoffset(c0);\n    float4 _335_fa_ambient : packoffset(c1);\n    float4 _335_fa_base_color : packoffset(c2);\n    float4 _335_fa_emissive : packoffset(c3);\n    float4 _335_fa_model_emissive : packoffset(c4);\n    float4 _335_fa_pbr : packoffset(c5);\n    float4 _335_fa_maps : packoffset(c6);\n    float4 _335_fa_fog : packoffset(c7);\n    float4 _335_fa_fog_b : packoffset(c8);\n    float4 _335_fa_fog_c : packoffset(c9);\n    float4 _335_fa_counts : packoffset(c10);\n    float4 _335_fa_env_sky : packoffset(c11);\n    float4 _335_fa_env_horizon : packoffset(c12);\n    float4 _335_fa_time : packoffset(c13);\n    float4 _335_fa_layers_a : packoffset(c14);\n    float4 _335_fa_layers_b : packoffset(c15);\n    float4 _335_fa_layers_c : packoffset(c16);\n    float4 _335_fa_layers_d : packoffset(c17);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _1445_dark : packoffset(c0);\n    float _1445_fa_pad0 : packoffset(c0.y);\n    float _1445_fa_pad1 : packoffset(c0.z);\n    float _1445_fa_pad2 : packoffset(c0.w);\n    float _1445_skyAmount : packoffset(c1);\n    float _1445_fa_pad3 : packoffset(c1.y);\n    float _1445_fa_pad4 : packoffset(c1.z);\n    float _1445_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1517 = fa_linear_to_srgb(param);\n        c = _1517;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1525 = fa_srgb_to_linear(param_1);\n            c = _1525;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _145;\n    if (i.front_facing)\n    {\n        _145 = i.world_normal;\n    }\n    else\n    {\n        _145 = -i.world_normal;\n    }\n    float3 _169 = normalize(i.world_tangent.xyz - (_145 * dot(_145, i.world_tangent.xyz)));\n    float3 _197 = normalize(((_169 * m.x) + ((cross(_145, _169) * i.world_tangent.w) * m.y)) + (_145 * m.z));\n    float3 _200;\n    if (i.front_facing)\n    {\n        _200 = _197;\n    }\n    else\n    {\n        _200 = -_197;\n    }\n    return _200;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _335_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1557 = fa_tex_fix(param_2, param_3);\n    float4 _2451 = base_t;\n    _2451.x = _1557.x;\n    _2451.y = _1557.y;\n    _2451.z = _1557.z;\n    base_t = _2451;\n    float4 _1571 = (_2451 * _335_fa_base_color) * i.vertex_color;\n    float3 _2394 = i.world_normal;\n    if (_335_fa_maps.z > 0.5f)\n    {\n        float param_4 = _335_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1604 = fa_tex_fix(param_6, param_7);\n        float3 _1607 = (_1604 * 2.0f) - 1.0f.xxx;\n        float2 _1612 = _1607.xy * _335_fa_maps.x;\n        float3 _2459 = _1607;\n        _2459.x = _1612.x;\n        _2459.y = _1612.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2459;\n        _2394 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _335_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1641 = fa_tex_fix(param_12, param_13);\n    float4 _2462 = mrt;\n    _2462.x = _1641.x;\n    _2462.y = _1641.y;\n    _2462.z = _1641.z;\n    mrt = _2462;\n    float4 _1669 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _335_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _1669.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1681 = fa_tex_fix(param_16, param_17);\n    float param_18 = _335_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1711 = fa_tex_fix(param_20, param_21);\n    float _2399 = _335_fa_layers_a.x;\n    float _2400 = _335_fa_layers_a.y;\n    float _2403 = _335_fa_layers_a.z;\n    float _2402 = _335_fa_layers_b.w;\n    float _2405 = _335_fa_layers_c.x;\n    if (_335_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_335_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _2399 *= _1681.y;\n            _2400 *= _1681.z;\n            _2402 *= _1669.w;\n        }\n        if (_335_fa_layers_c.z > 1.5f)\n        {\n            _2403 *= mrt.x;\n            _2405 *= mrt.w;\n        }\n    }\n    Surface _2424 = { _1571.xyz, _1571.w, _2394, clamp(_335_fa_pbr.x * _1641.z, 0.0f, 1.0f), clamp(_335_fa_pbr.y * _1641.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_335_fa_maps.y * (_1681.x - 1.0f)), _335_fa_emissive.xyz + (_335_fa_model_emissive.xyz * _1711), _2399, _2400, _335_fa_layers_b.xyz, _2402, _2403, _335_fa_layers_a.w, _2405, _335_fa_layers_c.y, _335_fa_layers_d.xyz };\n    return _2424;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return min(int(_335_fa_counts.x), 32);\n}\n\nLightSample fa_no_light()\n{\n    return _2479;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _228 = _217_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_228)\n    {\n        l = normalize(_217_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _246 = _217_fa_light_pos[li].xyz - world_pos;\n        float _248 = length(_246);\n        dist = _248;\n        l = _246 / max(_248, 9.9999997473787516355514526367188e-05f).xxx;\n        float _264 = _248 / max(_217_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _270 = clamp(1.0f - (_264 * _264), 0.0f, 1.0f);\n        atten = _270 * _270;\n        if (_217_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_217_fa_light_dir[li].w, lerp(_217_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_217_fa_light_dir[li].xyz)));\n        }\n    }\n    int _321;\n    if (_228)\n    {\n        _321 = 0;\n    }\n    else\n    {\n        _321 = (_217_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _2243 = { l, _217_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _321 };\n    return _2243;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _1358 = n < 0;\n    bool _1365;\n    if (!_1358)\n    {\n        _1365 = n >= fa_light_count();\n    }\n    else\n    {\n        _1365 = _1358;\n    }\n    if (_1365)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    float3 param_1 = i.world_pos;\n    return fa_light_sample(param, param_1);\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_335_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _348 = coord.xyz / coord.w.xxx;\n    float3 p = _348;\n    float2 suv = (_348.xy * 0.5f) + 0.5f.xx;\n    if (_335_fa_counts.z > 0.5f)\n    {\n        float3 _2426 = p;\n        _2426.z = (_2426.z * 0.5f) + 0.5f;\n        p = _2426;\n    }\n    else\n    {\n        float2 _2429 = suv;\n        _2429.y = 1.0f - _2429.y;\n        suv = _2429;\n    }\n    bool _376 = suv.x < 0.0f;\n    bool _383;\n    if (!_376)\n    {\n        _383 = suv.x > 1.0f;\n    }\n    else\n    {\n        _383 = _376;\n    }\n    bool _390;\n    if (!_383)\n    {\n        _390 = suv.y < 0.0f;\n    }\n    else\n    {\n        _390 = _383;\n    }\n    bool _397;\n    if (!_390)\n    {\n        _397 = suv.y > 1.0f;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    bool _404;\n    if (!_397)\n    {\n        _404 = p.z > 1.0f;\n    }\n    else\n    {\n        _404 = _397;\n    }\n    if (_404)\n    {\n        return 1.0f;\n    }\n    float _419 = _335_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _419) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _335_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1296 = fa_light_sample(param, param_1);\n    float3 _2370 = _1296.direction;\n    float3 _2365 = _1296.color;\n    float _2372 = _1296.attenuation;\n    float _2367 = _1296.shadow;\n    int _2375 = _1296.type;\n    if ((_2375 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2370;\n        float _1310 = fa_shadow_factor(param_2, param_3);\n        _2367 = _1310;\n        _2365 = _217_fa_light_color[li].xyz * (_2372 * _1310);\n    }\n    LightSample _2382 = { _2370, _2365, _2372, _2367, _1296._distance, _2375 };\n    return _2382;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _1334 = n < 0;\n    bool _1341;\n    if (!_1334)\n    {\n        _1341 = n >= fa_light_count();\n    }\n    else\n    {\n        _1341 = _1334;\n    }\n    if (_1341)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    float3 param_1 = i.world_pos;\n    float3 param_2 = i.world_normal;\n    return fa_light_shadowed(param, param_1, param_2);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _668 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _676 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _679 = int(_668);\n    int _682 = int(_676);\n    float _692 = _676 - float(_682);\n    int _748 = (_679 * 9) + _682;\n    int _768 = ((_679 + 1) * 9) + _682;\n    return lerp(lerp(_743[_748], _743[_748 + 1], _692), lerp(_743[_768], _743[_768 + 1], _692), _668 - float(_679));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _2244 = false;\n    float _2245 = 1.0f;\n    float _2246 = 1.0f;\n    float _2247 = 1.0f;\n    float _2248 = 0.0f;\n    float _2249 = 0.0f;\n    float _2250 = 0.0f;\n    float _2251 = 0.0f;\n    float _2253 = 1.0f;\n    bool _2254 = false;\n    float3 _2255 = 0.0f.xxx;\n    float _2256 = 1.0f;\n    float _2257 = 1.0f;\n    float _2258 = 1.0f;\n    float _2259 = 0.0f;\n    float _2260 = 0.0f;\n    float3 _2261 = float3(1.0f, 0.0f, 0.0f);\n    float3 _2262 = float3(0.0f, 0.0f, 1.0f);\n    float _2263 = 1.0f;\n    float _2264 = 1.0f;\n    float _830 = clamp(s.specular, 0.0f, 1.0f);\n    float _835 = clamp(s.ior, 1.0f, 3.0f);\n    bool _840 = (_830 != 1.0f) || (_835 != 1.5f);\n    bool _850;\n    if (!_840)\n    {\n        _850 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _850 = _840;\n    }\n    if (_850)\n    {\n        float _858 = (_835 - 1.0f) / (_835 + 1.0f);\n        f0 = lerp(min((_858 * _858).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _830, s.albedo, metallic.xxx);\n        _2245 = lerp(_830, 1.0f, metallic);\n        _2244 = true;\n    }\n    float _886 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_886 > 0.0f)\n    {\n        float _894 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _2248 = _886;\n        _2249 = _894;\n        float _901 = _894 * _894;\n        _2250 = _901;\n        _2251 = _901 * _901;\n        float _913 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _2253 = _913;\n        _2246 = 1.0f - (_886 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(1.0f - _913, 5.0f))));\n        _2244 = true;\n    }\n    float3 _932 = max(s.sheen_color, 0.0f.xxx);\n    float _941 = max(_932.x, max(_932.y, _932.z));\n    if (_941 > 0.0f)\n    {\n        float _949 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _2254 = true;\n        _2255 = _932;\n        _2256 = _949;\n        _2257 = _949 * _949;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _949;\n        float _966 = fa_sheen_albedo(param, param_1);\n        _2259 = _966;\n        _2258 = 1.0f - min(_941 * _966, 1.0f);\n        _2244 = true;\n    }\n    _2247 = _2246 * _2258;\n    float _985 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_985 != 0.0f)\n    {\n        float3 _1000 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1000;\n        if (dot(_1000, _1000) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1014 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1014.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1014.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1014.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1018 = t;\n        float3 _1019 = normalize(_1018);\n        t = _1019;\n        float3 _1044 = normalize((_1019 * cos(s.anisotropy_rotation)) + ((cross(n, _1019) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _2261 = _1044;\n        _2262 = cross(n, _1044);\n        float _1054 = roughness * roughness;\n        float _1060 = lerp(_1054, 1.0f, _985 * _985);\n        bool _1062 = _985 > 0.0f;\n        _2263 = _1062 ? _1060 : _1054;\n        _2264 = _1062 ? _1054 : _1060;\n        _2260 = _985;\n        _2244 = true;\n    }\n    FaLayers _2286 = { _2244, _2245, _2246, _2247, _2248, _2249, _2250, _2251, i.world_normal, _2253, _2254, _2255, _2256, _2257, _2258, _2259, _2260, _2261, _2262, _2263, _2264 };\n    return _2286;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _598 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _601 = _598.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_601 * _601, exp2((-9.27999973297119140625f) * ndv)) * _601) + _598.y)) + _598.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_335_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _335_fa_env_horizon.w).xyz;\n    }\n    float _519 = rough * rough;\n    float _550 = 0.60000002384185791015625f * _519;\n    return lerp(lerp(_335_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_335_fa_env_horizon.xyz, _335_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _519)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _550, 0.0500000007450580596923828125f + _550, d.y).xxx), ((_335_fa_env_sky.xyz + _335_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_519 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1095;\n        if (L.aniso >= 0.0f)\n        {\n            _1095 = L.b;\n        }\n        else\n        {\n            _1095 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1095, v), _1095), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1128 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1128.x) + (L.f90.xxx * _1128.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1183 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _1183.x) + _1183.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _640 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _640.x) + _640.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _1222 = clamp(s.metallic, 0.0f, 1.0f);\n    float _1226 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _1233 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _1222.xxx);\n    float3 f0 = _1233;\n    float3 _1237 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _1237;\n    float3 param_3 = i.view_dir;\n    float param_4 = _1222;\n    float param_5 = _1226;\n    float3 param_6 = _1233;\n    FaLayers _1254 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_1254.on)\n    {\n        FaLayers param_7 = _1254;\n        float3 param_8 = _1237;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _1226;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _1237;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _1226;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1402 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_1402 > bestPower)\n        {\n            bestPower = _1402;\n            best = n;\n        }\n    }\n    float3 lit = (_335_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1431 = fa_light(param_2, param_3);\n        float _1439;\n        if (dot(s.normal, _1431.direction) > 0.5f)\n        {\n            _1439 = 1.0f;\n        }\n        else\n        {\n            _1439 = _1445_dark;\n        }\n        lit += ((s.albedo * _1431.color) * _1439);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _1445_skyAmount);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2118 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2118 = -_2118;\n    }\n    float3 _1831 = normalize(_335_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _2131 = { fa_world_pos, _2118, fa_world_tangent, fa_uv, fa_vertex_color, _1831, gl_FrontFacing };\n    SurfaceInput param = _2131;\n    Surface _1836 = fa_standard_surface(param);\n    float3 _2149 = _1836.albedo;\n    float _2150 = _1836.alpha;\n    float3 _2151 = _1836.normal;\n    float _2152 = _1836.metallic;\n    float _2153 = _1836.roughness;\n    float _2154 = _1836.occlusion;\n    float3 _2155 = _1836.emission;\n    float _2156 = _1836.clearcoat;\n    float _2157 = _1836.clearcoat_roughness;\n    float3 _2158 = _1836.sheen_color;\n    float _2159 = _1836.sheen_roughness;\n    float _2160 = _1836.anisotropy;\n    float _2161 = _1836.anisotropy_rotation;\n    float _2162 = _1836.specular;\n    float _2163 = _1836.ior;\n    float3 _2164 = _1836.specular_color;\n    SurfaceInput _2139 = { fa_world_pos, _2118, fa_world_tangent, fa_uv, fa_vertex_color, _1831, gl_FrontFacing };\n    SurfaceInput param_1 = _2139;\n    Surface param_2 = _1836;\n    surface(param_1, param_2);\n    _2149 = param_2.albedo;\n    _2150 = param_2.alpha;\n    _2151 = param_2.normal;\n    _2152 = param_2.metallic;\n    _2153 = param_2.roughness;\n    _2154 = param_2.occlusion;\n    _2155 = param_2.emission;\n    _2156 = param_2.clearcoat;\n    _2157 = param_2.clearcoat_roughness;\n    _2158 = param_2.sheen_color;\n    _2159 = param_2.sheen_roughness;\n    _2160 = param_2.anisotropy;\n    _2161 = param_2.anisotropy_rotation;\n    _2162 = param_2.specular;\n    _2163 = param_2.ior;\n    _2164 = param_2.specular_color;\n    float3 result;\n    if (_335_fa_emissive.w > 0.5f)\n    {\n        result = _2149;\n    }\n    else\n    {\n        float3 _1857 = _2151;\n        float3 _1858 = normalize(_1857);\n        _2151 = _1858;\n        SurfaceInput _2147 = { fa_world_pos, _2118, fa_world_tangent, fa_uv, fa_vertex_color, _1831, gl_FrontFacing };\n        SurfaceInput param_3 = _2147;\n        Surface _2230 = { _2149, _2150, _1858, _2152, _2153, _2154, _2155, _2156, _2157, _2158, _2159, _2160, _2161, _2162, _2163, _2164 };\n        Surface param_4 = _2230;\n        result = lighting(param_3, param_4);\n    }\n    result += _2155;\n    bool _1877 = _335_fa_fog.w > 0.0f;\n    bool _1884;\n    if (!_1877)\n    {\n        _1884 = _335_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1884 = _1877;\n    }\n    if (_1884)\n    {\n        float3 _1893 = fa_world_pos - _335_fa_camera_pos.xyz;\n        float _1899 = dot(_1893, _335_fa_fog_c.xyz);\n        bool _1903 = _335_fa_fog_c.w > 0.5f;\n        float _1904;\n        if (_1903)\n        {\n            _1904 = _1899;\n        }\n        else\n        {\n            _1904 = length(_1893);\n        }\n        float _1916 = _1904 - _335_fa_fog_b.x;\n        if (_1916 > 0.0f)\n        {\n            float _1925 = _335_fa_fog.w * _1916;\n            float tau = _1925 * _1925;\n            if (_335_fa_fog_b.y > 0.0f)\n            {\n                float _1941;\n                if (_1903)\n                {\n                    _1941 = fa_world_pos.y - (_335_fa_fog_c.y * _1899);\n                }\n                else\n                {\n                    _1941 = _335_fa_camera_pos.y;\n                }\n                float _1962 = lerp(_1941, fa_world_pos.y, clamp(_335_fa_fog_b.x / _1904, 0.0f, 1.0f));\n                float _1966 = fa_world_pos.y - _1962;\n                float _1971 = _1962 - _335_fa_fog_b.z;\n                float _1976 = fa_world_pos.y - _335_fa_fog_b.z;\n                bool _1979 = _1971 <= 0.0f;\n                bool _1980 = !_1979;\n                bool _1986;\n                if (_1980)\n                {\n                    _1986 = _335_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1986 = _1979;\n                }\n                float _1987;\n                if (_1986)\n                {\n                    _1987 = _335_fa_fog_b.y;\n                }\n                else\n                {\n                    _1987 = _335_fa_fog_b.y * exp(-min(_335_fa_fog_b.w * _1971, 80.0f));\n                }\n                bool _2014;\n                if (_1980)\n                {\n                    _2014 = _335_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2014 = _1979;\n                }\n                float _2015;\n                if (_2014)\n                {\n                    _2015 = _335_fa_fog_b.y * _1971;\n                }\n                else\n                {\n                    _2015 = (_335_fa_fog_b.y * (1.0f - exp(-min(_335_fa_fog_b.w * _1971, 80.0f)))) / _335_fa_fog_b.w;\n                }\n                bool _2040 = _1976 <= 0.0f;\n                bool _2047;\n                if (!_2040)\n                {\n                    _2047 = _335_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2047 = _2040;\n                }\n                float _2048;\n                if (_2047)\n                {\n                    _2048 = _335_fa_fog_b.y * _1976;\n                }\n                else\n                {\n                    _2048 = (_335_fa_fog_b.y * (1.0f - exp(-min(_335_fa_fog_b.w * _1976, 80.0f)))) / _335_fa_fog_b.w;\n                }\n                float _2075;\n                if (abs(_1966) < 0.001000000047497451305389404296875f)\n                {\n                    _2075 = _1987;\n                }\n                else\n                {\n                    _2075 = (_2048 - _2015) / _1966;\n                }\n                tau += (_1916 * max(_2075, 0.0f));\n            }\n            result = lerp(result, _335_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2150);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_217",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_335",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1445",
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
          },
          {
            "slot": 6,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _743[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _2479 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _217_fa_light_pos[32] : packoffset(c0);\n    float4 _217_fa_light_color[32] : packoffset(c32);\n    float4 _217_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _335_fa_camera_pos : packoffset(c0);\n    float4 _335_fa_ambient : packoffset(c1);\n    float4 _335_fa_base_color : packoffset(c2);\n    float4 _335_fa_emissive : packoffset(c3);\n    float4 _335_fa_model_emissive : packoffset(c4);\n    float4 _335_fa_pbr : packoffset(c5);\n    float4 _335_fa_maps : packoffset(c6);\n    float4 _335_fa_fog : packoffset(c7);\n    float4 _335_fa_fog_b : packoffset(c8);\n    float4 _335_fa_fog_c : packoffset(c9);\n    float4 _335_fa_counts : packoffset(c10);\n    float4 _335_fa_env_sky : packoffset(c11);\n    float4 _335_fa_env_horizon : packoffset(c12);\n    float4 _335_fa_time : packoffset(c13);\n    float4 _335_fa_layers_a : packoffset(c14);\n    float4 _335_fa_layers_b : packoffset(c15);\n    float4 _335_fa_layers_c : packoffset(c16);\n    float4 _335_fa_layers_d : packoffset(c17);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _1445_dark : packoffset(c0);\n    float _1445_fa_pad0 : packoffset(c0.y);\n    float _1445_fa_pad1 : packoffset(c0.z);\n    float _1445_fa_pad2 : packoffset(c0.w);\n    float _1445_skyAmount : packoffset(c1);\n    float _1445_fa_pad3 : packoffset(c1.y);\n    float _1445_fa_pad4 : packoffset(c1.z);\n    float _1445_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1517 = fa_linear_to_srgb(param);\n        c = _1517;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1525 = fa_srgb_to_linear(param_1);\n            c = _1525;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _145;\n    if (i.front_facing)\n    {\n        _145 = i.world_normal;\n    }\n    else\n    {\n        _145 = -i.world_normal;\n    }\n    float3 _169 = normalize(i.world_tangent.xyz - (_145 * dot(_145, i.world_tangent.xyz)));\n    float3 _197 = normalize(((_169 * m.x) + ((cross(_145, _169) * i.world_tangent.w) * m.y)) + (_145 * m.z));\n    float3 _200;\n    if (i.front_facing)\n    {\n        _200 = _197;\n    }\n    else\n    {\n        _200 = -_197;\n    }\n    return _200;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _335_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1557 = fa_tex_fix(param_2, param_3);\n    float4 _2451 = base_t;\n    _2451.x = _1557.x;\n    _2451.y = _1557.y;\n    _2451.z = _1557.z;\n    base_t = _2451;\n    float4 _1571 = (_2451 * _335_fa_base_color) * i.vertex_color;\n    float3 _2394 = i.world_normal;\n    if (_335_fa_maps.z > 0.5f)\n    {\n        float param_4 = _335_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1604 = fa_tex_fix(param_6, param_7);\n        float3 _1607 = (_1604 * 2.0f) - 1.0f.xxx;\n        float2 _1612 = _1607.xy * _335_fa_maps.x;\n        float3 _2459 = _1607;\n        _2459.x = _1612.x;\n        _2459.y = _1612.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2459;\n        _2394 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _335_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1641 = fa_tex_fix(param_12, param_13);\n    float4 _2462 = mrt;\n    _2462.x = _1641.x;\n    _2462.y = _1641.y;\n    _2462.z = _1641.z;\n    mrt = _2462;\n    float4 _1669 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _335_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _1669.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1681 = fa_tex_fix(param_16, param_17);\n    float param_18 = _335_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1711 = fa_tex_fix(param_20, param_21);\n    float _2399 = _335_fa_layers_a.x;\n    float _2400 = _335_fa_layers_a.y;\n    float _2403 = _335_fa_layers_a.z;\n    float _2402 = _335_fa_layers_b.w;\n    float _2405 = _335_fa_layers_c.x;\n    if (_335_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_335_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _2399 *= _1681.y;\n            _2400 *= _1681.z;\n            _2402 *= _1669.w;\n        }\n        if (_335_fa_layers_c.z > 1.5f)\n        {\n            _2403 *= mrt.x;\n            _2405 *= mrt.w;\n        }\n    }\n    Surface _2424 = { _1571.xyz, _1571.w, _2394, clamp(_335_fa_pbr.x * _1641.z, 0.0f, 1.0f), clamp(_335_fa_pbr.y * _1641.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_335_fa_maps.y * (_1681.x - 1.0f)), _335_fa_emissive.xyz + (_335_fa_model_emissive.xyz * _1711), _2399, _2400, _335_fa_layers_b.xyz, _2402, _2403, _335_fa_layers_a.w, _2405, _335_fa_layers_c.y, _335_fa_layers_d.xyz };\n    return _2424;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return min(int(_335_fa_counts.x), 32);\n}\n\nLightSample fa_no_light()\n{\n    return _2479;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _228 = _217_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_228)\n    {\n        l = normalize(_217_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _246 = _217_fa_light_pos[li].xyz - world_pos;\n        float _248 = length(_246);\n        dist = _248;\n        l = _246 / max(_248, 9.9999997473787516355514526367188e-05f).xxx;\n        float _264 = _248 / max(_217_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _270 = clamp(1.0f - (_264 * _264), 0.0f, 1.0f);\n        atten = _270 * _270;\n        if (_217_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_217_fa_light_dir[li].w, lerp(_217_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_217_fa_light_dir[li].xyz)));\n        }\n    }\n    int _321;\n    if (_228)\n    {\n        _321 = 0;\n    }\n    else\n    {\n        _321 = (_217_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _2243 = { l, _217_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _321 };\n    return _2243;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _1358 = n < 0;\n    bool _1365;\n    if (!_1358)\n    {\n        _1365 = n >= fa_light_count();\n    }\n    else\n    {\n        _1365 = _1358;\n    }\n    if (_1365)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    float3 param_1 = i.world_pos;\n    return fa_light_sample(param, param_1);\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_335_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _348 = coord.xyz / coord.w.xxx;\n    float3 p = _348;\n    float2 suv = (_348.xy * 0.5f) + 0.5f.xx;\n    if (_335_fa_counts.z > 0.5f)\n    {\n        float3 _2426 = p;\n        _2426.z = (_2426.z * 0.5f) + 0.5f;\n        p = _2426;\n    }\n    else\n    {\n        float2 _2429 = suv;\n        _2429.y = 1.0f - _2429.y;\n        suv = _2429;\n    }\n    bool _376 = suv.x < 0.0f;\n    bool _383;\n    if (!_376)\n    {\n        _383 = suv.x > 1.0f;\n    }\n    else\n    {\n        _383 = _376;\n    }\n    bool _390;\n    if (!_383)\n    {\n        _390 = suv.y < 0.0f;\n    }\n    else\n    {\n        _390 = _383;\n    }\n    bool _397;\n    if (!_390)\n    {\n        _397 = suv.y > 1.0f;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    bool _404;\n    if (!_397)\n    {\n        _404 = p.z > 1.0f;\n    }\n    else\n    {\n        _404 = _397;\n    }\n    if (_404)\n    {\n        return 1.0f;\n    }\n    float _419 = _335_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _419) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _335_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1296 = fa_light_sample(param, param_1);\n    float3 _2370 = _1296.direction;\n    float3 _2365 = _1296.color;\n    float _2372 = _1296.attenuation;\n    float _2367 = _1296.shadow;\n    int _2375 = _1296.type;\n    if ((_2375 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2370;\n        float _1310 = fa_shadow_factor(param_2, param_3);\n        _2367 = _1310;\n        _2365 = _217_fa_light_color[li].xyz * (_2372 * _1310);\n    }\n    LightSample _2382 = { _2370, _2365, _2372, _2367, _1296._distance, _2375 };\n    return _2382;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _1334 = n < 0;\n    bool _1341;\n    if (!_1334)\n    {\n        _1341 = n >= fa_light_count();\n    }\n    else\n    {\n        _1341 = _1334;\n    }\n    if (_1341)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    float3 param_1 = i.world_pos;\n    float3 param_2 = i.world_normal;\n    return fa_light_shadowed(param, param_1, param_2);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _668 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _676 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _679 = int(_668);\n    int _682 = int(_676);\n    float _692 = _676 - float(_682);\n    int _748 = (_679 * 9) + _682;\n    int _768 = ((_679 + 1) * 9) + _682;\n    return lerp(lerp(_743[_748], _743[_748 + 1], _692), lerp(_743[_768], _743[_768 + 1], _692), _668 - float(_679));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _2244 = false;\n    float _2245 = 1.0f;\n    float _2246 = 1.0f;\n    float _2247 = 1.0f;\n    float _2248 = 0.0f;\n    float _2249 = 0.0f;\n    float _2250 = 0.0f;\n    float _2251 = 0.0f;\n    float _2253 = 1.0f;\n    bool _2254 = false;\n    float3 _2255 = 0.0f.xxx;\n    float _2256 = 1.0f;\n    float _2257 = 1.0f;\n    float _2258 = 1.0f;\n    float _2259 = 0.0f;\n    float _2260 = 0.0f;\n    float3 _2261 = float3(1.0f, 0.0f, 0.0f);\n    float3 _2262 = float3(0.0f, 0.0f, 1.0f);\n    float _2263 = 1.0f;\n    float _2264 = 1.0f;\n    float _830 = clamp(s.specular, 0.0f, 1.0f);\n    float _835 = clamp(s.ior, 1.0f, 3.0f);\n    bool _840 = (_830 != 1.0f) || (_835 != 1.5f);\n    bool _850;\n    if (!_840)\n    {\n        _850 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _850 = _840;\n    }\n    if (_850)\n    {\n        float _858 = (_835 - 1.0f) / (_835 + 1.0f);\n        f0 = lerp(min((_858 * _858).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _830, s.albedo, metallic.xxx);\n        _2245 = lerp(_830, 1.0f, metallic);\n        _2244 = true;\n    }\n    float _886 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_886 > 0.0f)\n    {\n        float _894 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _2248 = _886;\n        _2249 = _894;\n        float _901 = _894 * _894;\n        _2250 = _901;\n        _2251 = _901 * _901;\n        float _913 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _2253 = _913;\n        _2246 = 1.0f - (_886 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(1.0f - _913, 5.0f))));\n        _2244 = true;\n    }\n    float3 _932 = max(s.sheen_color, 0.0f.xxx);\n    float _941 = max(_932.x, max(_932.y, _932.z));\n    if (_941 > 0.0f)\n    {\n        float _949 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _2254 = true;\n        _2255 = _932;\n        _2256 = _949;\n        _2257 = _949 * _949;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _949;\n        float _966 = fa_sheen_albedo(param, param_1);\n        _2259 = _966;\n        _2258 = 1.0f - min(_941 * _966, 1.0f);\n        _2244 = true;\n    }\n    _2247 = _2246 * _2258;\n    float _985 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_985 != 0.0f)\n    {\n        float3 _1000 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1000;\n        if (dot(_1000, _1000) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1014 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1014.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1014.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1014.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1018 = t;\n        float3 _1019 = normalize(_1018);\n        t = _1019;\n        float3 _1044 = normalize((_1019 * cos(s.anisotropy_rotation)) + ((cross(n, _1019) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _2261 = _1044;\n        _2262 = cross(n, _1044);\n        float _1054 = roughness * roughness;\n        float _1060 = lerp(_1054, 1.0f, _985 * _985);\n        bool _1062 = _985 > 0.0f;\n        _2263 = _1062 ? _1060 : _1054;\n        _2264 = _1062 ? _1054 : _1060;\n        _2260 = _985;\n        _2244 = true;\n    }\n    FaLayers _2286 = { _2244, _2245, _2246, _2247, _2248, _2249, _2250, _2251, i.world_normal, _2253, _2254, _2255, _2256, _2257, _2258, _2259, _2260, _2261, _2262, _2263, _2264 };\n    return _2286;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _598 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _601 = _598.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_601 * _601, exp2((-9.27999973297119140625f) * ndv)) * _601) + _598.y)) + _598.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_335_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _335_fa_env_horizon.w).xyz;\n    }\n    float _519 = rough * rough;\n    float _550 = 0.60000002384185791015625f * _519;\n    return lerp(lerp(_335_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_335_fa_env_horizon.xyz, _335_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _519)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _550, 0.0500000007450580596923828125f + _550, d.y).xxx), ((_335_fa_env_sky.xyz + _335_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_519 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1095;\n        if (L.aniso >= 0.0f)\n        {\n            _1095 = L.b;\n        }\n        else\n        {\n            _1095 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1095, v), _1095), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1128 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1128.x) + (L.f90.xxx * _1128.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _1183 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _1183.x) + _1183.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _640 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _640.x) + _640.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _1222 = clamp(s.metallic, 0.0f, 1.0f);\n    float _1226 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _1233 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _1222.xxx);\n    float3 f0 = _1233;\n    float3 _1237 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _1237;\n    float3 param_3 = i.view_dir;\n    float param_4 = _1222;\n    float param_5 = _1226;\n    float3 param_6 = _1233;\n    FaLayers _1254 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_1254.on)\n    {\n        FaLayers param_7 = _1254;\n        float3 param_8 = _1237;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _1226;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _1237;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _1226;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1402 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_1402 > bestPower)\n        {\n            bestPower = _1402;\n            best = n;\n        }\n    }\n    float3 lit = (_335_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1431 = fa_light(param_2, param_3);\n        float _1439;\n        if (dot(s.normal, _1431.direction) > 0.5f)\n        {\n            _1439 = 1.0f;\n        }\n        else\n        {\n            _1439 = _1445_dark;\n        }\n        lit += ((s.albedo * _1431.color) * _1439);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _1445_skyAmount);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2118 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2118 = -_2118;\n    }\n    float3 _1831 = normalize(_335_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _2131 = { fa_world_pos, _2118, fa_world_tangent, fa_uv, fa_vertex_color, _1831, gl_FrontFacing };\n    SurfaceInput param = _2131;\n    Surface _1836 = fa_standard_surface(param);\n    float3 _2149 = _1836.albedo;\n    float _2150 = _1836.alpha;\n    float3 _2151 = _1836.normal;\n    float _2152 = _1836.metallic;\n    float _2153 = _1836.roughness;\n    float _2154 = _1836.occlusion;\n    float3 _2155 = _1836.emission;\n    float _2156 = _1836.clearcoat;\n    float _2157 = _1836.clearcoat_roughness;\n    float3 _2158 = _1836.sheen_color;\n    float _2159 = _1836.sheen_roughness;\n    float _2160 = _1836.anisotropy;\n    float _2161 = _1836.anisotropy_rotation;\n    float _2162 = _1836.specular;\n    float _2163 = _1836.ior;\n    float3 _2164 = _1836.specular_color;\n    SurfaceInput _2139 = { fa_world_pos, _2118, fa_world_tangent, fa_uv, fa_vertex_color, _1831, gl_FrontFacing };\n    SurfaceInput param_1 = _2139;\n    Surface param_2 = _1836;\n    surface(param_1, param_2);\n    _2149 = param_2.albedo;\n    _2150 = param_2.alpha;\n    _2151 = param_2.normal;\n    _2152 = param_2.metallic;\n    _2153 = param_2.roughness;\n    _2154 = param_2.occlusion;\n    _2155 = param_2.emission;\n    _2156 = param_2.clearcoat;\n    _2157 = param_2.clearcoat_roughness;\n    _2158 = param_2.sheen_color;\n    _2159 = param_2.sheen_roughness;\n    _2160 = param_2.anisotropy;\n    _2161 = param_2.anisotropy_rotation;\n    _2162 = param_2.specular;\n    _2163 = param_2.ior;\n    _2164 = param_2.specular_color;\n    float3 result;\n    if (_335_fa_emissive.w > 0.5f)\n    {\n        result = _2149;\n    }\n    else\n    {\n        float3 _1857 = _2151;\n        float3 _1858 = normalize(_1857);\n        _2151 = _1858;\n        SurfaceInput _2147 = { fa_world_pos, _2118, fa_world_tangent, fa_uv, fa_vertex_color, _1831, gl_FrontFacing };\n        SurfaceInput param_3 = _2147;\n        Surface _2230 = { _2149, _2150, _1858, _2152, _2153, _2154, _2155, _2156, _2157, _2158, _2159, _2160, _2161, _2162, _2163, _2164 };\n        Surface param_4 = _2230;\n        result = lighting(param_3, param_4);\n    }\n    result += _2155;\n    bool _1877 = _335_fa_fog.w > 0.0f;\n    bool _1884;\n    if (!_1877)\n    {\n        _1884 = _335_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1884 = _1877;\n    }\n    if (_1884)\n    {\n        float3 _1893 = fa_world_pos - _335_fa_camera_pos.xyz;\n        float _1899 = dot(_1893, _335_fa_fog_c.xyz);\n        bool _1903 = _335_fa_fog_c.w > 0.5f;\n        float _1904;\n        if (_1903)\n        {\n            _1904 = _1899;\n        }\n        else\n        {\n            _1904 = length(_1893);\n        }\n        float _1916 = _1904 - _335_fa_fog_b.x;\n        if (_1916 > 0.0f)\n        {\n            float _1925 = _335_fa_fog.w * _1916;\n            float tau = _1925 * _1925;\n            if (_335_fa_fog_b.y > 0.0f)\n            {\n                float _1941;\n                if (_1903)\n                {\n                    _1941 = fa_world_pos.y - (_335_fa_fog_c.y * _1899);\n                }\n                else\n                {\n                    _1941 = _335_fa_camera_pos.y;\n                }\n                float _1962 = lerp(_1941, fa_world_pos.y, clamp(_335_fa_fog_b.x / _1904, 0.0f, 1.0f));\n                float _1966 = fa_world_pos.y - _1962;\n                float _1971 = _1962 - _335_fa_fog_b.z;\n                float _1976 = fa_world_pos.y - _335_fa_fog_b.z;\n                bool _1979 = _1971 <= 0.0f;\n                bool _1980 = !_1979;\n                bool _1986;\n                if (_1980)\n                {\n                    _1986 = _335_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1986 = _1979;\n                }\n                float _1987;\n                if (_1986)\n                {\n                    _1987 = _335_fa_fog_b.y;\n                }\n                else\n                {\n                    _1987 = _335_fa_fog_b.y * exp(-min(_335_fa_fog_b.w * _1971, 80.0f));\n                }\n                bool _2014;\n                if (_1980)\n                {\n                    _2014 = _335_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2014 = _1979;\n                }\n                float _2015;\n                if (_2014)\n                {\n                    _2015 = _335_fa_fog_b.y * _1971;\n                }\n                else\n                {\n                    _2015 = (_335_fa_fog_b.y * (1.0f - exp(-min(_335_fa_fog_b.w * _1971, 80.0f)))) / _335_fa_fog_b.w;\n                }\n                bool _2040 = _1976 <= 0.0f;\n                bool _2047;\n                if (!_2040)\n                {\n                    _2047 = _335_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2047 = _2040;\n                }\n                float _2048;\n                if (_2047)\n                {\n                    _2048 = _335_fa_fog_b.y * _1976;\n                }\n                else\n                {\n                    _2048 = (_335_fa_fog_b.y * (1.0f - exp(-min(_335_fa_fog_b.w * _1976, 80.0f)))) / _335_fa_fog_b.w;\n                }\n                float _2075;\n                if (abs(_1966) < 0.001000000047497451305389404296875f)\n                {\n                    _2075 = _1987;\n                }\n                else\n                {\n                    _2075 = (_2048 - _2015) / _1966;\n                }\n                tau += (_1916 * max(_2075, 0.0f));\n            }\n            result = lerp(result, _335_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2150);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_217",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_335",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1445",
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
          },
          {
            "slot": 6,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_layers_a : packoffset(c14);\n    float4 _213_fa_layers_b : packoffset(c15);\n    float4 _213_fa_layers_c : packoffset(c16);\n    float4 _213_fa_layers_d : packoffset(c17);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213_fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213_fa_layers_a.x;\n    float _752 = _213_fa_layers_a.y;\n    float _755 = _213_fa_layers_a.z;\n    float _754 = _213_fa_layers_b.w;\n    float _757 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    Surface _776 = { _241.xyz, _241.w, _746, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _751, _752, _213_fa_layers_b.xyz, _754, _755, _213_fa_layers_a.w, _757, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _776;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _517 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _670 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _517, gl_FrontFacing };\n    SurfaceInput param = _670;\n    SurfaceInput _678 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _517, gl_FrontFacing };\n    SurfaceInput param_1 = _678;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _532 = normalize(param_2.normal);\n    float3 _547 = normalize(float3(dot(fa_pre_r0, _532), dot(fa_pre_r1, _532), dot(fa_pre_r2, _532)));\n    float _559 = _547.z;\n    float2 e = _547.xy / ((abs(_547.x) + abs(_547.y)) + abs(_559)).xx;\n    if (_559 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 288,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_layers_a : packoffset(c14);\n    float4 _213_fa_layers_b : packoffset(c15);\n    float4 _213_fa_layers_c : packoffset(c16);\n    float4 _213_fa_layers_d : packoffset(c17);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213_fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213_fa_layers_a.x;\n    float _752 = _213_fa_layers_a.y;\n    float _755 = _213_fa_layers_a.z;\n    float _754 = _213_fa_layers_b.w;\n    float _757 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    Surface _776 = { _241.xyz, _241.w, _746, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _751, _752, _213_fa_layers_b.xyz, _754, _755, _213_fa_layers_a.w, _757, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _776;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _517 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _670 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _517, gl_FrontFacing };\n    SurfaceInput param = _670;\n    SurfaceInput _678 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _517, gl_FrontFacing };\n    SurfaceInput param_1 = _678;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _532 = normalize(param_2.normal);\n    float3 _547 = normalize(float3(dot(fa_pre_r0, _532), dot(fa_pre_r1, _532), dot(fa_pre_r2, _532)));\n    float _559 = _547.z;\n    float2 e = _547.xy / ((abs(_547.x) + abs(_547.y)) + abs(_559)).xx;\n    if (_559 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 288,
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
