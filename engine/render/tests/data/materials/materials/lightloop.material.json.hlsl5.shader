{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b612c93917ef2f2ca09ed7d7ebb5d582b3c039f51369a75c84a9a8e9083bd53a",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _261 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _261;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_268, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstatic const LightSample _2169 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _224_fa_light_pos[32] : packoffset(c0);\n    float4 _224_fa_light_color[32] : packoffset(c32);\n    float4 _224_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _390_fa_shadow_mat[4] : packoffset(c0);\n    float4 _390_fa_shadow_rect[4] : packoffset(c16);\n    float4 _390_fa_shadow_info[4] : packoffset(c20);\n    float4 _390_fa_shadow_split : packoffset(c24);\n    float4 _390_fa_shadow_cfg : packoffset(c25);\n    float4 _390_fa_shadow_bias : packoffset(c26);\n    float4 _390_fa_shadow_eye : packoffset(c27);\n    float4 _390_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _749_fa_camera_pos : packoffset(c0);\n    float4 _749_fa_ambient : packoffset(c1);\n    float4 _749_fa_base_color : packoffset(c2);\n    float4 _749_fa_emissive : packoffset(c3);\n    float4 _749_fa_model_emissive : packoffset(c4);\n    float4 _749_fa_pbr : packoffset(c5);\n    float4 _749_fa_maps : packoffset(c6);\n    float4 _749_fa_fog : packoffset(c7);\n    float4 _749_fa_fog_b : packoffset(c8);\n    float4 _749_fa_fog_c : packoffset(c9);\n    float4 _749_fa_counts : packoffset(c10);\n    float4 _749_fa_env_sky : packoffset(c11);\n    float4 _749_fa_env_horizon : packoffset(c12);\n    float4 _749_fa_time : packoffset(c13);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _1393_dark : packoffset(c0);\n    float _1393_fa_pad0 : packoffset(c0.y);\n    float _1393_fa_pad1 : packoffset(c0.z);\n    float _1393_fa_pad2 : packoffset(c0.w);\n    float _1393_skyAmount : packoffset(c1);\n    float _1393_fa_pad3 : packoffset(c1.y);\n    float _1393_fa_pad4 : packoffset(c1.z);\n    float _1393_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1465 = fa_linear_to_srgb(param);\n        c = _1465;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1473 = fa_srgb_to_linear(param_1);\n            c = _1473;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _152;\n    if (i.front_facing)\n    {\n        _152 = i.world_normal;\n    }\n    else\n    {\n        _152 = -i.world_normal;\n    }\n    float3 _176 = normalize(i.world_tangent.xyz - (_152 * dot(_152, i.world_tangent.xyz)));\n    float3 _204 = normalize(((_176 * m.x) + ((cross(_152, _176) * i.world_tangent.w) * m.y)) + (_152 * m.z));\n    float3 _207;\n    if (i.front_facing)\n    {\n        _207 = _204;\n    }\n    else\n    {\n        _207 = -_204;\n    }\n    return _207;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _749_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1504 = fa_tex_fix(param_2, param_3);\n    float4 _2148 = base_t;\n    _2148.x = _1504.x;\n    _2148.y = _1504.y;\n    _2148.z = _1504.z;\n    base_t = _2148;\n    float4 _1518 = (_2148 * _749_fa_base_color) * i.vertex_color;\n    float3 _2116 = i.world_normal;\n    if (_749_fa_maps.z > 0.5f)\n    {\n        float param_4 = _749_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1550 = fa_tex_fix(param_6, param_7);\n        float3 _1554 = (_1550 * 2.0f) - 1.0f.xxx;\n        float2 _1559 = _1554.xy * _749_fa_maps.x;\n        float3 _2156 = _1554;\n        _2156.x = _1559.x;\n        _2156.y = _1559.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2156;\n        _2116 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _749_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1588 = fa_tex_fix(param_12, param_13);\n    float4 _2159 = mrt;\n    _2159.x = _1588.x;\n    _2159.y = _1588.y;\n    _2159.z = _1588.z;\n    mrt = _2159;\n    float param_14 = _749_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1627 = fa_tex_fix(param_16, param_17);\n    float param_18 = _749_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1654 = fa_tex_fix(param_20, param_21);\n    Surface _2128 = { _1518.xyz, _1518.w, _2116, clamp(_749_fa_pbr.x * _1588.z, 0.0f, 1.0f), clamp(_749_fa_pbr.y * _1588.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_749_fa_maps.y * (_1627.x - 1.0f)), _749_fa_emissive.xyz + (_749_fa_model_emissive.xyz * _1654) };\n    return _2128;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return min(int(_749_fa_counts.x), 32);\n}\n\nLightSample fa_no_light()\n{\n    return _2169;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _235 = _224_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_235)\n    {\n        l = normalize(_224_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _253 = _224_fa_light_pos[li].xyz - world_pos;\n        float _255 = length(_253);\n        dist = _255;\n        l = _253 / max(_255, 9.9999997473787516355514526367188e-05f).xxx;\n        float _271 = _255 / max(_224_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _277 = clamp(1.0f - (_271 * _271), 0.0f, 1.0f);\n        atten = _277 * _277;\n        if (_224_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_224_fa_light_dir[li].w, lerp(_224_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_224_fa_light_dir[li].xyz)));\n        }\n    }\n    int _328;\n    if (_235)\n    {\n        _328 = 0;\n    }\n    else\n    {\n        _328 = (_224_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _2072 = { l, _224_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _328 };\n    return _2072;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _1305 = n < 0;\n    bool _1312;\n    if (!_1305)\n    {\n        _1312 = n >= fa_light_count();\n    }\n    else\n    {\n        _1312 = _1305;\n    }\n    if (_1312)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    float3 param_1 = i.world_pos;\n    return fa_light_sample(param, param_1);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _380;\n    if (i == 0)\n    {\n        _380 = _390_fa_shadow_split.x;\n    }\n    else\n    {\n        float _396;\n        if (i == 1)\n        {\n            _396 = _390_fa_shadow_split.y;\n        }\n        else\n        {\n            float _404;\n            if (i == 2)\n            {\n                _404 = _390_fa_shadow_split.z;\n            }\n            else\n            {\n                _404 = _390_fa_shadow_split.w;\n            }\n            _396 = _404;\n        }\n        _380 = _396;\n    }\n    return _380;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _368 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_368), sin(_368)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _448 = max(_390_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _453 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _459 = sqrt(1.0f - (_453 * _453));\n    float _467 = min(_459 / max(_453, 0.20000000298023223876953125f), 4.0f);\n    float _472;\n    if (_390_fa_shadow_bias.y > 0.0f)\n    {\n        _472 = _390_fa_shadow_bias.y;\n    }\n    else\n    {\n        _472 = 1.5f * _390_fa_shadow_info[ci].x;\n    }\n    float4 _497 = mul(float4(world + (n * (_472 * _459)), 1.0f), _390_fa_shadow_mat[ci]);\n    float _504 = _497.x;\n    bool _507 = _504 < _390_fa_shadow_rect[ci].x;\n    bool _516;\n    if (!_507)\n    {\n        _516 = _504 > _390_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _516 = _507;\n    }\n    bool _525;\n    if (!_516)\n    {\n        _525 = _497.y < _390_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _525 = _516;\n    }\n    bool _534;\n    if (!_525)\n    {\n        _534 = _497.y > _390_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _534 = _525;\n    }\n    bool _541;\n    if (!_534)\n    {\n        _541 = _497.z > 1.0f;\n    }\n    else\n    {\n        _541 = _534;\n    }\n    if (_541)\n    {\n        return -1.0f;\n    }\n    float _550;\n    if (_390_fa_shadow_bias.x > 0.0f)\n    {\n        _550 = _390_fa_shadow_bias.x;\n    }\n    else\n    {\n        _550 = 1.5f * _390_fa_shadow_info[ci].x;\n    }\n    float _569 = _497.z - ((_550 * (1.0f + (0.5f * _467))) / _448);\n    float _578 = ((_390_fa_shadow_info[ci].x * min(_467, 3.0f)) * 0.5f) / _448;\n    int _587 = int(_390_fa_shadow_cfg.z + 0.5f);\n    if (_587 == 1)\n    {\n        float2 param = _497.xy;\n        float4 param_1 = _390_fa_shadow_rect[ci];\n        float _598 = fa_shadow_depth(param, param_1);\n        return float(_569 <= _598);\n    }\n    float _605 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _608 = _587 == 2;\n    if (_608)\n    {\n        float _622 = clamp(((_390_fa_shadow_cfg.w * _448) * 0.25f) / _390_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _605;\n            float2 _642 = fa_shadow_vogel(param_2, param_3, param_4) * _622;\n            float2 param_5 = _497.xy + (_642 * _390_fa_shadow_bias.zw);\n            float4 param_6 = _390_fa_shadow_rect[ci];\n            float _653 = fa_shadow_depth(param_5, param_6);\n            if (_653 < (_569 - (length(_642) * _578)))\n            {\n                sum += _653;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_569 - (sum / cnt), 0.0f) * _448) * _390_fa_shadow_cfg.w) / _390_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _697 = _608 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _697; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _697;\n        float param_9 = _605;\n        float2 _716 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _497.xy + (_716 * _390_fa_shadow_bias.zw);\n        float4 param_11 = _390_fa_shadow_rect[ci];\n        float _727 = fa_shadow_depth(param_10, param_11);\n        lit += float((_569 - (length(_716) * _578)) <= _727);\n    }\n    return lit / float(_697);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_749_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _760 = int(_390_fa_shadow_cfg.x + 0.5f);\n    if (_760 < 1)\n    {\n        return 1.0f;\n    }\n    float _776 = dot(world - _390_fa_shadow_eye.xyz, _390_fa_shadow_fwd.xyz);\n    int param = _760 - 1;\n    if (_776 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _788 = _760 > 1;\n    bool _795;\n    if (_788)\n    {\n        _795 = _776 > _390_fa_shadow_split.x;\n    }\n    else\n    {\n        _795 = _788;\n    }\n    if (_795)\n    {\n        ci = 1;\n    }\n    bool _799 = _760 > 2;\n    bool _806;\n    if (_799)\n    {\n        _806 = _776 > _390_fa_shadow_split.y;\n    }\n    else\n    {\n        _806 = _799;\n    }\n    if (_806)\n    {\n        ci = 2;\n    }\n    bool _810 = _760 > 3;\n    bool _817;\n    if (_810)\n    {\n        _817 = _776 > _390_fa_shadow_split.z;\n    }\n    else\n    {\n        _817 = _810;\n    }\n    if (_817)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _760)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _843 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _843;\n        if (_843 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_390_fa_shadow_cfg.y > 0.0f)\n    {\n        float _868;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _868 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _868 = _390_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _887 = _390_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _868, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _898 = clamp((_776 - (fa_shadow_split_at(param_7) - _887)) / _887, 0.0f, 1.0f);\n        if (_898 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _760)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _919 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _919;\n                if (_919 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _898);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1242 = fa_light_sample(param, param_1);\n    float3 _2092 = _1242.direction;\n    float3 _2087 = _1242.color;\n    float _2094 = _1242.attenuation;\n    float _2089 = _1242.shadow;\n    int _2097 = _1242.type;\n    if ((_2097 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2092;\n        float _1256 = fa_shadow_factor(param_2, param_3);\n        _2089 = _1256;\n        _2087 = _224_fa_light_color[li].xyz * (_2094 * _1256);\n    }\n    LightSample _2104 = { _2092, _2087, _2094, _2089, _1242._distance, _2097 };\n    return _2104;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _1281 = n < 0;\n    bool _1288;\n    if (!_1281)\n    {\n        _1288 = n >= fa_light_count();\n    }\n    else\n    {\n        _1288 = _1281;\n    }\n    if (_1288)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    float3 param_1 = i.world_pos;\n    float3 param_2 = i.world_normal;\n    return fa_light_shadowed(param, param_1, param_2);\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1133 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1136 = _1133.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1136 * _1136, exp2((-9.27999973297119140625f) * ndv)) * _1136) + _1133.y)) + _1133.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_749_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _749_fa_env_horizon.w).xyz;\n    }\n    float _1056 = rough * rough;\n    float _1086 = 0.60000002384185791015625f * _1056;\n    return lerp(lerp(_749_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_749_fa_env_horizon.xyz, _749_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1056)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1086, 0.0500000007450580596923828125f + _1086, d.y).xxx), ((_749_fa_env_sky.xyz + _749_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1056 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1175 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1175.x) + _1175.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float3 param = normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = lerp(0.039999999105930328369140625f.xxx, s.albedo, clamp(s.metallic, 0.0f, 1.0f).xxx);\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1350 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_1350 > bestPower)\n        {\n            bestPower = _1350;\n            best = n;\n        }\n    }\n    float3 lit = (_749_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1379 = fa_light(param_2, param_3);\n        float _1387;\n        if (dot(s.normal, _1379.direction) > 0.5f)\n        {\n            _1387 = 1.0f;\n        }\n        else\n        {\n            _1387 = _1393_dark;\n        }\n        lit += ((s.albedo * _1379.color) * _1387);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _1393_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_390_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _943 = int(_390_fa_shadow_cfg.x + 0.5f);\n    float _953 = dot(world - _390_fa_shadow_eye.xyz, _390_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _958 = _943 > 0;\n    bool _967;\n    if (_958)\n    {\n        int param = _943 - 1;\n        _967 = _953 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _967 = _958;\n    }\n    if (_967)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _974 = _943 > 1;\n        bool _981;\n        if (_974)\n        {\n            _981 = _953 > _390_fa_shadow_split.x;\n        }\n        else\n        {\n            _981 = _974;\n        }\n        if (_981)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _987 = _943 > 2;\n        bool _994;\n        if (_987)\n        {\n            _994 = _953 > _390_fa_shadow_split.y;\n        }\n        else\n        {\n            _994 = _987;\n        }\n        if (_994)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1000 = _943 > 3;\n        bool _1007;\n        if (_1000)\n        {\n            _1007 = _953 > _390_fa_shadow_split.z;\n        }\n        else\n        {\n            _1007 = _1000;\n        }\n        if (_1007)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1992 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1992 = -_1992;\n    }\n    float3 _1697 = normalize(_749_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _2005 = { fa_world_pos, _1992, fa_world_tangent, fa_uv, fa_vertex_color, _1697, gl_FrontFacing };\n    SurfaceInput param = _2005;\n    Surface _1702 = fa_standard_surface(param);\n    float3 _2023 = _1702.albedo;\n    float _2024 = _1702.alpha;\n    float3 _2025 = _1702.normal;\n    float _2026 = _1702.metallic;\n    float _2027 = _1702.roughness;\n    float _2028 = _1702.occlusion;\n    float3 _2029 = _1702.emission;\n    SurfaceInput _2013 = { fa_world_pos, _1992, fa_world_tangent, fa_uv, fa_vertex_color, _1697, gl_FrontFacing };\n    SurfaceInput param_1 = _2013;\n    Surface param_2 = _1702;\n    surface(param_1, param_2);\n    _2023 = param_2.albedo;\n    _2024 = param_2.alpha;\n    _2025 = param_2.normal;\n    _2026 = param_2.metallic;\n    _2027 = param_2.roughness;\n    _2028 = param_2.occlusion;\n    _2029 = param_2.emission;\n    float3 result;\n    if (_749_fa_emissive.w > 0.5f)\n    {\n        result = _2023;\n    }\n    else\n    {\n        float3 _1723 = _2025;\n        float3 _1724 = normalize(_1723);\n        _2025 = _1724;\n        SurfaceInput _2021 = { fa_world_pos, _1992, fa_world_tangent, fa_uv, fa_vertex_color, _1697, gl_FrontFacing };\n        SurfaceInput param_3 = _2021;\n        Surface _2059 = { _2023, _2024, _1724, _2026, _2027, _2028, _2029 };\n        Surface param_4 = _2059;\n        result = lighting(param_3, param_4);\n    }\n    float3 _1739 = result;\n    float3 _1740 = _1739 + _2029;\n    result = _1740;\n    float3 param_5 = _1740;\n    float3 param_6 = fa_world_pos;\n    result = fa_shadow_debug(param_5, param_6);\n    bool _1749 = _749_fa_fog.w > 0.0f;\n    bool _1757;\n    if (!_1749)\n    {\n        _1757 = _749_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1757 = _1749;\n    }\n    if (_1757)\n    {\n        float3 _1766 = fa_world_pos - _749_fa_camera_pos.xyz;\n        float _1773 = dot(_1766, _749_fa_fog_c.xyz);\n        bool _1777 = _749_fa_fog_c.w > 0.5f;\n        float _1778;\n        if (_1777)\n        {\n            _1778 = _1773;\n        }\n        else\n        {\n            _1778 = length(_1766);\n        }\n        float _1790 = _1778 - _749_fa_fog_b.x;\n        if (_1790 > 0.0f)\n        {\n            float _1799 = _749_fa_fog.w * _1790;\n            float tau = _1799 * _1799;\n            if (_749_fa_fog_b.y > 0.0f)\n            {\n                float _1815;\n                if (_1777)\n                {\n                    _1815 = fa_world_pos.y - (_749_fa_fog_c.y * _1773);\n                }\n                else\n                {\n                    _1815 = _749_fa_camera_pos.y;\n                }\n                float _1836 = lerp(_1815, fa_world_pos.y, clamp(_749_fa_fog_b.x / _1778, 0.0f, 1.0f));\n                float _1840 = fa_world_pos.y - _1836;\n                float _1845 = _1836 - _749_fa_fog_b.z;\n                float _1850 = fa_world_pos.y - _749_fa_fog_b.z;\n                bool _1853 = _1845 <= 0.0f;\n                bool _1854 = !_1853;\n                bool _1860;\n                if (_1854)\n                {\n                    _1860 = _749_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1860 = _1853;\n                }\n                float _1861;\n                if (_1860)\n                {\n                    _1861 = _749_fa_fog_b.y;\n                }\n                else\n                {\n                    _1861 = _749_fa_fog_b.y * exp(-min(_749_fa_fog_b.w * _1845, 80.0f));\n                }\n                bool _1888;\n                if (_1854)\n                {\n                    _1888 = _749_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1888 = _1853;\n                }\n                float _1889;\n                if (_1888)\n                {\n                    _1889 = _749_fa_fog_b.y * _1845;\n                }\n                else\n                {\n                    _1889 = (_749_fa_fog_b.y * (1.0f - exp(-min(_749_fa_fog_b.w * _1845, 80.0f)))) / _749_fa_fog_b.w;\n                }\n                bool _1914 = _1850 <= 0.0f;\n                bool _1921;\n                if (!_1914)\n                {\n                    _1921 = _749_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1921 = _1914;\n                }\n                float _1922;\n                if (_1921)\n                {\n                    _1922 = _749_fa_fog_b.y * _1850;\n                }\n                else\n                {\n                    _1922 = (_749_fa_fog_b.y * (1.0f - exp(-min(_749_fa_fog_b.w * _1850, 80.0f)))) / _749_fa_fog_b.w;\n                }\n                float _1949;\n                if (abs(_1840) < 0.001000000047497451305389404296875f)\n                {\n                    _1949 = _1861;\n                }\n                else\n                {\n                    _1949 = (_1922 - _1889) / _1840;\n                }\n                tau += (_1790 * max(_1949, 0.0f));\n            }\n            result = lerp(result, _749_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2024);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_224",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_390",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_749",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1393",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _382 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _382;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_389, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstatic const LightSample _2169 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _224_fa_light_pos[32] : packoffset(c0);\n    float4 _224_fa_light_color[32] : packoffset(c32);\n    float4 _224_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _390_fa_shadow_mat[4] : packoffset(c0);\n    float4 _390_fa_shadow_rect[4] : packoffset(c16);\n    float4 _390_fa_shadow_info[4] : packoffset(c20);\n    float4 _390_fa_shadow_split : packoffset(c24);\n    float4 _390_fa_shadow_cfg : packoffset(c25);\n    float4 _390_fa_shadow_bias : packoffset(c26);\n    float4 _390_fa_shadow_eye : packoffset(c27);\n    float4 _390_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _749_fa_camera_pos : packoffset(c0);\n    float4 _749_fa_ambient : packoffset(c1);\n    float4 _749_fa_base_color : packoffset(c2);\n    float4 _749_fa_emissive : packoffset(c3);\n    float4 _749_fa_model_emissive : packoffset(c4);\n    float4 _749_fa_pbr : packoffset(c5);\n    float4 _749_fa_maps : packoffset(c6);\n    float4 _749_fa_fog : packoffset(c7);\n    float4 _749_fa_fog_b : packoffset(c8);\n    float4 _749_fa_fog_c : packoffset(c9);\n    float4 _749_fa_counts : packoffset(c10);\n    float4 _749_fa_env_sky : packoffset(c11);\n    float4 _749_fa_env_horizon : packoffset(c12);\n    float4 _749_fa_time : packoffset(c13);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _1393_dark : packoffset(c0);\n    float _1393_fa_pad0 : packoffset(c0.y);\n    float _1393_fa_pad1 : packoffset(c0.z);\n    float _1393_fa_pad2 : packoffset(c0.w);\n    float _1393_skyAmount : packoffset(c1);\n    float _1393_fa_pad3 : packoffset(c1.y);\n    float _1393_fa_pad4 : packoffset(c1.z);\n    float _1393_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1465 = fa_linear_to_srgb(param);\n        c = _1465;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1473 = fa_srgb_to_linear(param_1);\n            c = _1473;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _152;\n    if (i.front_facing)\n    {\n        _152 = i.world_normal;\n    }\n    else\n    {\n        _152 = -i.world_normal;\n    }\n    float3 _176 = normalize(i.world_tangent.xyz - (_152 * dot(_152, i.world_tangent.xyz)));\n    float3 _204 = normalize(((_176 * m.x) + ((cross(_152, _176) * i.world_tangent.w) * m.y)) + (_152 * m.z));\n    float3 _207;\n    if (i.front_facing)\n    {\n        _207 = _204;\n    }\n    else\n    {\n        _207 = -_204;\n    }\n    return _207;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _749_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1504 = fa_tex_fix(param_2, param_3);\n    float4 _2148 = base_t;\n    _2148.x = _1504.x;\n    _2148.y = _1504.y;\n    _2148.z = _1504.z;\n    base_t = _2148;\n    float4 _1518 = (_2148 * _749_fa_base_color) * i.vertex_color;\n    float3 _2116 = i.world_normal;\n    if (_749_fa_maps.z > 0.5f)\n    {\n        float param_4 = _749_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1550 = fa_tex_fix(param_6, param_7);\n        float3 _1554 = (_1550 * 2.0f) - 1.0f.xxx;\n        float2 _1559 = _1554.xy * _749_fa_maps.x;\n        float3 _2156 = _1554;\n        _2156.x = _1559.x;\n        _2156.y = _1559.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2156;\n        _2116 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _749_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1588 = fa_tex_fix(param_12, param_13);\n    float4 _2159 = mrt;\n    _2159.x = _1588.x;\n    _2159.y = _1588.y;\n    _2159.z = _1588.z;\n    mrt = _2159;\n    float param_14 = _749_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1627 = fa_tex_fix(param_16, param_17);\n    float param_18 = _749_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1654 = fa_tex_fix(param_20, param_21);\n    Surface _2128 = { _1518.xyz, _1518.w, _2116, clamp(_749_fa_pbr.x * _1588.z, 0.0f, 1.0f), clamp(_749_fa_pbr.y * _1588.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_749_fa_maps.y * (_1627.x - 1.0f)), _749_fa_emissive.xyz + (_749_fa_model_emissive.xyz * _1654) };\n    return _2128;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return min(int(_749_fa_counts.x), 32);\n}\n\nLightSample fa_no_light()\n{\n    return _2169;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _235 = _224_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_235)\n    {\n        l = normalize(_224_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _253 = _224_fa_light_pos[li].xyz - world_pos;\n        float _255 = length(_253);\n        dist = _255;\n        l = _253 / max(_255, 9.9999997473787516355514526367188e-05f).xxx;\n        float _271 = _255 / max(_224_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _277 = clamp(1.0f - (_271 * _271), 0.0f, 1.0f);\n        atten = _277 * _277;\n        if (_224_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_224_fa_light_dir[li].w, lerp(_224_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_224_fa_light_dir[li].xyz)));\n        }\n    }\n    int _328;\n    if (_235)\n    {\n        _328 = 0;\n    }\n    else\n    {\n        _328 = (_224_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _2072 = { l, _224_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _328 };\n    return _2072;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _1305 = n < 0;\n    bool _1312;\n    if (!_1305)\n    {\n        _1312 = n >= fa_light_count();\n    }\n    else\n    {\n        _1312 = _1305;\n    }\n    if (_1312)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    float3 param_1 = i.world_pos;\n    return fa_light_sample(param, param_1);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _380;\n    if (i == 0)\n    {\n        _380 = _390_fa_shadow_split.x;\n    }\n    else\n    {\n        float _396;\n        if (i == 1)\n        {\n            _396 = _390_fa_shadow_split.y;\n        }\n        else\n        {\n            float _404;\n            if (i == 2)\n            {\n                _404 = _390_fa_shadow_split.z;\n            }\n            else\n            {\n                _404 = _390_fa_shadow_split.w;\n            }\n            _396 = _404;\n        }\n        _380 = _396;\n    }\n    return _380;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _368 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_368), sin(_368)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _448 = max(_390_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _453 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _459 = sqrt(1.0f - (_453 * _453));\n    float _467 = min(_459 / max(_453, 0.20000000298023223876953125f), 4.0f);\n    float _472;\n    if (_390_fa_shadow_bias.y > 0.0f)\n    {\n        _472 = _390_fa_shadow_bias.y;\n    }\n    else\n    {\n        _472 = 1.5f * _390_fa_shadow_info[ci].x;\n    }\n    float4 _497 = mul(float4(world + (n * (_472 * _459)), 1.0f), _390_fa_shadow_mat[ci]);\n    float _504 = _497.x;\n    bool _507 = _504 < _390_fa_shadow_rect[ci].x;\n    bool _516;\n    if (!_507)\n    {\n        _516 = _504 > _390_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _516 = _507;\n    }\n    bool _525;\n    if (!_516)\n    {\n        _525 = _497.y < _390_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _525 = _516;\n    }\n    bool _534;\n    if (!_525)\n    {\n        _534 = _497.y > _390_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _534 = _525;\n    }\n    bool _541;\n    if (!_534)\n    {\n        _541 = _497.z > 1.0f;\n    }\n    else\n    {\n        _541 = _534;\n    }\n    if (_541)\n    {\n        return -1.0f;\n    }\n    float _550;\n    if (_390_fa_shadow_bias.x > 0.0f)\n    {\n        _550 = _390_fa_shadow_bias.x;\n    }\n    else\n    {\n        _550 = 1.5f * _390_fa_shadow_info[ci].x;\n    }\n    float _569 = _497.z - ((_550 * (1.0f + (0.5f * _467))) / _448);\n    float _578 = ((_390_fa_shadow_info[ci].x * min(_467, 3.0f)) * 0.5f) / _448;\n    int _587 = int(_390_fa_shadow_cfg.z + 0.5f);\n    if (_587 == 1)\n    {\n        float2 param = _497.xy;\n        float4 param_1 = _390_fa_shadow_rect[ci];\n        float _598 = fa_shadow_depth(param, param_1);\n        return float(_569 <= _598);\n    }\n    float _605 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _608 = _587 == 2;\n    if (_608)\n    {\n        float _622 = clamp(((_390_fa_shadow_cfg.w * _448) * 0.25f) / _390_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _605;\n            float2 _642 = fa_shadow_vogel(param_2, param_3, param_4) * _622;\n            float2 param_5 = _497.xy + (_642 * _390_fa_shadow_bias.zw);\n            float4 param_6 = _390_fa_shadow_rect[ci];\n            float _653 = fa_shadow_depth(param_5, param_6);\n            if (_653 < (_569 - (length(_642) * _578)))\n            {\n                sum += _653;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_569 - (sum / cnt), 0.0f) * _448) * _390_fa_shadow_cfg.w) / _390_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _697 = _608 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _697; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _697;\n        float param_9 = _605;\n        float2 _716 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _497.xy + (_716 * _390_fa_shadow_bias.zw);\n        float4 param_11 = _390_fa_shadow_rect[ci];\n        float _727 = fa_shadow_depth(param_10, param_11);\n        lit += float((_569 - (length(_716) * _578)) <= _727);\n    }\n    return lit / float(_697);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_749_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _760 = int(_390_fa_shadow_cfg.x + 0.5f);\n    if (_760 < 1)\n    {\n        return 1.0f;\n    }\n    float _776 = dot(world - _390_fa_shadow_eye.xyz, _390_fa_shadow_fwd.xyz);\n    int param = _760 - 1;\n    if (_776 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _788 = _760 > 1;\n    bool _795;\n    if (_788)\n    {\n        _795 = _776 > _390_fa_shadow_split.x;\n    }\n    else\n    {\n        _795 = _788;\n    }\n    if (_795)\n    {\n        ci = 1;\n    }\n    bool _799 = _760 > 2;\n    bool _806;\n    if (_799)\n    {\n        _806 = _776 > _390_fa_shadow_split.y;\n    }\n    else\n    {\n        _806 = _799;\n    }\n    if (_806)\n    {\n        ci = 2;\n    }\n    bool _810 = _760 > 3;\n    bool _817;\n    if (_810)\n    {\n        _817 = _776 > _390_fa_shadow_split.z;\n    }\n    else\n    {\n        _817 = _810;\n    }\n    if (_817)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _760)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _843 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _843;\n        if (_843 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_390_fa_shadow_cfg.y > 0.0f)\n    {\n        float _868;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _868 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _868 = _390_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _887 = _390_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _868, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _898 = clamp((_776 - (fa_shadow_split_at(param_7) - _887)) / _887, 0.0f, 1.0f);\n        if (_898 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _760)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _919 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _919;\n                if (_919 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _898);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1242 = fa_light_sample(param, param_1);\n    float3 _2092 = _1242.direction;\n    float3 _2087 = _1242.color;\n    float _2094 = _1242.attenuation;\n    float _2089 = _1242.shadow;\n    int _2097 = _1242.type;\n    if ((_2097 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2092;\n        float _1256 = fa_shadow_factor(param_2, param_3);\n        _2089 = _1256;\n        _2087 = _224_fa_light_color[li].xyz * (_2094 * _1256);\n    }\n    LightSample _2104 = { _2092, _2087, _2094, _2089, _1242._distance, _2097 };\n    return _2104;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _1281 = n < 0;\n    bool _1288;\n    if (!_1281)\n    {\n        _1288 = n >= fa_light_count();\n    }\n    else\n    {\n        _1288 = _1281;\n    }\n    if (_1288)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    float3 param_1 = i.world_pos;\n    float3 param_2 = i.world_normal;\n    return fa_light_shadowed(param, param_1, param_2);\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1133 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1136 = _1133.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1136 * _1136, exp2((-9.27999973297119140625f) * ndv)) * _1136) + _1133.y)) + _1133.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_749_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _749_fa_env_horizon.w).xyz;\n    }\n    float _1056 = rough * rough;\n    float _1086 = 0.60000002384185791015625f * _1056;\n    return lerp(lerp(_749_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_749_fa_env_horizon.xyz, _749_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1056)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1086, 0.0500000007450580596923828125f + _1086, d.y).xxx), ((_749_fa_env_sky.xyz + _749_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1056 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1175 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1175.x) + _1175.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float3 param = normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = lerp(0.039999999105930328369140625f.xxx, s.albedo, clamp(s.metallic, 0.0f, 1.0f).xxx);\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1350 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_1350 > bestPower)\n        {\n            bestPower = _1350;\n            best = n;\n        }\n    }\n    float3 lit = (_749_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1379 = fa_light(param_2, param_3);\n        float _1387;\n        if (dot(s.normal, _1379.direction) > 0.5f)\n        {\n            _1387 = 1.0f;\n        }\n        else\n        {\n            _1387 = _1393_dark;\n        }\n        lit += ((s.albedo * _1379.color) * _1387);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _1393_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_390_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _943 = int(_390_fa_shadow_cfg.x + 0.5f);\n    float _953 = dot(world - _390_fa_shadow_eye.xyz, _390_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _958 = _943 > 0;\n    bool _967;\n    if (_958)\n    {\n        int param = _943 - 1;\n        _967 = _953 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _967 = _958;\n    }\n    if (_967)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _974 = _943 > 1;\n        bool _981;\n        if (_974)\n        {\n            _981 = _953 > _390_fa_shadow_split.x;\n        }\n        else\n        {\n            _981 = _974;\n        }\n        if (_981)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _987 = _943 > 2;\n        bool _994;\n        if (_987)\n        {\n            _994 = _953 > _390_fa_shadow_split.y;\n        }\n        else\n        {\n            _994 = _987;\n        }\n        if (_994)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1000 = _943 > 3;\n        bool _1007;\n        if (_1000)\n        {\n            _1007 = _953 > _390_fa_shadow_split.z;\n        }\n        else\n        {\n            _1007 = _1000;\n        }\n        if (_1007)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1992 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1992 = -_1992;\n    }\n    float3 _1697 = normalize(_749_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _2005 = { fa_world_pos, _1992, fa_world_tangent, fa_uv, fa_vertex_color, _1697, gl_FrontFacing };\n    SurfaceInput param = _2005;\n    Surface _1702 = fa_standard_surface(param);\n    float3 _2023 = _1702.albedo;\n    float _2024 = _1702.alpha;\n    float3 _2025 = _1702.normal;\n    float _2026 = _1702.metallic;\n    float _2027 = _1702.roughness;\n    float _2028 = _1702.occlusion;\n    float3 _2029 = _1702.emission;\n    SurfaceInput _2013 = { fa_world_pos, _1992, fa_world_tangent, fa_uv, fa_vertex_color, _1697, gl_FrontFacing };\n    SurfaceInput param_1 = _2013;\n    Surface param_2 = _1702;\n    surface(param_1, param_2);\n    _2023 = param_2.albedo;\n    _2024 = param_2.alpha;\n    _2025 = param_2.normal;\n    _2026 = param_2.metallic;\n    _2027 = param_2.roughness;\n    _2028 = param_2.occlusion;\n    _2029 = param_2.emission;\n    float3 result;\n    if (_749_fa_emissive.w > 0.5f)\n    {\n        result = _2023;\n    }\n    else\n    {\n        float3 _1723 = _2025;\n        float3 _1724 = normalize(_1723);\n        _2025 = _1724;\n        SurfaceInput _2021 = { fa_world_pos, _1992, fa_world_tangent, fa_uv, fa_vertex_color, _1697, gl_FrontFacing };\n        SurfaceInput param_3 = _2021;\n        Surface _2059 = { _2023, _2024, _1724, _2026, _2027, _2028, _2029 };\n        Surface param_4 = _2059;\n        result = lighting(param_3, param_4);\n    }\n    float3 _1739 = result;\n    float3 _1740 = _1739 + _2029;\n    result = _1740;\n    float3 param_5 = _1740;\n    float3 param_6 = fa_world_pos;\n    result = fa_shadow_debug(param_5, param_6);\n    bool _1749 = _749_fa_fog.w > 0.0f;\n    bool _1757;\n    if (!_1749)\n    {\n        _1757 = _749_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1757 = _1749;\n    }\n    if (_1757)\n    {\n        float3 _1766 = fa_world_pos - _749_fa_camera_pos.xyz;\n        float _1773 = dot(_1766, _749_fa_fog_c.xyz);\n        bool _1777 = _749_fa_fog_c.w > 0.5f;\n        float _1778;\n        if (_1777)\n        {\n            _1778 = _1773;\n        }\n        else\n        {\n            _1778 = length(_1766);\n        }\n        float _1790 = _1778 - _749_fa_fog_b.x;\n        if (_1790 > 0.0f)\n        {\n            float _1799 = _749_fa_fog.w * _1790;\n            float tau = _1799 * _1799;\n            if (_749_fa_fog_b.y > 0.0f)\n            {\n                float _1815;\n                if (_1777)\n                {\n                    _1815 = fa_world_pos.y - (_749_fa_fog_c.y * _1773);\n                }\n                else\n                {\n                    _1815 = _749_fa_camera_pos.y;\n                }\n                float _1836 = lerp(_1815, fa_world_pos.y, clamp(_749_fa_fog_b.x / _1778, 0.0f, 1.0f));\n                float _1840 = fa_world_pos.y - _1836;\n                float _1845 = _1836 - _749_fa_fog_b.z;\n                float _1850 = fa_world_pos.y - _749_fa_fog_b.z;\n                bool _1853 = _1845 <= 0.0f;\n                bool _1854 = !_1853;\n                bool _1860;\n                if (_1854)\n                {\n                    _1860 = _749_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1860 = _1853;\n                }\n                float _1861;\n                if (_1860)\n                {\n                    _1861 = _749_fa_fog_b.y;\n                }\n                else\n                {\n                    _1861 = _749_fa_fog_b.y * exp(-min(_749_fa_fog_b.w * _1845, 80.0f));\n                }\n                bool _1888;\n                if (_1854)\n                {\n                    _1888 = _749_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1888 = _1853;\n                }\n                float _1889;\n                if (_1888)\n                {\n                    _1889 = _749_fa_fog_b.y * _1845;\n                }\n                else\n                {\n                    _1889 = (_749_fa_fog_b.y * (1.0f - exp(-min(_749_fa_fog_b.w * _1845, 80.0f)))) / _749_fa_fog_b.w;\n                }\n                bool _1914 = _1850 <= 0.0f;\n                bool _1921;\n                if (!_1914)\n                {\n                    _1921 = _749_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1921 = _1914;\n                }\n                float _1922;\n                if (_1921)\n                {\n                    _1922 = _749_fa_fog_b.y * _1850;\n                }\n                else\n                {\n                    _1922 = (_749_fa_fog_b.y * (1.0f - exp(-min(_749_fa_fog_b.w * _1850, 80.0f)))) / _749_fa_fog_b.w;\n                }\n                float _1949;\n                if (abs(_1840) < 0.001000000047497451305389404296875f)\n                {\n                    _1949 = _1861;\n                }\n                else\n                {\n                    _1949 = (_1922 - _1889) / _1840;\n                }\n                tau += (_1790 * max(_1949, 0.0f));\n            }\n            result = lerp(result, _749_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2024);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_224",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_390",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_749",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1393",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _589 = base_t;\n    _589.x = _225.x;\n    _589.y = _225.y;\n    _589.z = _225.z;\n    base_t = _589;\n    float4 _241 = (_589 * _213_fa_base_color) * i.vertex_color;\n    float3 _570 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _597 = _279;\n        _597.x = _284.x;\n        _597.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _597;\n        _570 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _600 = mrt;\n    _600.x = _313.x;\n    _600.y = _313.y;\n    _600.z = _313.z;\n    mrt = _600;\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    Surface _582 = { _241.xyz, _241.w, _570, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_354.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _381) };\n    return _582;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _517 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _517 = -_517;\n    }\n    float3 _427 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _530 = { fa_world_pos, _517, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param = _530;\n    SurfaceInput _538 = { fa_world_pos, _517, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param_1 = _538;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _442 = normalize(param_2.normal);\n    float3 _457 = normalize(float3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / ((abs(_457.x) + abs(_457.y)) + abs(_469)).xx;\n    if (_469 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _416 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _416;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0f);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _589 = base_t;\n    _589.x = _225.x;\n    _589.y = _225.y;\n    _589.z = _225.z;\n    base_t = _589;\n    float4 _241 = (_589 * _213_fa_base_color) * i.vertex_color;\n    float3 _570 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _597 = _279;\n        _597.x = _284.x;\n        _597.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _597;\n        _570 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _600 = mrt;\n    _600.x = _313.x;\n    _600.y = _313.y;\n    _600.z = _313.z;\n    mrt = _600;\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    Surface _582 = { _241.xyz, _241.w, _570, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_354.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _381) };\n    return _582;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _517 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _517 = -_517;\n    }\n    float3 _427 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _530 = { fa_world_pos, _517, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param = _530;\n    SurfaceInput _538 = { fa_world_pos, _517, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param_1 = _538;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _442 = normalize(param_2.normal);\n    float3 _457 = normalize(float3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / ((abs(_457.x) + abs(_457.y)) + abs(_469)).xx;\n    if (_469 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
