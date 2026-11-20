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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _194_fa_light_pos[32] : packoffset(c0);\n    float4 _194_fa_light_color[32] : packoffset(c32);\n    float4 _194_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _359_fa_shadow_mat[4] : packoffset(c0);\n    float4 _359_fa_shadow_rect[4] : packoffset(c16);\n    float4 _359_fa_shadow_info[4] : packoffset(c20);\n    float4 _359_fa_shadow_split : packoffset(c24);\n    float4 _359_fa_shadow_cfg : packoffset(c25);\n    float4 _359_fa_shadow_bias : packoffset(c26);\n    float4 _359_fa_shadow_eye : packoffset(c27);\n    float4 _359_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _718_fa_camera_pos : packoffset(c0);\n    float4 _718_fa_ambient : packoffset(c1);\n    float4 _718_fa_base_color : packoffset(c2);\n    float4 _718_fa_emissive : packoffset(c3);\n    float4 _718_fa_model_emissive : packoffset(c4);\n    float4 _718_fa_pbr : packoffset(c5);\n    float4 _718_fa_maps : packoffset(c6);\n    float4 _718_fa_fog : packoffset(c7);\n    float4 _718_fa_fog_b : packoffset(c8);\n    float4 _718_fa_fog_c : packoffset(c9);\n    float4 _718_fa_counts : packoffset(c10);\n    float4 _718_fa_env_sky : packoffset(c11);\n    float4 _718_fa_env_horizon : packoffset(c12);\n    float4 _718_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_irr_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1106 = fa_linear_to_srgb(param);\n        c = _1106;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1114 = fa_srgb_to_linear(param_1);\n            c = _1114;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _122;\n    if (i.front_facing)\n    {\n        _122 = i.world_normal;\n    }\n    else\n    {\n        _122 = -i.world_normal;\n    }\n    float3 _146 = normalize(i.world_tangent.xyz - (_122 * dot(_122, i.world_tangent.xyz)));\n    float3 _174 = normalize(((_146 * m.x) + ((cross(_122, _146) * i.world_tangent.w) * m.y)) + (_122 * m.z));\n    float3 _177;\n    if (i.front_facing)\n    {\n        _177 = _174;\n    }\n    else\n    {\n        _177 = -_174;\n    }\n    return _177;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _718_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1145 = fa_tex_fix(param_2, param_3);\n    float4 _1825 = base_t;\n    _1825.x = _1145.x;\n    _1825.y = _1145.y;\n    _1825.z = _1145.z;\n    base_t = _1825;\n    float4 _1159 = (_1825 * _718_fa_base_color) * i.vertex_color;\n    float3 _1799 = i.world_normal;\n    if (_718_fa_maps.z > 0.5f)\n    {\n        float param_4 = _718_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1191 = fa_tex_fix(param_6, param_7);\n        float3 _1195 = (_1191 * 2.0f) - 1.0f.xxx;\n        float2 _1200 = _1195.xy * _718_fa_maps.x;\n        float3 _1833 = _1195;\n        _1833.x = _1200.x;\n        _1833.y = _1200.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1833;\n        _1799 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _718_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1229 = fa_tex_fix(param_12, param_13);\n    float4 _1836 = mrt;\n    _1836.x = _1229.x;\n    _1836.y = _1229.y;\n    _1836.z = _1229.z;\n    mrt = _1836;\n    float param_14 = _718_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1269 = fa_tex_fix(param_16, param_17);\n    float param_18 = _718_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1296 = fa_tex_fix(param_20, param_21);\n    Surface _1811 = { _1159.xyz, _1159.w, _1799, clamp(_718_fa_pbr.x * _1229.z, 0.0f, 1.0f), clamp(_718_fa_pbr.y * _1229.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_718_fa_maps.y * (_1269.x - 1.0f)), _718_fa_emissive.xyz + (_718_fa_model_emissive.xyz * _1296) };\n    return _1811;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_718_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _718_fa_ambient.xyz;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _205 = _194_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_205)\n    {\n        l = normalize(_194_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _223 = _194_fa_light_pos[li].xyz - world_pos;\n        float _225 = length(_223);\n        dist = _225;\n        l = _223 / max(_225, 9.9999997473787516355514526367188e-05f).xxx;\n        float _241 = _225 / max(_194_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _247 = clamp(1.0f - (_241 * _241), 0.0f, 1.0f);\n        atten = _247 * _247;\n        if (_194_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_194_fa_light_dir[li].w, lerp(_194_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_194_fa_light_dir[li].xyz)));\n        }\n    }\n    int _297;\n    if (_205)\n    {\n        _297 = 0;\n    }\n    else\n    {\n        _297 = (_194_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _1777 = { l, _194_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _297 };\n    return _1777;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _349;\n    if (i == 0)\n    {\n        _349 = _359_fa_shadow_split.x;\n    }\n    else\n    {\n        float _365;\n        if (i == 1)\n        {\n            _365 = _359_fa_shadow_split.y;\n        }\n        else\n        {\n            float _373;\n            if (i == 2)\n            {\n                _373 = _359_fa_shadow_split.z;\n            }\n            else\n            {\n                _373 = _359_fa_shadow_split.w;\n            }\n            _365 = _373;\n        }\n        _349 = _365;\n    }\n    return _349;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _337 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_337), sin(_337)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _417 = max(_359_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _422 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _428 = sqrt(1.0f - (_422 * _422));\n    float _436 = min(_428 / max(_422, 0.20000000298023223876953125f), 4.0f);\n    float _441;\n    if (_359_fa_shadow_bias.y > 0.0f)\n    {\n        _441 = _359_fa_shadow_bias.y;\n    }\n    else\n    {\n        _441 = 1.5f * _359_fa_shadow_info[ci].x;\n    }\n    float4 _466 = mul(float4(world + (n * (_441 * _428)), 1.0f), _359_fa_shadow_mat[ci]);\n    float _473 = _466.x;\n    bool _476 = _473 < _359_fa_shadow_rect[ci].x;\n    bool _485;\n    if (!_476)\n    {\n        _485 = _473 > _359_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _485 = _476;\n    }\n    bool _494;\n    if (!_485)\n    {\n        _494 = _466.y < _359_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _494 = _485;\n    }\n    bool _503;\n    if (!_494)\n    {\n        _503 = _466.y > _359_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _503 = _494;\n    }\n    bool _510;\n    if (!_503)\n    {\n        _510 = _466.z > 1.0f;\n    }\n    else\n    {\n        _510 = _503;\n    }\n    if (_510)\n    {\n        return -1.0f;\n    }\n    float _519;\n    if (_359_fa_shadow_bias.x > 0.0f)\n    {\n        _519 = _359_fa_shadow_bias.x;\n    }\n    else\n    {\n        _519 = 1.5f * _359_fa_shadow_info[ci].x;\n    }\n    float _538 = _466.z - ((_519 * (1.0f + (0.5f * _436))) / _417);\n    float _547 = ((_359_fa_shadow_info[ci].x * min(_436, 3.0f)) * 0.5f) / _417;\n    int _556 = int(_359_fa_shadow_cfg.z + 0.5f);\n    if (_556 == 1)\n    {\n        float2 param = _466.xy;\n        float4 param_1 = _359_fa_shadow_rect[ci];\n        float _567 = fa_shadow_depth(param, param_1);\n        return float(_538 <= _567);\n    }\n    float _574 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _577 = _556 == 2;\n    if (_577)\n    {\n        float _591 = clamp(((_359_fa_shadow_cfg.w * _417) * 0.25f) / _359_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _574;\n            float2 _611 = fa_shadow_vogel(param_2, param_3, param_4) * _591;\n            float2 param_5 = _466.xy + (_611 * _359_fa_shadow_bias.zw);\n            float4 param_6 = _359_fa_shadow_rect[ci];\n            float _622 = fa_shadow_depth(param_5, param_6);\n            if (_622 < (_538 - (length(_611) * _547)))\n            {\n                sum += _622;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_538 - (sum / cnt), 0.0f) * _417) * _359_fa_shadow_cfg.w) / _359_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _666 = _577 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _666; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _666;\n        float param_9 = _574;\n        float2 _685 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _466.xy + (_685 * _359_fa_shadow_bias.zw);\n        float4 param_11 = _359_fa_shadow_rect[ci];\n        float _696 = fa_shadow_depth(param_10, param_11);\n        lit += float((_538 - (length(_685) * _547)) <= _696);\n    }\n    return lit / float(_666);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_718_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _729 = int(_359_fa_shadow_cfg.x + 0.5f);\n    if (_729 < 1)\n    {\n        return 1.0f;\n    }\n    float _745 = dot(world - _359_fa_shadow_eye.xyz, _359_fa_shadow_fwd.xyz);\n    int param = _729 - 1;\n    if (_745 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _757 = _729 > 1;\n    bool _764;\n    if (_757)\n    {\n        _764 = _745 > _359_fa_shadow_split.x;\n    }\n    else\n    {\n        _764 = _757;\n    }\n    if (_764)\n    {\n        ci = 1;\n    }\n    bool _768 = _729 > 2;\n    bool _775;\n    if (_768)\n    {\n        _775 = _745 > _359_fa_shadow_split.y;\n    }\n    else\n    {\n        _775 = _768;\n    }\n    if (_775)\n    {\n        ci = 2;\n    }\n    bool _779 = _729 > 3;\n    bool _786;\n    if (_779)\n    {\n        _786 = _745 > _359_fa_shadow_split.z;\n    }\n    else\n    {\n        _786 = _779;\n    }\n    if (_786)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _729)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _812 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _812;\n        if (_812 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_359_fa_shadow_cfg.y > 0.0f)\n    {\n        float _837;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _837 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _837 = _359_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _856 = _359_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _837, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _867 = clamp((_745 - (fa_shadow_split_at(param_7) - _856)) / _856, 0.0f, 1.0f);\n        if (_867 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _729)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _888 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _888;\n                if (_888 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _867);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1026 = fa_light_sample(param, param_1);\n    float3 _1784 = _1026.direction;\n    float3 _1779 = _1026.color;\n    float _1786 = _1026.attenuation;\n    float _1781 = _1026.shadow;\n    int _1789 = _1026.type;\n    if ((_1789 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1784;\n        float _1040 = fa_shadow_factor(param_2, param_3);\n        _1781 = _1040;\n        _1779 = _194_fa_light_color[li].xyz * (_1786 * _1040);\n    }\n    LightSample _1796 = { _1784, _1779, _1786, _1781, _1026._distance, _1789 };\n    return _1796;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_359_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _912 = int(_359_fa_shadow_cfg.x + 0.5f);\n    float _922 = dot(world - _359_fa_shadow_eye.xyz, _359_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _927 = _912 > 0;\n    bool _936;\n    if (_927)\n    {\n        int param = _912 - 1;\n        _936 = _922 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _936 = _927;\n    }\n    if (_936)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _943 = _912 > 1;\n        bool _950;\n        if (_943)\n        {\n            _950 = _922 > _359_fa_shadow_split.x;\n        }\n        else\n        {\n            _950 = _943;\n        }\n        if (_950)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _956 = _912 > 2;\n        bool _963;\n        if (_956)\n        {\n            _963 = _922 > _359_fa_shadow_split.y;\n        }\n        else\n        {\n            _963 = _956;\n        }\n        if (_963)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _969 = _912 > 3;\n        bool _976;\n        if (_969)\n        {\n            _976 = _922 > _359_fa_shadow_split.z;\n        }\n        else\n        {\n            _976 = _969;\n        }\n        if (_976)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1678 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1678 = -_1678;\n    }\n    float3 _1339 = normalize(_718_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _1691 = { fa_world_pos, _1678, fa_world_tangent, fa_uv, fa_vertex_color, _1339, gl_FrontFacing };\n    SurfaceInput param = _1691;\n    Surface _1344 = fa_standard_surface(param);\n    float3 _1709 = _1344.albedo;\n    float _1710 = _1344.alpha;\n    float3 _1711 = _1344.normal;\n    float _1712 = _1344.metallic;\n    float _1713 = _1344.roughness;\n    float _1714 = _1344.occlusion;\n    float3 _1715 = _1344.emission;\n    SurfaceInput _1699 = { fa_world_pos, _1678, fa_world_tangent, fa_uv, fa_vertex_color, _1339, gl_FrontFacing };\n    SurfaceInput param_1 = _1699;\n    Surface param_2 = _1344;\n    surface(param_1, param_2);\n    _1709 = param_2.albedo;\n    _1710 = param_2.alpha;\n    _1711 = param_2.normal;\n    _1712 = param_2.metallic;\n    _1713 = param_2.roughness;\n    _1714 = param_2.occlusion;\n    _1715 = param_2.emission;\n    float3 result;\n    if (_718_fa_emissive.w > 0.5f)\n    {\n        result = _1709;\n    }\n    else\n    {\n        float3 _1365 = _1711;\n        float3 _1366 = normalize(_1365);\n        _1711 = _1366;\n        float3 param_3 = _1366;\n        float3 lit = (fa_ambient_light(param_3) * _1709) * _1714;\n        int _1386 = int(_718_fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1386)\n            {\n                break;\n            }\n            int param_4 = li;\n            float3 param_5 = fa_world_pos;\n            float3 param_6 = _1678;\n            SurfaceInput _1707 = { fa_world_pos, _1678, fa_world_tangent, fa_uv, fa_vertex_color, _1339, gl_FrontFacing };\n            SurfaceInput param_7 = _1707;\n            Surface _1745 = { _1709, _1710, _1711, _1712, _1713, _1714, _1715 };\n            Surface param_8 = _1745;\n            LightSample param_9 = fa_light_shadowed(param_4, param_5, param_6);\n            lit += light(param_7, param_8, param_9);\n        }\n        result = lit;\n    }\n    float3 _1425 = result;\n    float3 _1426 = _1425 + _1715;\n    result = _1426;\n    float3 param_10 = _1426;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _1435 = _718_fa_fog.w > 0.0f;\n    bool _1443;\n    if (!_1435)\n    {\n        _1443 = _718_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1443 = _1435;\n    }\n    if (_1443)\n    {\n        float3 _1452 = fa_world_pos - _718_fa_camera_pos.xyz;\n        float _1459 = dot(_1452, _718_fa_fog_c.xyz);\n        bool _1463 = _718_fa_fog_c.w > 0.5f;\n        float _1464;\n        if (_1463)\n        {\n            _1464 = _1459;\n        }\n        else\n        {\n            _1464 = length(_1452);\n        }\n        float _1476 = _1464 - _718_fa_fog_b.x;\n        if (_1476 > 0.0f)\n        {\n            float _1485 = _718_fa_fog.w * _1476;\n            float tau = _1485 * _1485;\n            if (_718_fa_fog_b.y > 0.0f)\n            {\n                float _1501;\n                if (_1463)\n                {\n                    _1501 = fa_world_pos.y - (_718_fa_fog_c.y * _1459);\n                }\n                else\n                {\n                    _1501 = _718_fa_camera_pos.y;\n                }\n                float _1522 = lerp(_1501, fa_world_pos.y, clamp(_718_fa_fog_b.x / _1464, 0.0f, 1.0f));\n                float _1526 = fa_world_pos.y - _1522;\n                float _1531 = _1522 - _718_fa_fog_b.z;\n                float _1536 = fa_world_pos.y - _718_fa_fog_b.z;\n                bool _1539 = _1531 <= 0.0f;\n                bool _1540 = !_1539;\n                bool _1546;\n                if (_1540)\n                {\n                    _1546 = _718_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1546 = _1539;\n                }\n                float _1547;\n                if (_1546)\n                {\n                    _1547 = _718_fa_fog_b.y;\n                }\n                else\n                {\n                    _1547 = _718_fa_fog_b.y * exp(-min(_718_fa_fog_b.w * _1531, 80.0f));\n                }\n                bool _1574;\n                if (_1540)\n                {\n                    _1574 = _718_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1574 = _1539;\n                }\n                float _1575;\n                if (_1574)\n                {\n                    _1575 = _718_fa_fog_b.y * _1531;\n                }\n                else\n                {\n                    _1575 = (_718_fa_fog_b.y * (1.0f - exp(-min(_718_fa_fog_b.w * _1531, 80.0f)))) / _718_fa_fog_b.w;\n                }\n                bool _1600 = _1536 <= 0.0f;\n                bool _1607;\n                if (!_1600)\n                {\n                    _1607 = _718_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1607 = _1600;\n                }\n                float _1608;\n                if (_1607)\n                {\n                    _1608 = _718_fa_fog_b.y * _1536;\n                }\n                else\n                {\n                    _1608 = (_718_fa_fog_b.y * (1.0f - exp(-min(_718_fa_fog_b.w * _1536, 80.0f)))) / _718_fa_fog_b.w;\n                }\n                float _1635;\n                if (abs(_1526) < 0.001000000047497451305389404296875f)\n                {\n                    _1635 = _1547;\n                }\n                else\n                {\n                    _1635 = (_1608 - _1575) / _1526;\n                }\n                tau += (_1476 * max(_1635, 0.0f));\n            }\n            result = lerp(result, _718_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1710);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_194",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_359",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_718",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _379 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _379;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_386, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _194_fa_light_pos[32] : packoffset(c0);\n    float4 _194_fa_light_color[32] : packoffset(c32);\n    float4 _194_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _359_fa_shadow_mat[4] : packoffset(c0);\n    float4 _359_fa_shadow_rect[4] : packoffset(c16);\n    float4 _359_fa_shadow_info[4] : packoffset(c20);\n    float4 _359_fa_shadow_split : packoffset(c24);\n    float4 _359_fa_shadow_cfg : packoffset(c25);\n    float4 _359_fa_shadow_bias : packoffset(c26);\n    float4 _359_fa_shadow_eye : packoffset(c27);\n    float4 _359_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _718_fa_camera_pos : packoffset(c0);\n    float4 _718_fa_ambient : packoffset(c1);\n    float4 _718_fa_base_color : packoffset(c2);\n    float4 _718_fa_emissive : packoffset(c3);\n    float4 _718_fa_model_emissive : packoffset(c4);\n    float4 _718_fa_pbr : packoffset(c5);\n    float4 _718_fa_maps : packoffset(c6);\n    float4 _718_fa_fog : packoffset(c7);\n    float4 _718_fa_fog_b : packoffset(c8);\n    float4 _718_fa_fog_c : packoffset(c9);\n    float4 _718_fa_counts : packoffset(c10);\n    float4 _718_fa_env_sky : packoffset(c11);\n    float4 _718_fa_env_horizon : packoffset(c12);\n    float4 _718_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_irr_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1106 = fa_linear_to_srgb(param);\n        c = _1106;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1114 = fa_srgb_to_linear(param_1);\n            c = _1114;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _122;\n    if (i.front_facing)\n    {\n        _122 = i.world_normal;\n    }\n    else\n    {\n        _122 = -i.world_normal;\n    }\n    float3 _146 = normalize(i.world_tangent.xyz - (_122 * dot(_122, i.world_tangent.xyz)));\n    float3 _174 = normalize(((_146 * m.x) + ((cross(_122, _146) * i.world_tangent.w) * m.y)) + (_122 * m.z));\n    float3 _177;\n    if (i.front_facing)\n    {\n        _177 = _174;\n    }\n    else\n    {\n        _177 = -_174;\n    }\n    return _177;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _718_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1145 = fa_tex_fix(param_2, param_3);\n    float4 _1825 = base_t;\n    _1825.x = _1145.x;\n    _1825.y = _1145.y;\n    _1825.z = _1145.z;\n    base_t = _1825;\n    float4 _1159 = (_1825 * _718_fa_base_color) * i.vertex_color;\n    float3 _1799 = i.world_normal;\n    if (_718_fa_maps.z > 0.5f)\n    {\n        float param_4 = _718_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1191 = fa_tex_fix(param_6, param_7);\n        float3 _1195 = (_1191 * 2.0f) - 1.0f.xxx;\n        float2 _1200 = _1195.xy * _718_fa_maps.x;\n        float3 _1833 = _1195;\n        _1833.x = _1200.x;\n        _1833.y = _1200.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1833;\n        _1799 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _718_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1229 = fa_tex_fix(param_12, param_13);\n    float4 _1836 = mrt;\n    _1836.x = _1229.x;\n    _1836.y = _1229.y;\n    _1836.z = _1229.z;\n    mrt = _1836;\n    float param_14 = _718_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1269 = fa_tex_fix(param_16, param_17);\n    float param_18 = _718_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1296 = fa_tex_fix(param_20, param_21);\n    Surface _1811 = { _1159.xyz, _1159.w, _1799, clamp(_718_fa_pbr.x * _1229.z, 0.0f, 1.0f), clamp(_718_fa_pbr.y * _1229.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_718_fa_maps.y * (_1269.x - 1.0f)), _718_fa_emissive.xyz + (_718_fa_model_emissive.xyz * _1296) };\n    return _1811;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_718_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _718_fa_ambient.xyz;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _205 = _194_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_205)\n    {\n        l = normalize(_194_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _223 = _194_fa_light_pos[li].xyz - world_pos;\n        float _225 = length(_223);\n        dist = _225;\n        l = _223 / max(_225, 9.9999997473787516355514526367188e-05f).xxx;\n        float _241 = _225 / max(_194_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _247 = clamp(1.0f - (_241 * _241), 0.0f, 1.0f);\n        atten = _247 * _247;\n        if (_194_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_194_fa_light_dir[li].w, lerp(_194_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_194_fa_light_dir[li].xyz)));\n        }\n    }\n    int _297;\n    if (_205)\n    {\n        _297 = 0;\n    }\n    else\n    {\n        _297 = (_194_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _1777 = { l, _194_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _297 };\n    return _1777;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _349;\n    if (i == 0)\n    {\n        _349 = _359_fa_shadow_split.x;\n    }\n    else\n    {\n        float _365;\n        if (i == 1)\n        {\n            _365 = _359_fa_shadow_split.y;\n        }\n        else\n        {\n            float _373;\n            if (i == 2)\n            {\n                _373 = _359_fa_shadow_split.z;\n            }\n            else\n            {\n                _373 = _359_fa_shadow_split.w;\n            }\n            _365 = _373;\n        }\n        _349 = _365;\n    }\n    return _349;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _337 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_337), sin(_337)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _417 = max(_359_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _422 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _428 = sqrt(1.0f - (_422 * _422));\n    float _436 = min(_428 / max(_422, 0.20000000298023223876953125f), 4.0f);\n    float _441;\n    if (_359_fa_shadow_bias.y > 0.0f)\n    {\n        _441 = _359_fa_shadow_bias.y;\n    }\n    else\n    {\n        _441 = 1.5f * _359_fa_shadow_info[ci].x;\n    }\n    float4 _466 = mul(float4(world + (n * (_441 * _428)), 1.0f), _359_fa_shadow_mat[ci]);\n    float _473 = _466.x;\n    bool _476 = _473 < _359_fa_shadow_rect[ci].x;\n    bool _485;\n    if (!_476)\n    {\n        _485 = _473 > _359_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _485 = _476;\n    }\n    bool _494;\n    if (!_485)\n    {\n        _494 = _466.y < _359_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _494 = _485;\n    }\n    bool _503;\n    if (!_494)\n    {\n        _503 = _466.y > _359_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _503 = _494;\n    }\n    bool _510;\n    if (!_503)\n    {\n        _510 = _466.z > 1.0f;\n    }\n    else\n    {\n        _510 = _503;\n    }\n    if (_510)\n    {\n        return -1.0f;\n    }\n    float _519;\n    if (_359_fa_shadow_bias.x > 0.0f)\n    {\n        _519 = _359_fa_shadow_bias.x;\n    }\n    else\n    {\n        _519 = 1.5f * _359_fa_shadow_info[ci].x;\n    }\n    float _538 = _466.z - ((_519 * (1.0f + (0.5f * _436))) / _417);\n    float _547 = ((_359_fa_shadow_info[ci].x * min(_436, 3.0f)) * 0.5f) / _417;\n    int _556 = int(_359_fa_shadow_cfg.z + 0.5f);\n    if (_556 == 1)\n    {\n        float2 param = _466.xy;\n        float4 param_1 = _359_fa_shadow_rect[ci];\n        float _567 = fa_shadow_depth(param, param_1);\n        return float(_538 <= _567);\n    }\n    float _574 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _577 = _556 == 2;\n    if (_577)\n    {\n        float _591 = clamp(((_359_fa_shadow_cfg.w * _417) * 0.25f) / _359_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _574;\n            float2 _611 = fa_shadow_vogel(param_2, param_3, param_4) * _591;\n            float2 param_5 = _466.xy + (_611 * _359_fa_shadow_bias.zw);\n            float4 param_6 = _359_fa_shadow_rect[ci];\n            float _622 = fa_shadow_depth(param_5, param_6);\n            if (_622 < (_538 - (length(_611) * _547)))\n            {\n                sum += _622;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_538 - (sum / cnt), 0.0f) * _417) * _359_fa_shadow_cfg.w) / _359_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _666 = _577 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _666; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _666;\n        float param_9 = _574;\n        float2 _685 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _466.xy + (_685 * _359_fa_shadow_bias.zw);\n        float4 param_11 = _359_fa_shadow_rect[ci];\n        float _696 = fa_shadow_depth(param_10, param_11);\n        lit += float((_538 - (length(_685) * _547)) <= _696);\n    }\n    return lit / float(_666);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_718_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _729 = int(_359_fa_shadow_cfg.x + 0.5f);\n    if (_729 < 1)\n    {\n        return 1.0f;\n    }\n    float _745 = dot(world - _359_fa_shadow_eye.xyz, _359_fa_shadow_fwd.xyz);\n    int param = _729 - 1;\n    if (_745 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _757 = _729 > 1;\n    bool _764;\n    if (_757)\n    {\n        _764 = _745 > _359_fa_shadow_split.x;\n    }\n    else\n    {\n        _764 = _757;\n    }\n    if (_764)\n    {\n        ci = 1;\n    }\n    bool _768 = _729 > 2;\n    bool _775;\n    if (_768)\n    {\n        _775 = _745 > _359_fa_shadow_split.y;\n    }\n    else\n    {\n        _775 = _768;\n    }\n    if (_775)\n    {\n        ci = 2;\n    }\n    bool _779 = _729 > 3;\n    bool _786;\n    if (_779)\n    {\n        _786 = _745 > _359_fa_shadow_split.z;\n    }\n    else\n    {\n        _786 = _779;\n    }\n    if (_786)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _729)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _812 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _812;\n        if (_812 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_359_fa_shadow_cfg.y > 0.0f)\n    {\n        float _837;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _837 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _837 = _359_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _856 = _359_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _837, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _867 = clamp((_745 - (fa_shadow_split_at(param_7) - _856)) / _856, 0.0f, 1.0f);\n        if (_867 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _729)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _888 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _888;\n                if (_888 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _867);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1026 = fa_light_sample(param, param_1);\n    float3 _1784 = _1026.direction;\n    float3 _1779 = _1026.color;\n    float _1786 = _1026.attenuation;\n    float _1781 = _1026.shadow;\n    int _1789 = _1026.type;\n    if ((_1789 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1784;\n        float _1040 = fa_shadow_factor(param_2, param_3);\n        _1781 = _1040;\n        _1779 = _194_fa_light_color[li].xyz * (_1786 * _1040);\n    }\n    LightSample _1796 = { _1784, _1779, _1786, _1781, _1026._distance, _1789 };\n    return _1796;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_359_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _912 = int(_359_fa_shadow_cfg.x + 0.5f);\n    float _922 = dot(world - _359_fa_shadow_eye.xyz, _359_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _927 = _912 > 0;\n    bool _936;\n    if (_927)\n    {\n        int param = _912 - 1;\n        _936 = _922 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _936 = _927;\n    }\n    if (_936)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _943 = _912 > 1;\n        bool _950;\n        if (_943)\n        {\n            _950 = _922 > _359_fa_shadow_split.x;\n        }\n        else\n        {\n            _950 = _943;\n        }\n        if (_950)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _956 = _912 > 2;\n        bool _963;\n        if (_956)\n        {\n            _963 = _922 > _359_fa_shadow_split.y;\n        }\n        else\n        {\n            _963 = _956;\n        }\n        if (_963)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _969 = _912 > 3;\n        bool _976;\n        if (_969)\n        {\n            _976 = _922 > _359_fa_shadow_split.z;\n        }\n        else\n        {\n            _976 = _969;\n        }\n        if (_976)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1678 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1678 = -_1678;\n    }\n    float3 _1339 = normalize(_718_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _1691 = { fa_world_pos, _1678, fa_world_tangent, fa_uv, fa_vertex_color, _1339, gl_FrontFacing };\n    SurfaceInput param = _1691;\n    Surface _1344 = fa_standard_surface(param);\n    float3 _1709 = _1344.albedo;\n    float _1710 = _1344.alpha;\n    float3 _1711 = _1344.normal;\n    float _1712 = _1344.metallic;\n    float _1713 = _1344.roughness;\n    float _1714 = _1344.occlusion;\n    float3 _1715 = _1344.emission;\n    SurfaceInput _1699 = { fa_world_pos, _1678, fa_world_tangent, fa_uv, fa_vertex_color, _1339, gl_FrontFacing };\n    SurfaceInput param_1 = _1699;\n    Surface param_2 = _1344;\n    surface(param_1, param_2);\n    _1709 = param_2.albedo;\n    _1710 = param_2.alpha;\n    _1711 = param_2.normal;\n    _1712 = param_2.metallic;\n    _1713 = param_2.roughness;\n    _1714 = param_2.occlusion;\n    _1715 = param_2.emission;\n    float3 result;\n    if (_718_fa_emissive.w > 0.5f)\n    {\n        result = _1709;\n    }\n    else\n    {\n        float3 _1365 = _1711;\n        float3 _1366 = normalize(_1365);\n        _1711 = _1366;\n        float3 param_3 = _1366;\n        float3 lit = (fa_ambient_light(param_3) * _1709) * _1714;\n        int _1386 = int(_718_fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1386)\n            {\n                break;\n            }\n            int param_4 = li;\n            float3 param_5 = fa_world_pos;\n            float3 param_6 = _1678;\n            SurfaceInput _1707 = { fa_world_pos, _1678, fa_world_tangent, fa_uv, fa_vertex_color, _1339, gl_FrontFacing };\n            SurfaceInput param_7 = _1707;\n            Surface _1745 = { _1709, _1710, _1711, _1712, _1713, _1714, _1715 };\n            Surface param_8 = _1745;\n            LightSample param_9 = fa_light_shadowed(param_4, param_5, param_6);\n            lit += light(param_7, param_8, param_9);\n        }\n        result = lit;\n    }\n    float3 _1425 = result;\n    float3 _1426 = _1425 + _1715;\n    result = _1426;\n    float3 param_10 = _1426;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _1435 = _718_fa_fog.w > 0.0f;\n    bool _1443;\n    if (!_1435)\n    {\n        _1443 = _718_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1443 = _1435;\n    }\n    if (_1443)\n    {\n        float3 _1452 = fa_world_pos - _718_fa_camera_pos.xyz;\n        float _1459 = dot(_1452, _718_fa_fog_c.xyz);\n        bool _1463 = _718_fa_fog_c.w > 0.5f;\n        float _1464;\n        if (_1463)\n        {\n            _1464 = _1459;\n        }\n        else\n        {\n            _1464 = length(_1452);\n        }\n        float _1476 = _1464 - _718_fa_fog_b.x;\n        if (_1476 > 0.0f)\n        {\n            float _1485 = _718_fa_fog.w * _1476;\n            float tau = _1485 * _1485;\n            if (_718_fa_fog_b.y > 0.0f)\n            {\n                float _1501;\n                if (_1463)\n                {\n                    _1501 = fa_world_pos.y - (_718_fa_fog_c.y * _1459);\n                }\n                else\n                {\n                    _1501 = _718_fa_camera_pos.y;\n                }\n                float _1522 = lerp(_1501, fa_world_pos.y, clamp(_718_fa_fog_b.x / _1464, 0.0f, 1.0f));\n                float _1526 = fa_world_pos.y - _1522;\n                float _1531 = _1522 - _718_fa_fog_b.z;\n                float _1536 = fa_world_pos.y - _718_fa_fog_b.z;\n                bool _1539 = _1531 <= 0.0f;\n                bool _1540 = !_1539;\n                bool _1546;\n                if (_1540)\n                {\n                    _1546 = _718_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1546 = _1539;\n                }\n                float _1547;\n                if (_1546)\n                {\n                    _1547 = _718_fa_fog_b.y;\n                }\n                else\n                {\n                    _1547 = _718_fa_fog_b.y * exp(-min(_718_fa_fog_b.w * _1531, 80.0f));\n                }\n                bool _1574;\n                if (_1540)\n                {\n                    _1574 = _718_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1574 = _1539;\n                }\n                float _1575;\n                if (_1574)\n                {\n                    _1575 = _718_fa_fog_b.y * _1531;\n                }\n                else\n                {\n                    _1575 = (_718_fa_fog_b.y * (1.0f - exp(-min(_718_fa_fog_b.w * _1531, 80.0f)))) / _718_fa_fog_b.w;\n                }\n                bool _1600 = _1536 <= 0.0f;\n                bool _1607;\n                if (!_1600)\n                {\n                    _1607 = _718_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1607 = _1600;\n                }\n                float _1608;\n                if (_1607)\n                {\n                    _1608 = _718_fa_fog_b.y * _1536;\n                }\n                else\n                {\n                    _1608 = (_718_fa_fog_b.y * (1.0f - exp(-min(_718_fa_fog_b.w * _1536, 80.0f)))) / _718_fa_fog_b.w;\n                }\n                float _1635;\n                if (abs(_1526) < 0.001000000047497451305389404296875f)\n                {\n                    _1635 = _1547;\n                }\n                else\n                {\n                    _1635 = (_1608 - _1575) / _1526;\n                }\n                tau += (_1476 * max(_1635, 0.0f));\n            }\n            result = lerp(result, _718_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1710);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_194",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_359",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_718",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _586 = base_t;\n    _586.x = _225.x;\n    _586.y = _225.y;\n    _586.z = _225.z;\n    base_t = _586;\n    float4 _241 = (_586 * _213_fa_base_color) * i.vertex_color;\n    float3 _567 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _594 = _279;\n        _594.x = _284.x;\n        _594.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _594;\n        _567 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _597 = mrt;\n    _597.x = _313.x;\n    _597.y = _313.y;\n    _597.z = _313.z;\n    mrt = _597;\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    Surface _579 = { _241.xyz, _241.w, _567, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_354.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _381) };\n    return _579;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _514 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _514 = -_514;\n    }\n    float3 _427 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _527 = { fa_world_pos, _514, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param = _527;\n    SurfaceInput _535 = { fa_world_pos, _514, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param_1 = _535;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _442 = normalize(param_2.normal);\n    float3 _457 = normalize(float3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / ((abs(_457.x) + abs(_457.y)) + abs(_469)).xx;\n    if (_469 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _586 = base_t;\n    _586.x = _225.x;\n    _586.y = _225.y;\n    _586.z = _225.z;\n    base_t = _586;\n    float4 _241 = (_586 * _213_fa_base_color) * i.vertex_color;\n    float3 _567 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _594 = _279;\n        _594.x = _284.x;\n        _594.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _594;\n        _567 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _597 = mrt;\n    _597.x = _313.x;\n    _597.y = _313.y;\n    _597.z = _313.z;\n    mrt = _597;\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    Surface _579 = { _241.xyz, _241.w, _567, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_354.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _381) };\n    return _579;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _514 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _514 = -_514;\n    }\n    float3 _427 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _527 = { fa_world_pos, _514, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param = _527;\n    SurfaceInput _535 = { fa_world_pos, _514, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param_1 = _535;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _442 = normalize(param_2.normal);\n    float3 _457 = normalize(float3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / ((abs(_457.x) + abs(_457.y)) + abs(_469)).xx;\n    if (_469 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
