{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b612c93917ef2f2ca09ed7d7ebb5d582b3c039f51369a75c84a9a8e9083bd53a",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _258 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _258;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_265, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _203_fa_light_pos[32] : packoffset(c0);\n    float4 _203_fa_light_color[32] : packoffset(c32);\n    float4 _203_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _369_fa_shadow_mat[4] : packoffset(c0);\n    float4 _369_fa_shadow_rect[4] : packoffset(c16);\n    float4 _369_fa_shadow_info[4] : packoffset(c20);\n    float4 _369_fa_shadow_split : packoffset(c24);\n    float4 _369_fa_shadow_cfg : packoffset(c25);\n    float4 _369_fa_shadow_bias : packoffset(c26);\n    float4 _369_fa_shadow_eye : packoffset(c27);\n    float4 _369_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _728_fa_camera_pos : packoffset(c0);\n    float4 _728_fa_ambient : packoffset(c1);\n    float4 _728_fa_base_color : packoffset(c2);\n    float4 _728_fa_emissive : packoffset(c3);\n    float4 _728_fa_model_emissive : packoffset(c4);\n    float4 _728_fa_pbr : packoffset(c5);\n    float4 _728_fa_maps : packoffset(c6);\n    float4 _728_fa_fog : packoffset(c7);\n    float4 _728_fa_fog_b : packoffset(c8);\n    float4 _728_fa_fog_c : packoffset(c9);\n    float4 _728_fa_counts : packoffset(c10);\n    float4 _728_fa_env_sky : packoffset(c11);\n    float4 _728_fa_env_horizon : packoffset(c12);\n    float4 _728_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1288 = fa_linear_to_srgb(param);\n        c = _1288;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1296 = fa_srgb_to_linear(param_1);\n            c = _1296;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _131;\n    if (i.front_facing)\n    {\n        _131 = i.world_normal;\n    }\n    else\n    {\n        _131 = -i.world_normal;\n    }\n    float3 _155 = normalize(i.world_tangent.xyz - (_131 * dot(_131, i.world_tangent.xyz)));\n    float3 _183 = normalize(((_155 * m.x) + ((cross(_131, _155) * i.world_tangent.w) * m.y)) + (_131 * m.z));\n    float3 _186;\n    if (i.front_facing)\n    {\n        _186 = _183;\n    }\n    else\n    {\n        _186 = -_183;\n    }\n    return _186;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _728_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1327 = fa_tex_fix(param_2, param_3);\n    float4 _2113 = base_t;\n    _2113.x = _1327.x;\n    _2113.y = _1327.y;\n    _2113.z = _1327.z;\n    base_t = _2113;\n    float4 _1341 = (_2113 * _728_fa_base_color) * i.vertex_color;\n    float3 _2081 = i.world_normal;\n    if (_728_fa_maps.z > 0.5f)\n    {\n        float param_4 = _728_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1373 = fa_tex_fix(param_6, param_7);\n        float3 _1377 = (_1373 * 2.0f) - 1.0f.xxx;\n        float2 _1382 = _1377.xy * _728_fa_maps.x;\n        float3 _2121 = _1377;\n        _2121.x = _1382.x;\n        _2121.y = _1382.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2121;\n        _2081 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _728_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1411 = fa_tex_fix(param_12, param_13);\n    float4 _2124 = mrt;\n    _2124.x = _1411.x;\n    _2124.y = _1411.y;\n    _2124.z = _1411.z;\n    mrt = _2124;\n    float param_14 = _728_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1450 = fa_tex_fix(param_16, param_17);\n    float param_18 = _728_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1477 = fa_tex_fix(param_20, param_21);\n    Surface _2093 = { _1341.xyz, _1341.w, _2081, clamp(_728_fa_pbr.x * _1411.z, 0.0f, 1.0f), clamp(_728_fa_pbr.y * _1411.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_728_fa_maps.y * (_1450.x - 1.0f)), _728_fa_emissive.xyz + (_728_fa_model_emissive.xyz * _1477) };\n    return _2093;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += float3(0.5f + (0.5f * sin(_728_fa_time.x * 3.0f)), 0.25f * frac(_728_fa_time.x), 0.0f);\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_728_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _728_fa_ambient.xyz;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _214 = _203_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_214)\n    {\n        l = normalize(_203_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _232 = _203_fa_light_pos[li].xyz - world_pos;\n        float _234 = length(_232);\n        dist = _234;\n        l = _232 / max(_234, 9.9999997473787516355514526367188e-05f).xxx;\n        float _250 = _234 / max(_203_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _256 = clamp(1.0f - (_250 * _250), 0.0f, 1.0f);\n        atten = _256 * _256;\n        if (_203_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_203_fa_light_dir[li].w, lerp(_203_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_203_fa_light_dir[li].xyz)));\n        }\n    }\n    int _307;\n    if (_214)\n    {\n        _307 = 0;\n    }\n    else\n    {\n        _307 = (_203_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _2059 = { l, _203_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _307 };\n    return _2059;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _359;\n    if (i == 0)\n    {\n        _359 = _369_fa_shadow_split.x;\n    }\n    else\n    {\n        float _375;\n        if (i == 1)\n        {\n            _375 = _369_fa_shadow_split.y;\n        }\n        else\n        {\n            float _383;\n            if (i == 2)\n            {\n                _383 = _369_fa_shadow_split.z;\n            }\n            else\n            {\n                _383 = _369_fa_shadow_split.w;\n            }\n            _375 = _383;\n        }\n        _359 = _375;\n    }\n    return _359;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _347 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_347), sin(_347)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _427 = max(_369_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _432 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _438 = sqrt(1.0f - (_432 * _432));\n    float _446 = min(_438 / max(_432, 0.20000000298023223876953125f), 4.0f);\n    float _451;\n    if (_369_fa_shadow_bias.y > 0.0f)\n    {\n        _451 = _369_fa_shadow_bias.y;\n    }\n    else\n    {\n        _451 = 1.5f * _369_fa_shadow_info[ci].x;\n    }\n    float4 _476 = mul(float4(world + (n * (_451 * _438)), 1.0f), _369_fa_shadow_mat[ci]);\n    float _483 = _476.x;\n    bool _486 = _483 < _369_fa_shadow_rect[ci].x;\n    bool _495;\n    if (!_486)\n    {\n        _495 = _483 > _369_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _495 = _486;\n    }\n    bool _504;\n    if (!_495)\n    {\n        _504 = _476.y < _369_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _504 = _495;\n    }\n    bool _513;\n    if (!_504)\n    {\n        _513 = _476.y > _369_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _513 = _504;\n    }\n    bool _520;\n    if (!_513)\n    {\n        _520 = _476.z > 1.0f;\n    }\n    else\n    {\n        _520 = _513;\n    }\n    if (_520)\n    {\n        return -1.0f;\n    }\n    float _529;\n    if (_369_fa_shadow_bias.x > 0.0f)\n    {\n        _529 = _369_fa_shadow_bias.x;\n    }\n    else\n    {\n        _529 = 1.5f * _369_fa_shadow_info[ci].x;\n    }\n    float _548 = _476.z - ((_529 * (1.0f + (0.5f * _446))) / _427);\n    float _557 = ((_369_fa_shadow_info[ci].x * min(_446, 3.0f)) * 0.5f) / _427;\n    int _566 = int(_369_fa_shadow_cfg.z + 0.5f);\n    if (_566 == 1)\n    {\n        float2 param = _476.xy;\n        float4 param_1 = _369_fa_shadow_rect[ci];\n        float _577 = fa_shadow_depth(param, param_1);\n        return float(_548 <= _577);\n    }\n    float _584 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _587 = _566 == 2;\n    if (_587)\n    {\n        float _601 = clamp(((_369_fa_shadow_cfg.w * _427) * 0.25f) / _369_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _584;\n            float2 _621 = fa_shadow_vogel(param_2, param_3, param_4) * _601;\n            float2 param_5 = _476.xy + (_621 * _369_fa_shadow_bias.zw);\n            float4 param_6 = _369_fa_shadow_rect[ci];\n            float _632 = fa_shadow_depth(param_5, param_6);\n            if (_632 < (_548 - (length(_621) * _557)))\n            {\n                sum += _632;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_548 - (sum / cnt), 0.0f) * _427) * _369_fa_shadow_cfg.w) / _369_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _676 = _587 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _676; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _676;\n        float param_9 = _584;\n        float2 _695 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _476.xy + (_695 * _369_fa_shadow_bias.zw);\n        float4 param_11 = _369_fa_shadow_rect[ci];\n        float _706 = fa_shadow_depth(param_10, param_11);\n        lit += float((_548 - (length(_695) * _557)) <= _706);\n    }\n    return lit / float(_676);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_728_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _739 = int(_369_fa_shadow_cfg.x + 0.5f);\n    if (_739 < 1)\n    {\n        return 1.0f;\n    }\n    float _755 = dot(world - _369_fa_shadow_eye.xyz, _369_fa_shadow_fwd.xyz);\n    int param = _739 - 1;\n    if (_755 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _767 = _739 > 1;\n    bool _774;\n    if (_767)\n    {\n        _774 = _755 > _369_fa_shadow_split.x;\n    }\n    else\n    {\n        _774 = _767;\n    }\n    if (_774)\n    {\n        ci = 1;\n    }\n    bool _778 = _739 > 2;\n    bool _785;\n    if (_778)\n    {\n        _785 = _755 > _369_fa_shadow_split.y;\n    }\n    else\n    {\n        _785 = _778;\n    }\n    if (_785)\n    {\n        ci = 2;\n    }\n    bool _789 = _739 > 3;\n    bool _796;\n    if (_789)\n    {\n        _796 = _755 > _369_fa_shadow_split.z;\n    }\n    else\n    {\n        _796 = _789;\n    }\n    if (_796)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _739)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _822 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _822;\n        if (_822 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_369_fa_shadow_cfg.y > 0.0f)\n    {\n        float _847;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _847 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _847 = _369_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _866 = _369_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _847, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _877 = clamp((_755 - (fa_shadow_split_at(param_7) - _866)) / _866, 0.0f, 1.0f);\n        if (_877 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _739)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _898 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _898;\n                if (_898 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _877);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1194 = fa_light_sample(param, param_1);\n    float3 _2066 = _1194.direction;\n    float3 _2061 = _1194.color;\n    float _2068 = _1194.attenuation;\n    float _2063 = _1194.shadow;\n    int _2071 = _1194.type;\n    if ((_2071 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2066;\n        float _1208 = fa_shadow_factor(param_2, param_3);\n        _2063 = _1208;\n        _2061 = _203_fa_light_color[li].xyz * (_2068 * _1208);\n    }\n    LightSample _2078 = { _2066, _2061, _2068, _2063, _1194._distance, _2071 };\n    return _2078;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1130 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1133 = _1130.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1133 * _1133, exp2((-9.27999973297119140625f) * ndv)) * _1133) + _1130.y)) + _1130.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_728_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _728_fa_env_horizon.w).xyz;\n    }\n    float _1035 = rough * rough;\n    float _1065 = 0.60000002384185791015625f * _1035;\n    return lerp(lerp(_728_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_728_fa_env_horizon.xyz, _728_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1035)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1065, 0.0500000007450580596923828125f + _1065, d.y).xxx), ((_728_fa_env_sky.xyz + _728_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1035 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1172 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1172.x) + _1172.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_369_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _922 = int(_369_fa_shadow_cfg.x + 0.5f);\n    float _932 = dot(world - _369_fa_shadow_eye.xyz, _369_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _937 = _922 > 0;\n    bool _946;\n    if (_937)\n    {\n        int param = _922 - 1;\n        _946 = _932 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _946 = _937;\n    }\n    if (_946)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _953 = _922 > 1;\n        bool _960;\n        if (_953)\n        {\n            _960 = _932 > _369_fa_shadow_split.x;\n        }\n        else\n        {\n            _960 = _953;\n        }\n        if (_960)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _966 = _922 > 2;\n        bool _973;\n        if (_966)\n        {\n            _973 = _932 > _369_fa_shadow_split.y;\n        }\n        else\n        {\n            _973 = _966;\n        }\n        if (_973)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _979 = _922 > 3;\n        bool _986;\n        if (_979)\n        {\n            _986 = _932 > _369_fa_shadow_split.z;\n        }\n        else\n        {\n            _986 = _979;\n        }\n        if (_986)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1986 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1986 = -_1986;\n    }\n    float3 _1520 = normalize(_728_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _1999 = { fa_world_pos, _1986, fa_world_tangent, fa_uv, fa_vertex_color, _1520, gl_FrontFacing };\n    SurfaceInput param = _1999;\n    Surface _1525 = fa_standard_surface(param);\n    float3 _2009 = _1525.albedo;\n    float _2010 = _1525.alpha;\n    float3 _2011 = _1525.normal;\n    float _2012 = _1525.metallic;\n    float _2013 = _1525.roughness;\n    float _2014 = _1525.occlusion;\n    float3 _2015 = _1525.emission;\n    SurfaceInput _2007 = { fa_world_pos, _1986, fa_world_tangent, fa_uv, fa_vertex_color, _1520, gl_FrontFacing };\n    SurfaceInput param_1 = _2007;\n    Surface param_2 = _1525;\n    surface(param_1, param_2);\n    _2009 = param_2.albedo;\n    _2010 = param_2.alpha;\n    _2011 = param_2.normal;\n    _2012 = param_2.metallic;\n    _2013 = param_2.roughness;\n    _2014 = param_2.occlusion;\n    _2015 = param_2.emission;\n    float3 result;\n    if (_728_fa_emissive.w > 0.5f)\n    {\n        result = _2009;\n    }\n    else\n    {\n        float3 _1547 = normalize(_2011);\n        float _1554 = clamp(_2012, 0.0f, 1.0f);\n        float _1558 = clamp(_2013, 0.0500000007450580596923828125f, 1.0f);\n        float _1562 = _1558 * _1558;\n        float _1566 = _1562 * _1562;\n        float _1571 = max(dot(_1547, _1520), 9.9999997473787516355514526367188e-05f);\n        float3 _1577 = _2009 * (1.0f - _1554);\n        float3 _1585 = lerp(0.039999999105930328369140625f.xxx, _2009, _1554.xxx);\n        float3 param_3 = _1547;\n        float3 lit = (fa_ambient_light(param_3) * _1577) * _2014;\n        int _1599 = int(_728_fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1599)\n            {\n                break;\n            }\n            int param_4 = li;\n            float3 param_5 = fa_world_pos;\n            float3 param_6 = _1986;\n            LightSample _1623 = fa_light_shadowed(param_4, param_5, param_6);\n            float3 _2044 = _1623.direction;\n            float _1631 = max(dot(_1547, _2044), 0.0f);\n            float3 _1642 = normalize(_2044 + _1520);\n            float _1647 = max(dot(_1547, _1642), 0.0f);\n            float _1660 = ((_1647 * _1647) * (_1566 - 1.0f)) + 1.0f;\n            lit += (((_1577 + (((_1585 + ((1.0f.xxx - _1585) * pow(1.0f - max(dot(_1520, _1642), 0.0f), 5.0f))) * (((_1566 / ((3.1415927410125732421875f * _1660) * _1660)) * (0.5f / max(lerp((2.0f * _1631) * _1571, _1631 + _1571, _1562), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _1631))) * _203_fa_light_color[li].xyz) * (_1631 * (_1623.attenuation * _1623.shadow)));\n        }\n        float3 param_7 = _1547;\n        float3 param_8 = _1520;\n        float3 param_9 = _1585;\n        float param_10 = _1558;\n        float3 _1730 = lit;\n        float3 _1731 = _1730 + (fa_sky_reflection(param_7, param_8, param_9, param_10) * _2014);\n        lit = _1731;\n        result = _1731;\n    }\n    float3 _1735 = result;\n    float3 _1736 = _1735 + _2015;\n    result = _1736;\n    float3 param_11 = _1736;\n    float3 param_12 = fa_world_pos;\n    result = fa_shadow_debug(param_11, param_12);\n    bool _1745 = _728_fa_fog.w > 0.0f;\n    bool _1753;\n    if (!_1745)\n    {\n        _1753 = _728_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1753 = _1745;\n    }\n    if (_1753)\n    {\n        float3 _1762 = fa_world_pos - _728_fa_camera_pos.xyz;\n        float _1769 = dot(_1762, _728_fa_fog_c.xyz);\n        bool _1773 = _728_fa_fog_c.w > 0.5f;\n        float _1774;\n        if (_1773)\n        {\n            _1774 = _1769;\n        }\n        else\n        {\n            _1774 = length(_1762);\n        }\n        float _1786 = _1774 - _728_fa_fog_b.x;\n        if (_1786 > 0.0f)\n        {\n            float _1795 = _728_fa_fog.w * _1786;\n            float tau = _1795 * _1795;\n            if (_728_fa_fog_b.y > 0.0f)\n            {\n                float _1811;\n                if (_1773)\n                {\n                    _1811 = fa_world_pos.y - (_728_fa_fog_c.y * _1769);\n                }\n                else\n                {\n                    _1811 = _728_fa_camera_pos.y;\n                }\n                float _1832 = lerp(_1811, fa_world_pos.y, clamp(_728_fa_fog_b.x / _1774, 0.0f, 1.0f));\n                float _1836 = fa_world_pos.y - _1832;\n                float _1841 = _1832 - _728_fa_fog_b.z;\n                float _1846 = fa_world_pos.y - _728_fa_fog_b.z;\n                bool _1849 = _1841 <= 0.0f;\n                bool _1850 = !_1849;\n                bool _1856;\n                if (_1850)\n                {\n                    _1856 = _728_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1856 = _1849;\n                }\n                float _1857;\n                if (_1856)\n                {\n                    _1857 = _728_fa_fog_b.y;\n                }\n                else\n                {\n                    _1857 = _728_fa_fog_b.y * exp(-min(_728_fa_fog_b.w * _1841, 80.0f));\n                }\n                bool _1884;\n                if (_1850)\n                {\n                    _1884 = _728_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1884 = _1849;\n                }\n                float _1885;\n                if (_1884)\n                {\n                    _1885 = _728_fa_fog_b.y * _1841;\n                }\n                else\n                {\n                    _1885 = (_728_fa_fog_b.y * (1.0f - exp(-min(_728_fa_fog_b.w * _1841, 80.0f)))) / _728_fa_fog_b.w;\n                }\n                bool _1910 = _1846 <= 0.0f;\n                bool _1917;\n                if (!_1910)\n                {\n                    _1917 = _728_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1917 = _1910;\n                }\n                float _1918;\n                if (_1917)\n                {\n                    _1918 = _728_fa_fog_b.y * _1846;\n                }\n                else\n                {\n                    _1918 = (_728_fa_fog_b.y * (1.0f - exp(-min(_728_fa_fog_b.w * _1846, 80.0f)))) / _728_fa_fog_b.w;\n                }\n                float _1945;\n                if (abs(_1836) < 0.001000000047497451305389404296875f)\n                {\n                    _1945 = _1857;\n                }\n                else\n                {\n                    _1945 = (_1918 - _1885) / _1836;\n                }\n                tau += (_1786 * max(_1945, 0.0f));\n            }\n            result = lerp(result, _728_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2010);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_203",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_369",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_728",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _379 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _379;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_386, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _203_fa_light_pos[32] : packoffset(c0);\n    float4 _203_fa_light_color[32] : packoffset(c32);\n    float4 _203_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _369_fa_shadow_mat[4] : packoffset(c0);\n    float4 _369_fa_shadow_rect[4] : packoffset(c16);\n    float4 _369_fa_shadow_info[4] : packoffset(c20);\n    float4 _369_fa_shadow_split : packoffset(c24);\n    float4 _369_fa_shadow_cfg : packoffset(c25);\n    float4 _369_fa_shadow_bias : packoffset(c26);\n    float4 _369_fa_shadow_eye : packoffset(c27);\n    float4 _369_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _728_fa_camera_pos : packoffset(c0);\n    float4 _728_fa_ambient : packoffset(c1);\n    float4 _728_fa_base_color : packoffset(c2);\n    float4 _728_fa_emissive : packoffset(c3);\n    float4 _728_fa_model_emissive : packoffset(c4);\n    float4 _728_fa_pbr : packoffset(c5);\n    float4 _728_fa_maps : packoffset(c6);\n    float4 _728_fa_fog : packoffset(c7);\n    float4 _728_fa_fog_b : packoffset(c8);\n    float4 _728_fa_fog_c : packoffset(c9);\n    float4 _728_fa_counts : packoffset(c10);\n    float4 _728_fa_env_sky : packoffset(c11);\n    float4 _728_fa_env_horizon : packoffset(c12);\n    float4 _728_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1288 = fa_linear_to_srgb(param);\n        c = _1288;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1296 = fa_srgb_to_linear(param_1);\n            c = _1296;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _131;\n    if (i.front_facing)\n    {\n        _131 = i.world_normal;\n    }\n    else\n    {\n        _131 = -i.world_normal;\n    }\n    float3 _155 = normalize(i.world_tangent.xyz - (_131 * dot(_131, i.world_tangent.xyz)));\n    float3 _183 = normalize(((_155 * m.x) + ((cross(_131, _155) * i.world_tangent.w) * m.y)) + (_131 * m.z));\n    float3 _186;\n    if (i.front_facing)\n    {\n        _186 = _183;\n    }\n    else\n    {\n        _186 = -_183;\n    }\n    return _186;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _728_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1327 = fa_tex_fix(param_2, param_3);\n    float4 _2113 = base_t;\n    _2113.x = _1327.x;\n    _2113.y = _1327.y;\n    _2113.z = _1327.z;\n    base_t = _2113;\n    float4 _1341 = (_2113 * _728_fa_base_color) * i.vertex_color;\n    float3 _2081 = i.world_normal;\n    if (_728_fa_maps.z > 0.5f)\n    {\n        float param_4 = _728_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1373 = fa_tex_fix(param_6, param_7);\n        float3 _1377 = (_1373 * 2.0f) - 1.0f.xxx;\n        float2 _1382 = _1377.xy * _728_fa_maps.x;\n        float3 _2121 = _1377;\n        _2121.x = _1382.x;\n        _2121.y = _1382.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2121;\n        _2081 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _728_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1411 = fa_tex_fix(param_12, param_13);\n    float4 _2124 = mrt;\n    _2124.x = _1411.x;\n    _2124.y = _1411.y;\n    _2124.z = _1411.z;\n    mrt = _2124;\n    float param_14 = _728_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1450 = fa_tex_fix(param_16, param_17);\n    float param_18 = _728_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1477 = fa_tex_fix(param_20, param_21);\n    Surface _2093 = { _1341.xyz, _1341.w, _2081, clamp(_728_fa_pbr.x * _1411.z, 0.0f, 1.0f), clamp(_728_fa_pbr.y * _1411.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_728_fa_maps.y * (_1450.x - 1.0f)), _728_fa_emissive.xyz + (_728_fa_model_emissive.xyz * _1477) };\n    return _2093;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += float3(0.5f + (0.5f * sin(_728_fa_time.x * 3.0f)), 0.25f * frac(_728_fa_time.x), 0.0f);\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_728_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _728_fa_ambient.xyz;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _214 = _203_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_214)\n    {\n        l = normalize(_203_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _232 = _203_fa_light_pos[li].xyz - world_pos;\n        float _234 = length(_232);\n        dist = _234;\n        l = _232 / max(_234, 9.9999997473787516355514526367188e-05f).xxx;\n        float _250 = _234 / max(_203_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _256 = clamp(1.0f - (_250 * _250), 0.0f, 1.0f);\n        atten = _256 * _256;\n        if (_203_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_203_fa_light_dir[li].w, lerp(_203_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_203_fa_light_dir[li].xyz)));\n        }\n    }\n    int _307;\n    if (_214)\n    {\n        _307 = 0;\n    }\n    else\n    {\n        _307 = (_203_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _2059 = { l, _203_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _307 };\n    return _2059;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _359;\n    if (i == 0)\n    {\n        _359 = _369_fa_shadow_split.x;\n    }\n    else\n    {\n        float _375;\n        if (i == 1)\n        {\n            _375 = _369_fa_shadow_split.y;\n        }\n        else\n        {\n            float _383;\n            if (i == 2)\n            {\n                _383 = _369_fa_shadow_split.z;\n            }\n            else\n            {\n                _383 = _369_fa_shadow_split.w;\n            }\n            _375 = _383;\n        }\n        _359 = _375;\n    }\n    return _359;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _347 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_347), sin(_347)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _427 = max(_369_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _432 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _438 = sqrt(1.0f - (_432 * _432));\n    float _446 = min(_438 / max(_432, 0.20000000298023223876953125f), 4.0f);\n    float _451;\n    if (_369_fa_shadow_bias.y > 0.0f)\n    {\n        _451 = _369_fa_shadow_bias.y;\n    }\n    else\n    {\n        _451 = 1.5f * _369_fa_shadow_info[ci].x;\n    }\n    float4 _476 = mul(float4(world + (n * (_451 * _438)), 1.0f), _369_fa_shadow_mat[ci]);\n    float _483 = _476.x;\n    bool _486 = _483 < _369_fa_shadow_rect[ci].x;\n    bool _495;\n    if (!_486)\n    {\n        _495 = _483 > _369_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _495 = _486;\n    }\n    bool _504;\n    if (!_495)\n    {\n        _504 = _476.y < _369_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _504 = _495;\n    }\n    bool _513;\n    if (!_504)\n    {\n        _513 = _476.y > _369_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _513 = _504;\n    }\n    bool _520;\n    if (!_513)\n    {\n        _520 = _476.z > 1.0f;\n    }\n    else\n    {\n        _520 = _513;\n    }\n    if (_520)\n    {\n        return -1.0f;\n    }\n    float _529;\n    if (_369_fa_shadow_bias.x > 0.0f)\n    {\n        _529 = _369_fa_shadow_bias.x;\n    }\n    else\n    {\n        _529 = 1.5f * _369_fa_shadow_info[ci].x;\n    }\n    float _548 = _476.z - ((_529 * (1.0f + (0.5f * _446))) / _427);\n    float _557 = ((_369_fa_shadow_info[ci].x * min(_446, 3.0f)) * 0.5f) / _427;\n    int _566 = int(_369_fa_shadow_cfg.z + 0.5f);\n    if (_566 == 1)\n    {\n        float2 param = _476.xy;\n        float4 param_1 = _369_fa_shadow_rect[ci];\n        float _577 = fa_shadow_depth(param, param_1);\n        return float(_548 <= _577);\n    }\n    float _584 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _587 = _566 == 2;\n    if (_587)\n    {\n        float _601 = clamp(((_369_fa_shadow_cfg.w * _427) * 0.25f) / _369_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _584;\n            float2 _621 = fa_shadow_vogel(param_2, param_3, param_4) * _601;\n            float2 param_5 = _476.xy + (_621 * _369_fa_shadow_bias.zw);\n            float4 param_6 = _369_fa_shadow_rect[ci];\n            float _632 = fa_shadow_depth(param_5, param_6);\n            if (_632 < (_548 - (length(_621) * _557)))\n            {\n                sum += _632;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_548 - (sum / cnt), 0.0f) * _427) * _369_fa_shadow_cfg.w) / _369_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _676 = _587 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _676; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _676;\n        float param_9 = _584;\n        float2 _695 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _476.xy + (_695 * _369_fa_shadow_bias.zw);\n        float4 param_11 = _369_fa_shadow_rect[ci];\n        float _706 = fa_shadow_depth(param_10, param_11);\n        lit += float((_548 - (length(_695) * _557)) <= _706);\n    }\n    return lit / float(_676);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_728_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _739 = int(_369_fa_shadow_cfg.x + 0.5f);\n    if (_739 < 1)\n    {\n        return 1.0f;\n    }\n    float _755 = dot(world - _369_fa_shadow_eye.xyz, _369_fa_shadow_fwd.xyz);\n    int param = _739 - 1;\n    if (_755 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _767 = _739 > 1;\n    bool _774;\n    if (_767)\n    {\n        _774 = _755 > _369_fa_shadow_split.x;\n    }\n    else\n    {\n        _774 = _767;\n    }\n    if (_774)\n    {\n        ci = 1;\n    }\n    bool _778 = _739 > 2;\n    bool _785;\n    if (_778)\n    {\n        _785 = _755 > _369_fa_shadow_split.y;\n    }\n    else\n    {\n        _785 = _778;\n    }\n    if (_785)\n    {\n        ci = 2;\n    }\n    bool _789 = _739 > 3;\n    bool _796;\n    if (_789)\n    {\n        _796 = _755 > _369_fa_shadow_split.z;\n    }\n    else\n    {\n        _796 = _789;\n    }\n    if (_796)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _739)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _822 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _822;\n        if (_822 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_369_fa_shadow_cfg.y > 0.0f)\n    {\n        float _847;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _847 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _847 = _369_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _866 = _369_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _847, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _877 = clamp((_755 - (fa_shadow_split_at(param_7) - _866)) / _866, 0.0f, 1.0f);\n        if (_877 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _739)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _898 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _898;\n                if (_898 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _877);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1194 = fa_light_sample(param, param_1);\n    float3 _2066 = _1194.direction;\n    float3 _2061 = _1194.color;\n    float _2068 = _1194.attenuation;\n    float _2063 = _1194.shadow;\n    int _2071 = _1194.type;\n    if ((_2071 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2066;\n        float _1208 = fa_shadow_factor(param_2, param_3);\n        _2063 = _1208;\n        _2061 = _203_fa_light_color[li].xyz * (_2068 * _1208);\n    }\n    LightSample _2078 = { _2066, _2061, _2068, _2063, _1194._distance, _2071 };\n    return _2078;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1130 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1133 = _1130.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1133 * _1133, exp2((-9.27999973297119140625f) * ndv)) * _1133) + _1130.y)) + _1130.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_728_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _728_fa_env_horizon.w).xyz;\n    }\n    float _1035 = rough * rough;\n    float _1065 = 0.60000002384185791015625f * _1035;\n    return lerp(lerp(_728_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_728_fa_env_horizon.xyz, _728_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1035)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1065, 0.0500000007450580596923828125f + _1065, d.y).xxx), ((_728_fa_env_sky.xyz + _728_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1035 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1172 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1172.x) + _1172.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_369_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _922 = int(_369_fa_shadow_cfg.x + 0.5f);\n    float _932 = dot(world - _369_fa_shadow_eye.xyz, _369_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _937 = _922 > 0;\n    bool _946;\n    if (_937)\n    {\n        int param = _922 - 1;\n        _946 = _932 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _946 = _937;\n    }\n    if (_946)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _953 = _922 > 1;\n        bool _960;\n        if (_953)\n        {\n            _960 = _932 > _369_fa_shadow_split.x;\n        }\n        else\n        {\n            _960 = _953;\n        }\n        if (_960)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _966 = _922 > 2;\n        bool _973;\n        if (_966)\n        {\n            _973 = _932 > _369_fa_shadow_split.y;\n        }\n        else\n        {\n            _973 = _966;\n        }\n        if (_973)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _979 = _922 > 3;\n        bool _986;\n        if (_979)\n        {\n            _986 = _932 > _369_fa_shadow_split.z;\n        }\n        else\n        {\n            _986 = _979;\n        }\n        if (_986)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1986 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1986 = -_1986;\n    }\n    float3 _1520 = normalize(_728_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _1999 = { fa_world_pos, _1986, fa_world_tangent, fa_uv, fa_vertex_color, _1520, gl_FrontFacing };\n    SurfaceInput param = _1999;\n    Surface _1525 = fa_standard_surface(param);\n    float3 _2009 = _1525.albedo;\n    float _2010 = _1525.alpha;\n    float3 _2011 = _1525.normal;\n    float _2012 = _1525.metallic;\n    float _2013 = _1525.roughness;\n    float _2014 = _1525.occlusion;\n    float3 _2015 = _1525.emission;\n    SurfaceInput _2007 = { fa_world_pos, _1986, fa_world_tangent, fa_uv, fa_vertex_color, _1520, gl_FrontFacing };\n    SurfaceInput param_1 = _2007;\n    Surface param_2 = _1525;\n    surface(param_1, param_2);\n    _2009 = param_2.albedo;\n    _2010 = param_2.alpha;\n    _2011 = param_2.normal;\n    _2012 = param_2.metallic;\n    _2013 = param_2.roughness;\n    _2014 = param_2.occlusion;\n    _2015 = param_2.emission;\n    float3 result;\n    if (_728_fa_emissive.w > 0.5f)\n    {\n        result = _2009;\n    }\n    else\n    {\n        float3 _1547 = normalize(_2011);\n        float _1554 = clamp(_2012, 0.0f, 1.0f);\n        float _1558 = clamp(_2013, 0.0500000007450580596923828125f, 1.0f);\n        float _1562 = _1558 * _1558;\n        float _1566 = _1562 * _1562;\n        float _1571 = max(dot(_1547, _1520), 9.9999997473787516355514526367188e-05f);\n        float3 _1577 = _2009 * (1.0f - _1554);\n        float3 _1585 = lerp(0.039999999105930328369140625f.xxx, _2009, _1554.xxx);\n        float3 param_3 = _1547;\n        float3 lit = (fa_ambient_light(param_3) * _1577) * _2014;\n        int _1599 = int(_728_fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1599)\n            {\n                break;\n            }\n            int param_4 = li;\n            float3 param_5 = fa_world_pos;\n            float3 param_6 = _1986;\n            LightSample _1623 = fa_light_shadowed(param_4, param_5, param_6);\n            float3 _2044 = _1623.direction;\n            float _1631 = max(dot(_1547, _2044), 0.0f);\n            float3 _1642 = normalize(_2044 + _1520);\n            float _1647 = max(dot(_1547, _1642), 0.0f);\n            float _1660 = ((_1647 * _1647) * (_1566 - 1.0f)) + 1.0f;\n            lit += (((_1577 + (((_1585 + ((1.0f.xxx - _1585) * pow(1.0f - max(dot(_1520, _1642), 0.0f), 5.0f))) * (((_1566 / ((3.1415927410125732421875f * _1660) * _1660)) * (0.5f / max(lerp((2.0f * _1631) * _1571, _1631 + _1571, _1562), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _1631))) * _203_fa_light_color[li].xyz) * (_1631 * (_1623.attenuation * _1623.shadow)));\n        }\n        float3 param_7 = _1547;\n        float3 param_8 = _1520;\n        float3 param_9 = _1585;\n        float param_10 = _1558;\n        float3 _1730 = lit;\n        float3 _1731 = _1730 + (fa_sky_reflection(param_7, param_8, param_9, param_10) * _2014);\n        lit = _1731;\n        result = _1731;\n    }\n    float3 _1735 = result;\n    float3 _1736 = _1735 + _2015;\n    result = _1736;\n    float3 param_11 = _1736;\n    float3 param_12 = fa_world_pos;\n    result = fa_shadow_debug(param_11, param_12);\n    bool _1745 = _728_fa_fog.w > 0.0f;\n    bool _1753;\n    if (!_1745)\n    {\n        _1753 = _728_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1753 = _1745;\n    }\n    if (_1753)\n    {\n        float3 _1762 = fa_world_pos - _728_fa_camera_pos.xyz;\n        float _1769 = dot(_1762, _728_fa_fog_c.xyz);\n        bool _1773 = _728_fa_fog_c.w > 0.5f;\n        float _1774;\n        if (_1773)\n        {\n            _1774 = _1769;\n        }\n        else\n        {\n            _1774 = length(_1762);\n        }\n        float _1786 = _1774 - _728_fa_fog_b.x;\n        if (_1786 > 0.0f)\n        {\n            float _1795 = _728_fa_fog.w * _1786;\n            float tau = _1795 * _1795;\n            if (_728_fa_fog_b.y > 0.0f)\n            {\n                float _1811;\n                if (_1773)\n                {\n                    _1811 = fa_world_pos.y - (_728_fa_fog_c.y * _1769);\n                }\n                else\n                {\n                    _1811 = _728_fa_camera_pos.y;\n                }\n                float _1832 = lerp(_1811, fa_world_pos.y, clamp(_728_fa_fog_b.x / _1774, 0.0f, 1.0f));\n                float _1836 = fa_world_pos.y - _1832;\n                float _1841 = _1832 - _728_fa_fog_b.z;\n                float _1846 = fa_world_pos.y - _728_fa_fog_b.z;\n                bool _1849 = _1841 <= 0.0f;\n                bool _1850 = !_1849;\n                bool _1856;\n                if (_1850)\n                {\n                    _1856 = _728_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1856 = _1849;\n                }\n                float _1857;\n                if (_1856)\n                {\n                    _1857 = _728_fa_fog_b.y;\n                }\n                else\n                {\n                    _1857 = _728_fa_fog_b.y * exp(-min(_728_fa_fog_b.w * _1841, 80.0f));\n                }\n                bool _1884;\n                if (_1850)\n                {\n                    _1884 = _728_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1884 = _1849;\n                }\n                float _1885;\n                if (_1884)\n                {\n                    _1885 = _728_fa_fog_b.y * _1841;\n                }\n                else\n                {\n                    _1885 = (_728_fa_fog_b.y * (1.0f - exp(-min(_728_fa_fog_b.w * _1841, 80.0f)))) / _728_fa_fog_b.w;\n                }\n                bool _1910 = _1846 <= 0.0f;\n                bool _1917;\n                if (!_1910)\n                {\n                    _1917 = _728_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1917 = _1910;\n                }\n                float _1918;\n                if (_1917)\n                {\n                    _1918 = _728_fa_fog_b.y * _1846;\n                }\n                else\n                {\n                    _1918 = (_728_fa_fog_b.y * (1.0f - exp(-min(_728_fa_fog_b.w * _1846, 80.0f)))) / _728_fa_fog_b.w;\n                }\n                float _1945;\n                if (abs(_1836) < 0.001000000047497451305389404296875f)\n                {\n                    _1945 = _1857;\n                }\n                else\n                {\n                    _1945 = (_1918 - _1885) / _1836;\n                }\n                tau += (_1786 * max(_1945, 0.0f));\n            }\n            result = lerp(result, _728_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2010);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_203",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_369",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_728",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _125_fa_camera_pos : packoffset(c0);\n    float4 _125_fa_ambient : packoffset(c1);\n    float4 _125_fa_base_color : packoffset(c2);\n    float4 _125_fa_emissive : packoffset(c3);\n    float4 _125_fa_model_emissive : packoffset(c4);\n    float4 _125_fa_pbr : packoffset(c5);\n    float4 _125_fa_maps : packoffset(c6);\n    float4 _125_fa_fog : packoffset(c7);\n    float4 _125_fa_fog_b : packoffset(c8);\n    float4 _125_fa_fog_c : packoffset(c9);\n    float4 _125_fa_counts : packoffset(c10);\n    float4 _125_fa_env_sky : packoffset(c11);\n    float4 _125_fa_env_horizon : packoffset(c12);\n    float4 _125_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _195 = fa_linear_to_srgb(param);\n        c = _195;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _203 = fa_srgb_to_linear(param_1);\n            c = _203;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _125_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _243 = fa_tex_fix(param_2, param_3);\n    float4 _604 = base_t;\n    _604.x = _243.x;\n    _604.y = _243.y;\n    _604.z = _243.z;\n    base_t = _604;\n    float4 _259 = (_604 * _125_fa_base_color) * i.vertex_color;\n    float3 _585 = i.world_normal;\n    if (_125_fa_maps.z > 0.5f)\n    {\n        float param_4 = _125_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _293 = fa_tex_fix(param_6, param_7);\n        float3 _297 = (_293 * 2.0f) - 1.0f.xxx;\n        float2 _302 = _297.xy * _125_fa_maps.x;\n        float3 _612 = _297;\n        _612.x = _302.x;\n        _612.y = _302.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _612;\n        _585 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _125_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _331 = fa_tex_fix(param_12, param_13);\n    float4 _615 = mrt;\n    _615.x = _331.x;\n    _615.y = _331.y;\n    _615.z = _331.z;\n    mrt = _615;\n    float param_14 = _125_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _372 = fa_tex_fix(param_16, param_17);\n    float param_18 = _125_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _399 = fa_tex_fix(param_20, param_21);\n    Surface _597 = { _259.xyz, _259.w, _585, clamp(_125_fa_pbr.x * _331.z, 0.0f, 1.0f), clamp(_125_fa_pbr.y * _331.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_125_fa_maps.y * (_372.x - 1.0f)), _125_fa_emissive.xyz + (_125_fa_model_emissive.xyz * _399) };\n    return _597;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += float3(0.5f + (0.5f * sin(_125_fa_time.x * 3.0f)), 0.25f * frac(_125_fa_time.x), 0.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _532 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _532 = -_532;\n    }\n    float3 _445 = normalize(_125_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _545 = { fa_world_pos, _532, fa_world_tangent, fa_uv, fa_vertex_color, _445, gl_FrontFacing };\n    SurfaceInput param = _545;\n    SurfaceInput _553 = { fa_world_pos, _532, fa_world_tangent, fa_uv, fa_vertex_color, _445, gl_FrontFacing };\n    SurfaceInput param_1 = _553;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _460 = normalize(param_2.normal);\n    float3 _475 = normalize(float3(dot(fa_pre_r0, _460), dot(fa_pre_r1, _460), dot(fa_pre_r2, _460)));\n    float _487 = _475.z;\n    float2 e = _475.xy / ((abs(_475.x) + abs(_475.y)) + abs(_487)).xx;\n    if (_487 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 224,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _125_fa_camera_pos : packoffset(c0);\n    float4 _125_fa_ambient : packoffset(c1);\n    float4 _125_fa_base_color : packoffset(c2);\n    float4 _125_fa_emissive : packoffset(c3);\n    float4 _125_fa_model_emissive : packoffset(c4);\n    float4 _125_fa_pbr : packoffset(c5);\n    float4 _125_fa_maps : packoffset(c6);\n    float4 _125_fa_fog : packoffset(c7);\n    float4 _125_fa_fog_b : packoffset(c8);\n    float4 _125_fa_fog_c : packoffset(c9);\n    float4 _125_fa_counts : packoffset(c10);\n    float4 _125_fa_env_sky : packoffset(c11);\n    float4 _125_fa_env_horizon : packoffset(c12);\n    float4 _125_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _195 = fa_linear_to_srgb(param);\n        c = _195;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _203 = fa_srgb_to_linear(param_1);\n            c = _203;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _125_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _243 = fa_tex_fix(param_2, param_3);\n    float4 _604 = base_t;\n    _604.x = _243.x;\n    _604.y = _243.y;\n    _604.z = _243.z;\n    base_t = _604;\n    float4 _259 = (_604 * _125_fa_base_color) * i.vertex_color;\n    float3 _585 = i.world_normal;\n    if (_125_fa_maps.z > 0.5f)\n    {\n        float param_4 = _125_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _293 = fa_tex_fix(param_6, param_7);\n        float3 _297 = (_293 * 2.0f) - 1.0f.xxx;\n        float2 _302 = _297.xy * _125_fa_maps.x;\n        float3 _612 = _297;\n        _612.x = _302.x;\n        _612.y = _302.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _612;\n        _585 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _125_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _331 = fa_tex_fix(param_12, param_13);\n    float4 _615 = mrt;\n    _615.x = _331.x;\n    _615.y = _331.y;\n    _615.z = _331.z;\n    mrt = _615;\n    float param_14 = _125_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _372 = fa_tex_fix(param_16, param_17);\n    float param_18 = _125_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _399 = fa_tex_fix(param_20, param_21);\n    Surface _597 = { _259.xyz, _259.w, _585, clamp(_125_fa_pbr.x * _331.z, 0.0f, 1.0f), clamp(_125_fa_pbr.y * _331.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_125_fa_maps.y * (_372.x - 1.0f)), _125_fa_emissive.xyz + (_125_fa_model_emissive.xyz * _399) };\n    return _597;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += float3(0.5f + (0.5f * sin(_125_fa_time.x * 3.0f)), 0.25f * frac(_125_fa_time.x), 0.0f);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _532 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _532 = -_532;\n    }\n    float3 _445 = normalize(_125_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _545 = { fa_world_pos, _532, fa_world_tangent, fa_uv, fa_vertex_color, _445, gl_FrontFacing };\n    SurfaceInput param = _545;\n    SurfaceInput _553 = { fa_world_pos, _532, fa_world_tangent, fa_uv, fa_vertex_color, _445, gl_FrontFacing };\n    SurfaceInput param_1 = _553;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _460 = normalize(param_2.normal);\n    float3 _475 = normalize(float3(dot(fa_pre_r0, _460), dot(fa_pre_r1, _460), dot(fa_pre_r2, _460)));\n    float _487 = _475.z;\n    float2 e = _475.xy / ((abs(_475.x) + abs(_475.y)) + abs(_487)).xx;\n    if (_487 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 224,
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
