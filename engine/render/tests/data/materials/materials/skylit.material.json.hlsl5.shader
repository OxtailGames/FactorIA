{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "cdeb0668828214c74f0c30d588a05ff792b9d23c1a6a8d04f213c29c73527515",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _2703[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _511_fa_camera_pos : packoffset(c0);\n    float4 _511_fa_ambient : packoffset(c1);\n    float4 _511_fa_base_color : packoffset(c2);\n    float4 _511_fa_emissive : packoffset(c3);\n    float4 _511_fa_model_emissive : packoffset(c4);\n    float4 _511_fa_pbr : packoffset(c5);\n    float4 _511_fa_maps : packoffset(c6);\n    float4 _511_fa_fog : packoffset(c7);\n    float4 _511_fa_fog_b : packoffset(c8);\n    float4 _511_fa_fog_c : packoffset(c9);\n    float4 _511_fa_counts : packoffset(c10);\n    float4 _511_fa_env_sky : packoffset(c11);\n    float4 _511_fa_env_horizon : packoffset(c12);\n    float4 _511_fa_time : packoffset(c13);\n    float4 _511_fa_cl_vpx : packoffset(c14);\n    float4 _511_fa_cl_vpy : packoffset(c15);\n    float4 _511_fa_cl_vpw : packoffset(c16);\n    float4 _511_fa_cl_fwd : packoffset(c17);\n    float4 _511_fa_cl_grid : packoffset(c18);\n    float4 _511_fa_cl_info : packoffset(c19);\n    float4 _511_fa_layers_a : packoffset(c20);\n    float4 _511_fa_layers_b : packoffset(c21);\n    float4 _511_fa_layers_c : packoffset(c22);\n    float4 _511_fa_layers_d : packoffset(c23);\n    float4 _511_fa_ct_a : packoffset(c24);\n    float4 _511_fa_ct_b : packoffset(c25);\n    float4 _511_fa_ct_vpx : packoffset(c26);\n    float4 _511_fa_ct_vpy : packoffset(c27);\n    float4 _511_fa_ct_vpw : packoffset(c28);\n    float4 _511_fa_ct_fwd : packoffset(c29);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1251_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1251_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1251_fa_shadow_info[4] : packoffset(c20);\n    float4 _1251_fa_shadow_split : packoffset(c24);\n    float4 _1251_fa_shadow_cfg : packoffset(c25);\n    float4 _1251_fa_shadow_bias : packoffset(c26);\n    float4 _1251_fa_shadow_eye : packoffset(c27);\n    float4 _1251_fa_shadow_fwd : packoffset(c28);\n    float4 _1251_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t8);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _516 = _511_fa_cl_info.x < 0.0f;\n    bool _523;\n    if (!_516)\n    {\n        _523 = _511_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _523 = _516;\n    }\n    bool _531;\n    if (!_523)\n    {\n        _531 = _511_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _531 = _523;\n    }\n    bool _538;\n    if (!_531)\n    {\n        _538 = _511_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _538 = _531;\n    }\n    bool _545;\n    if (!_538)\n    {\n        _545 = _511_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _545 = _538;\n    }\n    if (_545)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _555 = float4(world_pos, 1.0f);\n    float _562 = dot(_511_fa_cl_vpw, _555);\n    if (!(_562 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _584 = float2(dot(_511_fa_cl_vpx, _555), dot(_511_fa_cl_vpy, _555)) / _562.xx;\n    int _588 = int(_511_fa_cl_grid.x);\n    int _592 = int(_511_fa_cl_grid.y);\n    int param = (int(_511_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_511_fa_cl_fwd.xyz, world_pos) + _511_fa_cl_fwd.w, _511_fa_cl_grid.w) / _511_fa_cl_grid.w) * _511_fa_cl_grid.z)), 0, int(_511_fa_cl_info.y) - 1) * _592) + clamp(int(floor(((_584.y * 0.5f) + 0.5f) * _511_fa_cl_grid.y)), 0, _592 - 1)) * _588)) + clamp(int(floor(((_584.x * 0.5f) + 0.5f) * _511_fa_cl_grid.x)), 0, _588 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _668 = fa_cluster_texel(param);\n    return int2(int(_668.x), int(_668.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_511_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3489 = fa_cluster_lookup(param);\n    fa_cl_slot = _3489.x;\n    fa_cl_local = _3489.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3687 = fa_linear_to_srgb(param);\n        c = _3687;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3695 = fa_srgb_to_linear(param_1);\n            c = _3695;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _276;\n    if (i.front_facing)\n    {\n        _276 = i.world_normal;\n    }\n    else\n    {\n        _276 = -i.world_normal;\n    }\n    float3 _300 = normalize(i.world_tangent.xyz - (_276 * dot(_276, i.world_tangent.xyz)));\n    float3 _327 = normalize(((_300 * m.x) + ((cross(_276, _300) * i.world_tangent.w) * m.y)) + (_276 * m.z));\n    float3 _330;\n    if (i.front_facing)\n    {\n        _330 = _327;\n    }\n    else\n    {\n        _330 = -_327;\n    }\n    return _330;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _511_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3726 = fa_tex_fix(param_2, param_3);\n    float4 _4841 = base_t;\n    _4841.x = _3726.x;\n    _4841.y = _3726.y;\n    _4841.z = _3726.z;\n    base_t = _4841;\n    float4 _3740 = (_4841 * _511_fa_base_color) * i.vertex_color;\n    float3 _4695 = i.world_normal;\n    if (_511_fa_maps.z > 0.5f)\n    {\n        float param_4 = _511_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3772 = fa_tex_fix(param_6, param_7);\n        float3 _3775 = (_3772 * 2.0f) - 1.0f.xxx;\n        float2 _3780 = _3775.xy * _511_fa_maps.x;\n        float3 _4849 = _3775;\n        _4849.x = _3780.x;\n        _4849.y = _3780.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4849;\n        _4695 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _511_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3809 = fa_tex_fix(param_12, param_13);\n    float4 _4852 = mrt;\n    _4852.x = _3809.x;\n    _4852.y = _3809.y;\n    _4852.z = _3809.z;\n    mrt = _4852;\n    float4 _3837 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _511_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3837.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3849 = fa_tex_fix(param_16, param_17);\n    float param_18 = _511_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3879 = fa_tex_fix(param_20, param_21);\n    float _4700 = _511_fa_layers_a.x;\n    float _4701 = _511_fa_layers_a.y;\n    float _4704 = _511_fa_layers_a.z;\n    float _4703 = _511_fa_layers_b.w;\n    float _4706 = _511_fa_layers_c.x;\n    if (_511_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_511_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4700 *= _3849.y;\n            _4701 *= _3849.z;\n            _4703 *= _3837.w;\n        }\n        if (_511_fa_layers_c.z > 1.5f)\n        {\n            _4704 *= mrt.x;\n            _4706 *= mrt.w;\n        }\n    }\n    Surface _4725 = { _3740.xyz, _3740.w, _4695, clamp(_511_fa_pbr.x * _3809.z, 0.0f, 1.0f), clamp(_511_fa_pbr.y * _3809.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_511_fa_maps.y * (_3849.x - 1.0f)), _511_fa_emissive.xyz + (_511_fa_model_emissive.xyz * _3879), _4700, _4701, _511_fa_layers_b.xyz, _4703, _4704, _511_fa_layers_a.w, _4706, _511_fa_layers_c.y, _511_fa_layers_d.xyz };\n    return _4725;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _749 = rect.zw - rect.xy;\n    float2 _753 = _749 * atlas;\n    float2 _757 = ddx * _753;\n    float2 _761 = ddy * _753;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _749), clamp(0.5f * log2(max(max(dot(_757, _757), dot(_761, _761)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _796 = _511_fa_counts.y < 0.5f;\n    bool _803;\n    if (!_796)\n    {\n        _803 = _511_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _803 = _796;\n    }\n    if (_803)\n    {\n        return;\n    }\n    float3 _809 = ddx(world_pos);\n    float3 _812 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _816 = fa_cluster_texel(param);\n    int _820 = int(_816.w);\n    if (_820 < 1)\n    {\n        return;\n    }\n    int _830 = int(_511_fa_counts.y + 0.5f);\n    int param_1 = _830;\n    float4 _834 = fa_light_texel(param_1);\n    float2 _837 = _834.yz;\n    int _841 = int(_834.w);\n    int param_2 = _830 + 1;\n    float4 _846 = fa_light_texel(param_2);\n    float _847 = _846.x;\n    int _853 = int(_511_fa_counts.w + 0.5f) - 1;\n    int _857 = int(_816.z);\n    float3 _1123;\n    for (int k = 0; k < _820; k++)\n    {\n        int _870 = _857 + k;\n        int param_3 = _841 + (_870 >> 2);\n        int _888 = (_830 + 2) + (int(fa_light_texel(param_3)[_870 & 3]) * 7);\n        int param_4 = _888 + 6;\n        float4 _893 = fa_light_texel(param_4);\n        if (((int(_893.w + 0.5f) >> _853) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _888;\n        float4 _908 = fa_light_texel(param_5);\n        int param_6 = _888 + 1;\n        float4 _913 = fa_light_texel(param_6);\n        int param_7 = _888 + 2;\n        float4 _918 = fa_light_texel(param_7);\n        float3 _921 = _908.xyz;\n        float _926 = dot(_921, world_pos) + _908.w;\n        float3 _928 = _913.xyz;\n        float _933 = dot(_928, world_pos) + _913.w;\n        float3 _935 = _918.xyz;\n        float _940 = dot(_935, world_pos) + _918.w;\n        bool _945 = abs(_926) > 0.5f;\n        bool _953;\n        if (!_945)\n        {\n            _953 = abs(_933) > 0.5f;\n        }\n        else\n        {\n            _953 = _945;\n        }\n        bool _961;\n        if (!_953)\n        {\n            _961 = abs(_940) > 0.5f;\n        }\n        else\n        {\n            _961 = _953;\n        }\n        if (_961)\n        {\n            continue;\n        }\n        float _976 = clamp(dot(geo_normal, normalize(_935)) * _893.z, 0.0f, 1.0f);\n        if (_976 <= 0.0f)\n        {\n            continue;\n        }\n        float _996 = (clamp((0.5f - abs(_940)) * 10.0f, 0.0f, 1.0f) * _976) * _893.x;\n        float2 _1004 = float2(_926 + 0.5f, 0.5f - _933);\n        float2 _1014 = float2(dot(_921, _809), dot(_928, _809));\n        float2 _1024 = float2(dot(_921, _812), dot(_928, _812));\n        int param_8 = _888 + 5;\n        float4 _1029 = fa_light_texel(param_8);\n        int param_9 = _888 + 3;\n        float4 _1034 = fa_light_texel(param_9);\n        int param_10 = _888 + 4;\n        float4 _1039 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1029.xyz;\n        bool _1049 = _1034.z > _1034.x;\n        if (_1049)\n        {\n            float4 param_11 = _1034;\n            float2 param_12 = _1004;\n            float2 param_13 = _837;\n            float2 param_14 = _1014;\n            float2 param_15 = _1024;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_847 > 0.5f) && (_847 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1075 = fa_dc_to_linear(param_16);\n                float4 _4751 = tx;\n                _4751.x = _1075.x;\n                _4751.y = _1075.y;\n                _4751.z = _1075.z;\n                tx = _4751;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_996 * tex_a) * _1029.w, 0.0f, 1.0f).xxx);\n        if (_1039.z > _1039.x)\n        {\n            float4 param_17 = _1039;\n            float2 param_18 = _1004;\n            float2 param_19 = _837;\n            float2 param_20 = _1014;\n            float2 param_21 = _1024;\n            float4 _1119 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_847 > 1.5f)\n            {\n                float3 param_22 = _1119.xyz;\n                float3 _1129 = fa_dc_to_srgb(param_22);\n                _1123 = _1129;\n            }\n            else\n            {\n                _1123 = _1119.xyz;\n            }\n            float3 _1139 = (_1123 * 2.0f) - 1.0f.xxx;\n            float2 _1144 = _1139.xy * _893.y;\n            float3 _1166 = (normalize(_921) * _1144.x) + (normalize(_928) * _1144.y);\n            float3 _1169 = normalize(normal);\n            normal = normalize(lerp(_1169, normalize((_1169 * max(_1139.z, 0.0500000007450580596923828125f)) + (_1166 - (_1169 * dot(_1169, _1166)))), clamp(_996 * (_1049 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_511_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _2386 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _2386;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_511_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _511_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2629 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _2636 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _2639 = int(_2629);\n    int _2642 = int(_2636);\n    float _2652 = _2636 - float(_2642);\n    int _2707 = (_2639 * 9) + _2642;\n    int _2727 = ((_2639 + 1) * 9) + _2642;\n    return lerp(lerp(_2703[_2707], _2703[_2707 + 1], _2652), lerp(_2703[_2727], _2703[_2727 + 1], _2652), _2629 - float(_2639));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4554 = false;\n    float _4555 = 1.0f;\n    float _4556 = 1.0f;\n    float _4557 = 1.0f;\n    float _4558 = 0.0f;\n    float _4559 = 0.0f;\n    float _4560 = 0.0f;\n    float _4561 = 0.0f;\n    float _4563 = 1.0f;\n    bool _4564 = false;\n    float3 _4565 = 0.0f.xxx;\n    float _4566 = 1.0f;\n    float _4567 = 1.0f;\n    float _4568 = 1.0f;\n    float _4569 = 0.0f;\n    float _4570 = 0.0f;\n    float3 _4571 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4572 = float3(0.0f, 0.0f, 1.0f);\n    float _4573 = 1.0f;\n    float _4574 = 1.0f;\n    float _2780 = clamp(s.specular, 0.0f, 1.0f);\n    float _2784 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2789 = (_2780 != 1.0f) || (_2784 != 1.5f);\n    bool _2799;\n    if (!_2789)\n    {\n        _2799 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2799 = _2789;\n    }\n    if (_2799)\n    {\n        float _2807 = (_2784 - 1.0f) / (_2784 + 1.0f);\n        f0 = lerp(min((_2807 * _2807).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2780, s.albedo, metallic.xxx);\n        _4555 = lerp(_2780, 1.0f, metallic);\n        _4554 = true;\n    }\n    float _2835 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2835 > 0.0f)\n    {\n        float _2843 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4558 = _2835;\n        _4559 = _2843;\n        float _2850 = _2843 * _2843;\n        _4560 = _2850;\n        _4561 = _2850 * _2850;\n        float _2862 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4563 = _2862;\n        _4556 = 1.0f - (_2835 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2862, 0.0f, 1.0f), 5.0f))));\n        _4554 = true;\n    }\n    float3 _2881 = max(s.sheen_color, 0.0f.xxx);\n    float _2890 = max(_2881.x, max(_2881.y, _2881.z));\n    if (_2890 > 0.0f)\n    {\n        float _2898 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4564 = true;\n        _4565 = _2881;\n        _4566 = _2898;\n        _4567 = _2898 * _2898;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2898;\n        float _2915 = fa_sheen_albedo(param, param_1);\n        _4569 = _2915;\n        _4568 = 1.0f - min(_2890 * _2915, 1.0f);\n        _4554 = true;\n    }\n    _4557 = _4556 * _4568;\n    float _2934 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2934 != 0.0f)\n    {\n        float3 _2949 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2949;\n        if (dot(_2949, _2949) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2962 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2962.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2962.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2962.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2966 = t;\n        float3 _2967 = normalize(_2966);\n        t = _2967;\n        float3 _2992 = normalize((_2967 * cos(s.anisotropy_rotation)) + ((cross(n, _2967) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4571 = _2992;\n        _4572 = cross(n, _2992);\n        float _3002 = roughness * roughness;\n        float _3008 = lerp(_3002, 1.0f, _2934 * _2934);\n        bool _3010 = _2934 > 0.0f;\n        _4573 = _3010 ? _3008 : _3002;\n        _4574 = _3010 ? _3002 : _3008;\n        _4570 = _2934;\n        _4554 = true;\n    }\n    FaLayers _4596 = { _4554, _4555, _4556, _4557, _4558, _4559, _4560, _4561, i.world_normal, _4563, _4564, _4565, _4566, _4567, _4568, _4569, _4570, _4571, _4572, _4573, _4574 };\n    return _4596;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _2561 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _2564 = _2561.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_2564 * _2564, exp2((-9.27999973297119140625f) * ndv)) * _2564) + _2561.y)) + _2561.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_511_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _511_fa_env_horizon.w).xyz;\n    }\n    float _2415 = rough * rough;\n    float _2445 = 0.60000002384185791015625f * _2415;\n    return lerp(lerp(_511_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_511_fa_env_horizon.xyz, _511_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _2415)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _2445, 0.0500000007450580596923828125f + _2445, d.y).xxx), ((_511_fa_env_sky.xyz + _511_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_2415 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3043;\n        if (L.aniso >= 0.0f)\n        {\n            _3043 = L.b;\n        }\n        else\n        {\n            _3043 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3043, v), _3043), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3076 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3076.x) + (L.f90.xxx * _3076.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3131 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3131.x) + _3131.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2603 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2603.x) + _2603.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3160 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3164 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3171 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3160.xxx);\n    float3 f0 = _3171;\n    float3 _3175 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3175;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3160;\n    float param_5 = _3164;\n    float3 param_6 = _3171;\n    FaLayers _3192 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3192.on)\n    {\n        FaLayers param_7 = _3192;\n        float3 param_8 = _3175;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3164;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3175;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3164;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_511_fa_cl_info.x) + int(_511_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _386 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _392 = fa_light_texel(param_1);\n    float _395 = _392.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _401 = _395 < 0.5f;\n    float3 l;\n    if (_401)\n    {\n        l = normalize(_386.xyz);\n    }\n    else\n    {\n        float3 _413 = _386.xyz - world_pos;\n        float _415 = length(_413);\n        dist = _415;\n        l = _413 / max(_415, 9.9999997473787516355514526367188e-05f).xxx;\n        float _430 = _415 / max(_386.w, 0.001000000047497451305389404296875f);\n        float _436 = clamp(1.0f - (_430 * _430), 0.0f, 1.0f);\n        atten = _436 * _436;\n        if (_395 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _450 = fa_light_texel(param_2);\n            float _460 = _450.w;\n            int param_3 = (li * 4) + 3;\n            float4 _466 = fa_light_texel(param_3);\n            float _467 = _466.x;\n            float cos_inner = _467;\n            if (_467 > 1.5f)\n            {\n                cos_inner = lerp(_460, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_460, cos_inner, dot(-l, normalize(_450.xyz)));\n        }\n    }\n    int _497;\n    if (_401)\n    {\n        _497 = 0;\n    }\n    else\n    {\n        _497 = (_395 > 1.5f) ? 2 : 1;\n    }\n    LightSample _4553 = { l, _392.xyz * atten, atten, 1.0f, dist, _497 };\n    return _4553;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1241;\n    if (i == 0)\n    {\n        _1241 = _1251_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1257;\n        if (i == 1)\n        {\n            _1257 = _1251_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1265;\n            if (i == 2)\n            {\n                _1265 = _1251_fa_shadow_split.z;\n            }\n            else\n            {\n                _1265 = _1251_fa_shadow_split.w;\n            }\n            _1257 = _1265;\n        }\n        _1241 = _1257;\n    }\n    return _1241;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1298 = fa_shadow_depth(param, param_1);\n    float _1302;\n    if (conv.x < 0.5f)\n    {\n        _1302 = _1298;\n    }\n    else\n    {\n        _1302 = (conv.y * conv.z) / (conv.z - (_1298 * (conv.z - conv.y)));\n    }\n    return _1302;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1229 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1229), sin(_1229)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1348 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1362 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1348;\n            float2 _1381 = fa_shadow_vogel(param_3, param_4, param_5) * _1362;\n            float2 param_6 = uv + (_1381 * _1251_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1393 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1393 < (zr - (length(_1381) * plane)))\n            {\n                sum += _1393;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1437 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1437; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1437;\n        float param_11 = _1348;\n        float2 _1456 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1456 * _1251_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1456) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1437);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1498 = max(_1251_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1503 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1509 = sqrt(1.0f - (_1503 * _1503));\n    float _1516 = min(_1509 / max(_1503, 0.20000000298023223876953125f), 4.0f);\n    float _1521;\n    if (_1251_fa_shadow_bias.y > 0.0f)\n    {\n        _1521 = _1251_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1521 = 1.5f * _1251_fa_shadow_info[ci].x;\n    }\n    float4 _1546 = mul(float4(world + (n * (_1521 * _1509)), 1.0f), _1251_fa_shadow_mat[ci]);\n    float _1553 = _1546.x;\n    bool _1556 = _1553 < _1251_fa_shadow_rect[ci].x;\n    bool _1565;\n    if (!_1556)\n    {\n        _1565 = _1553 > _1251_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1565 = _1556;\n    }\n    bool _1574;\n    if (!_1565)\n    {\n        _1574 = _1546.y < _1251_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1574 = _1565;\n    }\n    bool _1583;\n    if (!_1574)\n    {\n        _1583 = _1546.y > _1251_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1583 = _1574;\n    }\n    bool _1590;\n    if (!_1583)\n    {\n        _1590 = _1546.z > 1.0f;\n    }\n    else\n    {\n        _1590 = _1583;\n    }\n    if (_1590)\n    {\n        return -1.0f;\n    }\n    float _1599;\n    if (_1251_fa_shadow_bias.x > 0.0f)\n    {\n        _1599 = _1251_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1599 = 1.5f * _1251_fa_shadow_info[ci].x;\n    }\n    float2 param = _1546.xy;\n    float4 param_1 = _1251_fa_shadow_rect[ci];\n    float param_2 = _1546.z - ((_1599 * (1.0f + (0.5f * _1516))) / _1498);\n    float param_3 = _1251_fa_shadow_info[ci].x;\n    float param_4 = _1498;\n    float param_5 = _1498 * 0.25f;\n    float param_6 = ((_1251_fa_shadow_info[ci].x * min(_1516, 3.0f)) * 0.5f) / _1498;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1251_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1251_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_511_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2026 = int(_1251_fa_shadow_cfg.x + 0.5f);\n    if (_2026 < 1)\n    {\n        return 1.0f;\n    }\n    float _2041 = dot(world - _1251_fa_shadow_eye.xyz, _1251_fa_shadow_fwd.xyz);\n    int param = _2026 - 1;\n    if (_2041 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2053 = _2026 > 1;\n    bool _2060;\n    if (_2053)\n    {\n        _2060 = _2041 > _1251_fa_shadow_split.x;\n    }\n    else\n    {\n        _2060 = _2053;\n    }\n    if (_2060)\n    {\n        ci = 1;\n    }\n    bool _2064 = _2026 > 2;\n    bool _2071;\n    if (_2064)\n    {\n        _2071 = _2041 > _1251_fa_shadow_split.y;\n    }\n    else\n    {\n        _2071 = _2064;\n    }\n    if (_2071)\n    {\n        ci = 2;\n    }\n    bool _2075 = _2026 > 3;\n    bool _2082;\n    if (_2075)\n    {\n        _2082 = _2041 > _1251_fa_shadow_split.z;\n    }\n    else\n    {\n        _2082 = _2075;\n    }\n    if (_2082)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2026)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2108 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2108;\n        if (_2108 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1251_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2133;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2133 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2133 = _1251_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2152 = _1251_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2133, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2163 = clamp((_2041 - (fa_shadow_split_at(param_7) - _2152)) / _2152, 0.0f, 1.0f);\n        if (_2163 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2026)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2184 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2184;\n                if (_2184 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2163);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1657 = _511_fa_pbr.z < 0.5f;\n    bool _1665;\n    if (!_1657)\n    {\n        _1665 = _1251_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1665 = _1657;\n    }\n    if (_1665)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1251_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1678 = fa_light_texel(param);\n    float _1679 = _1678.x;\n    if (_1679 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1688 = int(_1679 + 0.5f);\n    int param_1 = _1688;\n    float4 _1692 = fa_light_texel(param_1);\n    int param_2 = _1688 + 1;\n    float4 _1697 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1700 = _1692.y;\n    if (_1700 > 0.0f)\n    {\n        float _1717 = 1.0f - smoothstep(0.75f * _1700, _1700, length(world - _1251_fa_shadow_eye.xyz));\n        fade = _1717;\n        if (_1717 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1692.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1736 = world - fa_light_texel(param_3).xyz;\n        float3 _1739 = abs(_1736);\n        float _1741 = _1739.x;\n        float _1743 = _1739.y;\n        bool _1744 = _1741 >= _1743;\n        bool _1752;\n        if (_1744)\n        {\n            _1752 = _1741 >= _1739.z;\n        }\n        else\n        {\n            _1752 = _1744;\n        }\n        int _1753;\n        if (_1752)\n        {\n            _1753 = (_1736.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1766;\n            if (_1743 >= _1739.z)\n            {\n                _1766 = (_1736.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1766 = (_1736.z > 0.0f) ? 4 : 5;\n            }\n            _1753 = _1766;\n        }\n        face = _1753;\n    }\n    int _1785 = (_1688 + 2) + (face * 6);\n    int param_4 = _1785;\n    int param_5 = _1785 + 1;\n    int param_6 = _1785 + 3;\n    float4 _1799 = fa_light_texel(param_6);\n    int param_7 = _1785 + 4;\n    float4 _1804 = fa_light_texel(param_7);\n    int param_8 = _1785 + 5;\n    float4 _1809 = fa_light_texel(param_8);\n    float _1821 = _1809.x * max(dot(_1799, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1826 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1849 = clamp(dot(n, _1799.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1872 = min(sqrt(1.0f - (_1849 * _1849)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1799, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1875 = _1697.y;\n    float _1877;\n    if (_1875 > 0.0f)\n    {\n        _1877 = _1875;\n    }\n    else\n    {\n        _1877 = 1.5f * _1821;\n    }\n    float4 _1897 = float4(world + (n * (_1877 * sqrt(1.0f - (_1826 * _1826)))), 1.0f);\n    float _1901 = dot(_1799, _1897);\n    float _1904 = _1809.y;\n    if (_1901 < _1904)\n    {\n        return 1.0f;\n    }\n    float2 _1919 = float2(dot(fa_light_texel(param_4), _1897), dot(fa_light_texel(param_5), _1897)) / _1901.xx;\n    float _1921 = _1919.x;\n    bool _1924 = _1921 < _1804.x;\n    bool _1933;\n    if (!_1924)\n    {\n        _1933 = _1921 > _1804.z;\n    }\n    else\n    {\n        _1933 = _1924;\n    }\n    bool _1942;\n    if (!_1933)\n    {\n        _1942 = _1919.y < _1804.y;\n    }\n    else\n    {\n        _1942 = _1933;\n    }\n    bool _1951;\n    if (!_1942)\n    {\n        _1951 = _1919.y > _1804.w;\n    }\n    else\n    {\n        _1951 = _1942;\n    }\n    if (_1951)\n    {\n        return 1.0f;\n    }\n    float _1957 = _1697.x;\n    float _1959;\n    if (_1957 > 0.0f)\n    {\n        _1959 = _1957;\n    }\n    else\n    {\n        _1959 = 1.5f * _1821;\n    }\n    float2 param_10 = _1919;\n    float4 param_11 = _1804;\n    float param_12 = _1901 - (_1959 * (1.0f + (0.5f * _1872)));\n    float param_13 = _1821;\n    float param_14 = 1.0f;\n    float param_15 = _1809.z * 0.25f;\n    float param_16 = (_1821 * min(_1872, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1904, _1809.z);\n    int param_18 = int(_1692.z + 0.5f);\n    float param_19 = _1692.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3231 = _511_fa_ct_a.x < 0.5f;\n    bool _3238;\n    if (!_3231)\n    {\n        _3238 = _1251_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3238 = _3231;\n    }\n    if (_3238)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1251_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3251 = fa_light_texel(param);\n    float _3252 = _3251.y;\n    float len = _3252;\n    if (_3252 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3264 = length(world - _511_fa_camera_pos.xyz);\n    float _3274 = 1.0f - smoothstep(0.5f * _511_fa_ct_b.x, _511_fa_ct_b.x, _3264);\n    if (_3274 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3280 = len;\n    float _3283 = min(_3280, 0.89999997615814208984375f * dist);\n    len = _3283;\n    float _3288 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3264);\n    float _3293 = _3288 + (0.5f * _3283);\n    float3 _3299 = world + (gn * _3288);\n    float _3301 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3365;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3316 = (float(k) + _3301) * 0.083333335816860198974609375f;\n        float3 _3324 = _3299 + (l * (_3316 * len));\n        float4 _3330 = float4(_3324, 1.0f);\n        float _3336 = dot(_511_fa_ct_vpw, _3330);\n        if (_3336 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3356 = float2(dot(_511_fa_ct_vpx, _3330), dot(_511_fa_ct_vpy, _3330)) / _3336.xx;\n        float _3360 = _3356.x * 0.5f;\n        float _3361 = _3360 + 0.5f;\n        if (_511_fa_ct_a.y > 0.5f)\n        {\n            _3365 = (_3356.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3365 = 0.5f - (_3356.y * 0.5f);\n        }\n        bool _3381 = _3361 < 0.0f;\n        bool _3388;\n        if (!_3381)\n        {\n            _3388 = _3361 >= 1.0f;\n        }\n        else\n        {\n            _3388 = _3381;\n        }\n        bool _3395;\n        if (!_3388)\n        {\n            _3395 = _3365 < 0.0f;\n        }\n        else\n        {\n            _3395 = _3388;\n        }\n        bool _3402;\n        if (!_3395)\n        {\n            _3402 = _3365 >= 1.0f;\n        }\n        else\n        {\n            _3402 = _3395;\n        }\n        if (_3402)\n        {\n            break;\n        }\n        float4 _3421 = fa_screen_tex.Load(int3(int2(float2(_3361, _3365) * _511_fa_ct_a.zw), 0));\n        if (_3421.w < 0.5f)\n        {\n            continue;\n        }\n        float _3440 = (dot(_511_fa_ct_fwd.xyz, _3324) + _511_fa_ct_fwd.w) - _3421.x;\n        if ((_3440 > _3288) && (_3440 < _3293))\n        {\n            occ = max(occ, (1.0f - (_3316 * _3316)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3361, 0.5f - _3360), min(_3365, 1.0f - _3365))));\n        }\n    }\n    return 1.0f - (occ * _3274);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3516 = fa_lm.z > 0.5f;\n    bool _3522;\n    if (_3516)\n    {\n        int param = li;\n        _3522 = fa_light_baked(param);\n    }\n    else\n    {\n        _3522 = _3516;\n    }\n    if (_3522)\n    {\n        int param_1 = li;\n        LightSample _4673 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4673;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3544 = fa_light_sample(param_2, param_3);\n    float3 _4680 = _3544.direction;\n    float3 _4675 = _3544.color;\n    float _4682 = _3544.attenuation;\n    float _4677 = _3544.shadow;\n    float _4684 = _3544._distance;\n    int _4685 = _3544.type;\n    bool _3547 = _4685 == 0;\n    if (_3547 && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4680;\n        float _3558 = fa_shadow_factor(param_4, param_5);\n        _4677 = _3558;\n        _4675 *= _3558;\n    }\n    else\n    {\n        bool _3569 = _4685 != 0;\n        bool _3575;\n        if (_3569)\n        {\n            _3575 = _4682 > 0.0f;\n        }\n        else\n        {\n            _3575 = _3569;\n        }\n        if (_3575)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4680;\n            float _3587 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4677 = _3587;\n            _4675 *= _3587;\n        }\n    }\n    bool _3597 = _511_fa_ct_a.x > 0.5f;\n    bool _3603;\n    if (_3597)\n    {\n        _3603 = _4682 > 0.0f;\n    }\n    else\n    {\n        _3603 = _3597;\n    }\n    if (_3603)\n    {\n        float _3610;\n        if (_3547)\n        {\n            _3610 = 1000000000.0f;\n        }\n        else\n        {\n            _3610 = _4684;\n        }\n        int param_10 = li;\n        float3 param_11 = world_pos;\n        float3 param_12 = gn;\n        float3 param_13 = _4680;\n        float param_14 = _3610;\n        float _3628 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14);\n        _4677 *= _3628;\n        _4675 *= _3628;\n    }\n    LightSample _4692 = { _4680, _4675, _4682, _4677, _4684, _4685 };\n    return _4692;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1251_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2208 = int(_1251_fa_shadow_cfg.x + 0.5f);\n    float _2218 = dot(world - _1251_fa_shadow_eye.xyz, _1251_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2223 = _2208 > 0;\n    bool _2232;\n    if (_2223)\n    {\n        int param = _2208 - 1;\n        _2232 = _2218 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2232 = _2223;\n    }\n    if (_2232)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2239 = _2208 > 1;\n        bool _2246;\n        if (_2239)\n        {\n            _2246 = _2218 > _1251_fa_shadow_split.x;\n        }\n        else\n        {\n            _2246 = _2239;\n        }\n        if (_2246)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2252 = _2208 > 2;\n        bool _2259;\n        if (_2252)\n        {\n            _2259 = _2218 > _1251_fa_shadow_split.y;\n        }\n        else\n        {\n            _2259 = _2252;\n        }\n        if (_2259)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2265 = _2208 > 3;\n        bool _2272;\n        if (_2265)\n        {\n            _2272 = _2218 > _1251_fa_shadow_split.z;\n        }\n        else\n        {\n            _2272 = _2265;\n        }\n        if (_2272)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4384 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4384 = -_4384;\n    }\n    float3 _4019 = normalize(_511_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4397 = { fa_world_pos, _4384, fa_world_tangent, fa_uv, fa_vertex_color, _4019, gl_FrontFacing };\n    SurfaceInput param_1 = _4397;\n    Surface _4027 = fa_standard_surface(param_1);\n    float3 _4423 = _4027.albedo;\n    float _4424 = _4027.alpha;\n    float3 _4425 = _4027.normal;\n    float _4426 = _4027.metallic;\n    float _4427 = _4027.roughness;\n    float _4428 = _4027.occlusion;\n    float3 _4429 = _4027.emission;\n    float _4430 = _4027.clearcoat;\n    float _4431 = _4027.clearcoat_roughness;\n    float3 _4432 = _4027.sheen_color;\n    float _4433 = _4027.sheen_roughness;\n    float _4434 = _4027.anisotropy;\n    float _4435 = _4027.anisotropy_rotation;\n    float _4436 = _4027.specular;\n    float _4437 = _4027.ior;\n    float3 _4438 = _4027.specular_color;\n    SurfaceInput _4405 = { fa_world_pos, _4384, fa_world_tangent, fa_uv, fa_vertex_color, _4019, gl_FrontFacing };\n    SurfaceInput param_2 = _4405;\n    Surface param_3 = _4027;\n    surface(param_2, param_3);\n    _4423 = param_3.albedo;\n    _4424 = param_3.alpha;\n    _4425 = param_3.normal;\n    _4426 = param_3.metallic;\n    _4427 = param_3.roughness;\n    _4428 = param_3.occlusion;\n    _4429 = param_3.emission;\n    _4430 = param_3.clearcoat;\n    _4431 = param_3.clearcoat_roughness;\n    _4432 = param_3.sheen_color;\n    _4433 = param_3.sheen_roughness;\n    _4434 = param_3.anisotropy;\n    _4435 = param_3.anisotropy_rotation;\n    _4436 = param_3.specular;\n    _4437 = param_3.ior;\n    _4438 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4384;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4423 = param_6;\n    _4425 = param_7;\n    float3 result;\n    if (_511_fa_emissive.w > 0.5f)\n    {\n        result = _4423;\n    }\n    else\n    {\n        float3 _4065 = _4425;\n        float3 _4066 = normalize(_4065);\n        _4425 = _4066;\n        float3 param_8 = _4066;\n        SurfaceInput _4413 = { fa_world_pos, _4384, fa_world_tangent, fa_uv, fa_vertex_color, _4019, gl_FrontFacing };\n        SurfaceInput param_9 = _4413;\n        Surface _4504 = { _4423, _4424, _4425, _4426, _4427, _4428, _4429, _4430, _4431, _4432, _4433, _4434, _4435, _4436, _4437, _4438 };\n        Surface param_10 = _4504;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4085 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4085; ln++)\n        {\n            int param_12 = ln;\n            int _4098 = fa_cl_light(param_12);\n            bool _4101 = fa_lm.z > 0.5f;\n            bool _4107;\n            if (_4101)\n            {\n                int param_13 = _4098;\n                _4107 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _4107 = _4101;\n            }\n            if (_4107)\n            {\n                continue;\n            }\n            int param_14 = _4098;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4384;\n            SurfaceInput _4421 = { fa_world_pos, _4384, fa_world_tangent, fa_uv, fa_vertex_color, _4019, gl_FrontFacing };\n            SurfaceInput param_17 = _4421;\n            Surface _4521 = { _4423, _4424, _4425, _4426, _4427, _4428, _4429, _4430, _4431, _4432, _4433, _4434, _4435, _4436, _4437, _4438 };\n            Surface param_18 = _4521;\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4134 = result;\n    float3 _4135 = _4134 + _4429;\n    result = _4135;\n    float3 param_20 = _4135;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4144 = _511_fa_fog.w > 0.0f;\n    bool _4151;\n    if (!_4144)\n    {\n        _4151 = _511_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4151 = _4144;\n    }\n    if (_4151)\n    {\n        float3 _4160 = fa_world_pos - _511_fa_camera_pos.xyz;\n        float _4166 = dot(_4160, _511_fa_fog_c.xyz);\n        bool _4170 = _511_fa_fog_c.w > 0.5f;\n        float _4171;\n        if (_4170)\n        {\n            _4171 = _4166;\n        }\n        else\n        {\n            _4171 = length(_4160);\n        }\n        float _4183 = _4171 - _511_fa_fog_b.x;\n        if (_4183 > 0.0f)\n        {\n            float _4192 = _511_fa_fog.w * _4183;\n            float tau = _4192 * _4192;\n            if (_511_fa_fog_b.y > 0.0f)\n            {\n                float _4208;\n                if (_4170)\n                {\n                    _4208 = fa_world_pos.y - (_511_fa_fog_c.y * _4166);\n                }\n                else\n                {\n                    _4208 = _511_fa_camera_pos.y;\n                }\n                float _4229 = lerp(_4208, fa_world_pos.y, clamp(_511_fa_fog_b.x / _4171, 0.0f, 1.0f));\n                float _4233 = fa_world_pos.y - _4229;\n                float _4238 = _4229 - _511_fa_fog_b.z;\n                float _4243 = fa_world_pos.y - _511_fa_fog_b.z;\n                bool _4246 = _4238 <= 0.0f;\n                bool _4247 = !_4246;\n                bool _4253;\n                if (_4247)\n                {\n                    _4253 = _511_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4253 = _4246;\n                }\n                float _4254;\n                if (_4253)\n                {\n                    _4254 = _511_fa_fog_b.y;\n                }\n                else\n                {\n                    _4254 = _511_fa_fog_b.y * exp(-min(_511_fa_fog_b.w * _4238, 80.0f));\n                }\n                bool _4281;\n                if (_4247)\n                {\n                    _4281 = _511_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4281 = _4246;\n                }\n                float _4282;\n                if (_4281)\n                {\n                    _4282 = _511_fa_fog_b.y * _4238;\n                }\n                else\n                {\n                    _4282 = (_511_fa_fog_b.y * (1.0f - exp(-min(_511_fa_fog_b.w * _4238, 80.0f)))) / _511_fa_fog_b.w;\n                }\n                bool _4307 = _4243 <= 0.0f;\n                bool _4314;\n                if (!_4307)\n                {\n                    _4314 = _511_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4314 = _4307;\n                }\n                float _4315;\n                if (_4314)\n                {\n                    _4315 = _511_fa_fog_b.y * _4243;\n                }\n                else\n                {\n                    _4315 = (_511_fa_fog_b.y * (1.0f - exp(-min(_511_fa_fog_b.w * _4243, 80.0f)))) / _511_fa_fog_b.w;\n                }\n                float _4342;\n                if (abs(_4233) < 0.001000000047497451305389404296875f)\n                {\n                    _4342 = _4254;\n                }\n                else\n                {\n                    _4342 = (_4315 - _4282) / _4233;\n                }\n                tau += (_4183 * max(_4342, 0.0f));\n            }\n            result = lerp(result, _511_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4424);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_511",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1251",
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
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 8
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 9
            }
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 10
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_388, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _2703[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _511_fa_camera_pos : packoffset(c0);\n    float4 _511_fa_ambient : packoffset(c1);\n    float4 _511_fa_base_color : packoffset(c2);\n    float4 _511_fa_emissive : packoffset(c3);\n    float4 _511_fa_model_emissive : packoffset(c4);\n    float4 _511_fa_pbr : packoffset(c5);\n    float4 _511_fa_maps : packoffset(c6);\n    float4 _511_fa_fog : packoffset(c7);\n    float4 _511_fa_fog_b : packoffset(c8);\n    float4 _511_fa_fog_c : packoffset(c9);\n    float4 _511_fa_counts : packoffset(c10);\n    float4 _511_fa_env_sky : packoffset(c11);\n    float4 _511_fa_env_horizon : packoffset(c12);\n    float4 _511_fa_time : packoffset(c13);\n    float4 _511_fa_cl_vpx : packoffset(c14);\n    float4 _511_fa_cl_vpy : packoffset(c15);\n    float4 _511_fa_cl_vpw : packoffset(c16);\n    float4 _511_fa_cl_fwd : packoffset(c17);\n    float4 _511_fa_cl_grid : packoffset(c18);\n    float4 _511_fa_cl_info : packoffset(c19);\n    float4 _511_fa_layers_a : packoffset(c20);\n    float4 _511_fa_layers_b : packoffset(c21);\n    float4 _511_fa_layers_c : packoffset(c22);\n    float4 _511_fa_layers_d : packoffset(c23);\n    float4 _511_fa_ct_a : packoffset(c24);\n    float4 _511_fa_ct_b : packoffset(c25);\n    float4 _511_fa_ct_vpx : packoffset(c26);\n    float4 _511_fa_ct_vpy : packoffset(c27);\n    float4 _511_fa_ct_vpw : packoffset(c28);\n    float4 _511_fa_ct_fwd : packoffset(c29);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1251_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1251_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1251_fa_shadow_info[4] : packoffset(c20);\n    float4 _1251_fa_shadow_split : packoffset(c24);\n    float4 _1251_fa_shadow_cfg : packoffset(c25);\n    float4 _1251_fa_shadow_bias : packoffset(c26);\n    float4 _1251_fa_shadow_eye : packoffset(c27);\n    float4 _1251_fa_shadow_fwd : packoffset(c28);\n    float4 _1251_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t8);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _516 = _511_fa_cl_info.x < 0.0f;\n    bool _523;\n    if (!_516)\n    {\n        _523 = _511_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _523 = _516;\n    }\n    bool _531;\n    if (!_523)\n    {\n        _531 = _511_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _531 = _523;\n    }\n    bool _538;\n    if (!_531)\n    {\n        _538 = _511_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _538 = _531;\n    }\n    bool _545;\n    if (!_538)\n    {\n        _545 = _511_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _545 = _538;\n    }\n    if (_545)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _555 = float4(world_pos, 1.0f);\n    float _562 = dot(_511_fa_cl_vpw, _555);\n    if (!(_562 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _584 = float2(dot(_511_fa_cl_vpx, _555), dot(_511_fa_cl_vpy, _555)) / _562.xx;\n    int _588 = int(_511_fa_cl_grid.x);\n    int _592 = int(_511_fa_cl_grid.y);\n    int param = (int(_511_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_511_fa_cl_fwd.xyz, world_pos) + _511_fa_cl_fwd.w, _511_fa_cl_grid.w) / _511_fa_cl_grid.w) * _511_fa_cl_grid.z)), 0, int(_511_fa_cl_info.y) - 1) * _592) + clamp(int(floor(((_584.y * 0.5f) + 0.5f) * _511_fa_cl_grid.y)), 0, _592 - 1)) * _588)) + clamp(int(floor(((_584.x * 0.5f) + 0.5f) * _511_fa_cl_grid.x)), 0, _588 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _668 = fa_cluster_texel(param);\n    return int2(int(_668.x), int(_668.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_511_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3489 = fa_cluster_lookup(param);\n    fa_cl_slot = _3489.x;\n    fa_cl_local = _3489.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3687 = fa_linear_to_srgb(param);\n        c = _3687;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3695 = fa_srgb_to_linear(param_1);\n            c = _3695;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _276;\n    if (i.front_facing)\n    {\n        _276 = i.world_normal;\n    }\n    else\n    {\n        _276 = -i.world_normal;\n    }\n    float3 _300 = normalize(i.world_tangent.xyz - (_276 * dot(_276, i.world_tangent.xyz)));\n    float3 _327 = normalize(((_300 * m.x) + ((cross(_276, _300) * i.world_tangent.w) * m.y)) + (_276 * m.z));\n    float3 _330;\n    if (i.front_facing)\n    {\n        _330 = _327;\n    }\n    else\n    {\n        _330 = -_327;\n    }\n    return _330;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _511_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3726 = fa_tex_fix(param_2, param_3);\n    float4 _4841 = base_t;\n    _4841.x = _3726.x;\n    _4841.y = _3726.y;\n    _4841.z = _3726.z;\n    base_t = _4841;\n    float4 _3740 = (_4841 * _511_fa_base_color) * i.vertex_color;\n    float3 _4695 = i.world_normal;\n    if (_511_fa_maps.z > 0.5f)\n    {\n        float param_4 = _511_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3772 = fa_tex_fix(param_6, param_7);\n        float3 _3775 = (_3772 * 2.0f) - 1.0f.xxx;\n        float2 _3780 = _3775.xy * _511_fa_maps.x;\n        float3 _4849 = _3775;\n        _4849.x = _3780.x;\n        _4849.y = _3780.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4849;\n        _4695 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _511_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3809 = fa_tex_fix(param_12, param_13);\n    float4 _4852 = mrt;\n    _4852.x = _3809.x;\n    _4852.y = _3809.y;\n    _4852.z = _3809.z;\n    mrt = _4852;\n    float4 _3837 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _511_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3837.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3849 = fa_tex_fix(param_16, param_17);\n    float param_18 = _511_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3879 = fa_tex_fix(param_20, param_21);\n    float _4700 = _511_fa_layers_a.x;\n    float _4701 = _511_fa_layers_a.y;\n    float _4704 = _511_fa_layers_a.z;\n    float _4703 = _511_fa_layers_b.w;\n    float _4706 = _511_fa_layers_c.x;\n    if (_511_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_511_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4700 *= _3849.y;\n            _4701 *= _3849.z;\n            _4703 *= _3837.w;\n        }\n        if (_511_fa_layers_c.z > 1.5f)\n        {\n            _4704 *= mrt.x;\n            _4706 *= mrt.w;\n        }\n    }\n    Surface _4725 = { _3740.xyz, _3740.w, _4695, clamp(_511_fa_pbr.x * _3809.z, 0.0f, 1.0f), clamp(_511_fa_pbr.y * _3809.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_511_fa_maps.y * (_3849.x - 1.0f)), _511_fa_emissive.xyz + (_511_fa_model_emissive.xyz * _3879), _4700, _4701, _511_fa_layers_b.xyz, _4703, _4704, _511_fa_layers_a.w, _4706, _511_fa_layers_c.y, _511_fa_layers_d.xyz };\n    return _4725;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _749 = rect.zw - rect.xy;\n    float2 _753 = _749 * atlas;\n    float2 _757 = ddx * _753;\n    float2 _761 = ddy * _753;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _749), clamp(0.5f * log2(max(max(dot(_757, _757), dot(_761, _761)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _796 = _511_fa_counts.y < 0.5f;\n    bool _803;\n    if (!_796)\n    {\n        _803 = _511_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _803 = _796;\n    }\n    if (_803)\n    {\n        return;\n    }\n    float3 _809 = ddx(world_pos);\n    float3 _812 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _816 = fa_cluster_texel(param);\n    int _820 = int(_816.w);\n    if (_820 < 1)\n    {\n        return;\n    }\n    int _830 = int(_511_fa_counts.y + 0.5f);\n    int param_1 = _830;\n    float4 _834 = fa_light_texel(param_1);\n    float2 _837 = _834.yz;\n    int _841 = int(_834.w);\n    int param_2 = _830 + 1;\n    float4 _846 = fa_light_texel(param_2);\n    float _847 = _846.x;\n    int _853 = int(_511_fa_counts.w + 0.5f) - 1;\n    int _857 = int(_816.z);\n    float3 _1123;\n    for (int k = 0; k < _820; k++)\n    {\n        int _870 = _857 + k;\n        int param_3 = _841 + (_870 >> 2);\n        int _888 = (_830 + 2) + (int(fa_light_texel(param_3)[_870 & 3]) * 7);\n        int param_4 = _888 + 6;\n        float4 _893 = fa_light_texel(param_4);\n        if (((int(_893.w + 0.5f) >> _853) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _888;\n        float4 _908 = fa_light_texel(param_5);\n        int param_6 = _888 + 1;\n        float4 _913 = fa_light_texel(param_6);\n        int param_7 = _888 + 2;\n        float4 _918 = fa_light_texel(param_7);\n        float3 _921 = _908.xyz;\n        float _926 = dot(_921, world_pos) + _908.w;\n        float3 _928 = _913.xyz;\n        float _933 = dot(_928, world_pos) + _913.w;\n        float3 _935 = _918.xyz;\n        float _940 = dot(_935, world_pos) + _918.w;\n        bool _945 = abs(_926) > 0.5f;\n        bool _953;\n        if (!_945)\n        {\n            _953 = abs(_933) > 0.5f;\n        }\n        else\n        {\n            _953 = _945;\n        }\n        bool _961;\n        if (!_953)\n        {\n            _961 = abs(_940) > 0.5f;\n        }\n        else\n        {\n            _961 = _953;\n        }\n        if (_961)\n        {\n            continue;\n        }\n        float _976 = clamp(dot(geo_normal, normalize(_935)) * _893.z, 0.0f, 1.0f);\n        if (_976 <= 0.0f)\n        {\n            continue;\n        }\n        float _996 = (clamp((0.5f - abs(_940)) * 10.0f, 0.0f, 1.0f) * _976) * _893.x;\n        float2 _1004 = float2(_926 + 0.5f, 0.5f - _933);\n        float2 _1014 = float2(dot(_921, _809), dot(_928, _809));\n        float2 _1024 = float2(dot(_921, _812), dot(_928, _812));\n        int param_8 = _888 + 5;\n        float4 _1029 = fa_light_texel(param_8);\n        int param_9 = _888 + 3;\n        float4 _1034 = fa_light_texel(param_9);\n        int param_10 = _888 + 4;\n        float4 _1039 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1029.xyz;\n        bool _1049 = _1034.z > _1034.x;\n        if (_1049)\n        {\n            float4 param_11 = _1034;\n            float2 param_12 = _1004;\n            float2 param_13 = _837;\n            float2 param_14 = _1014;\n            float2 param_15 = _1024;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_847 > 0.5f) && (_847 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1075 = fa_dc_to_linear(param_16);\n                float4 _4751 = tx;\n                _4751.x = _1075.x;\n                _4751.y = _1075.y;\n                _4751.z = _1075.z;\n                tx = _4751;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_996 * tex_a) * _1029.w, 0.0f, 1.0f).xxx);\n        if (_1039.z > _1039.x)\n        {\n            float4 param_17 = _1039;\n            float2 param_18 = _1004;\n            float2 param_19 = _837;\n            float2 param_20 = _1014;\n            float2 param_21 = _1024;\n            float4 _1119 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_847 > 1.5f)\n            {\n                float3 param_22 = _1119.xyz;\n                float3 _1129 = fa_dc_to_srgb(param_22);\n                _1123 = _1129;\n            }\n            else\n            {\n                _1123 = _1119.xyz;\n            }\n            float3 _1139 = (_1123 * 2.0f) - 1.0f.xxx;\n            float2 _1144 = _1139.xy * _893.y;\n            float3 _1166 = (normalize(_921) * _1144.x) + (normalize(_928) * _1144.y);\n            float3 _1169 = normalize(normal);\n            normal = normalize(lerp(_1169, normalize((_1169 * max(_1139.z, 0.0500000007450580596923828125f)) + (_1166 - (_1169 * dot(_1169, _1166)))), clamp(_996 * (_1049 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_511_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _2386 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _2386;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_511_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _511_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2629 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _2636 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _2639 = int(_2629);\n    int _2642 = int(_2636);\n    float _2652 = _2636 - float(_2642);\n    int _2707 = (_2639 * 9) + _2642;\n    int _2727 = ((_2639 + 1) * 9) + _2642;\n    return lerp(lerp(_2703[_2707], _2703[_2707 + 1], _2652), lerp(_2703[_2727], _2703[_2727 + 1], _2652), _2629 - float(_2639));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4554 = false;\n    float _4555 = 1.0f;\n    float _4556 = 1.0f;\n    float _4557 = 1.0f;\n    float _4558 = 0.0f;\n    float _4559 = 0.0f;\n    float _4560 = 0.0f;\n    float _4561 = 0.0f;\n    float _4563 = 1.0f;\n    bool _4564 = false;\n    float3 _4565 = 0.0f.xxx;\n    float _4566 = 1.0f;\n    float _4567 = 1.0f;\n    float _4568 = 1.0f;\n    float _4569 = 0.0f;\n    float _4570 = 0.0f;\n    float3 _4571 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4572 = float3(0.0f, 0.0f, 1.0f);\n    float _4573 = 1.0f;\n    float _4574 = 1.0f;\n    float _2780 = clamp(s.specular, 0.0f, 1.0f);\n    float _2784 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2789 = (_2780 != 1.0f) || (_2784 != 1.5f);\n    bool _2799;\n    if (!_2789)\n    {\n        _2799 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2799 = _2789;\n    }\n    if (_2799)\n    {\n        float _2807 = (_2784 - 1.0f) / (_2784 + 1.0f);\n        f0 = lerp(min((_2807 * _2807).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2780, s.albedo, metallic.xxx);\n        _4555 = lerp(_2780, 1.0f, metallic);\n        _4554 = true;\n    }\n    float _2835 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2835 > 0.0f)\n    {\n        float _2843 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4558 = _2835;\n        _4559 = _2843;\n        float _2850 = _2843 * _2843;\n        _4560 = _2850;\n        _4561 = _2850 * _2850;\n        float _2862 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4563 = _2862;\n        _4556 = 1.0f - (_2835 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2862, 0.0f, 1.0f), 5.0f))));\n        _4554 = true;\n    }\n    float3 _2881 = max(s.sheen_color, 0.0f.xxx);\n    float _2890 = max(_2881.x, max(_2881.y, _2881.z));\n    if (_2890 > 0.0f)\n    {\n        float _2898 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4564 = true;\n        _4565 = _2881;\n        _4566 = _2898;\n        _4567 = _2898 * _2898;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2898;\n        float _2915 = fa_sheen_albedo(param, param_1);\n        _4569 = _2915;\n        _4568 = 1.0f - min(_2890 * _2915, 1.0f);\n        _4554 = true;\n    }\n    _4557 = _4556 * _4568;\n    float _2934 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2934 != 0.0f)\n    {\n        float3 _2949 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2949;\n        if (dot(_2949, _2949) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2962 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2962.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2962.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2962.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2966 = t;\n        float3 _2967 = normalize(_2966);\n        t = _2967;\n        float3 _2992 = normalize((_2967 * cos(s.anisotropy_rotation)) + ((cross(n, _2967) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4571 = _2992;\n        _4572 = cross(n, _2992);\n        float _3002 = roughness * roughness;\n        float _3008 = lerp(_3002, 1.0f, _2934 * _2934);\n        bool _3010 = _2934 > 0.0f;\n        _4573 = _3010 ? _3008 : _3002;\n        _4574 = _3010 ? _3002 : _3008;\n        _4570 = _2934;\n        _4554 = true;\n    }\n    FaLayers _4596 = { _4554, _4555, _4556, _4557, _4558, _4559, _4560, _4561, i.world_normal, _4563, _4564, _4565, _4566, _4567, _4568, _4569, _4570, _4571, _4572, _4573, _4574 };\n    return _4596;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _2561 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _2564 = _2561.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_2564 * _2564, exp2((-9.27999973297119140625f) * ndv)) * _2564) + _2561.y)) + _2561.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_511_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _511_fa_env_horizon.w).xyz;\n    }\n    float _2415 = rough * rough;\n    float _2445 = 0.60000002384185791015625f * _2415;\n    return lerp(lerp(_511_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_511_fa_env_horizon.xyz, _511_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _2415)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _2445, 0.0500000007450580596923828125f + _2445, d.y).xxx), ((_511_fa_env_sky.xyz + _511_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_2415 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3043;\n        if (L.aniso >= 0.0f)\n        {\n            _3043 = L.b;\n        }\n        else\n        {\n            _3043 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3043, v), _3043), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3076 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3076.x) + (L.f90.xxx * _3076.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3131 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3131.x) + _3131.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2603 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2603.x) + _2603.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3160 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3164 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3171 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3160.xxx);\n    float3 f0 = _3171;\n    float3 _3175 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3175;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3160;\n    float param_5 = _3164;\n    float3 param_6 = _3171;\n    FaLayers _3192 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3192.on)\n    {\n        FaLayers param_7 = _3192;\n        float3 param_8 = _3175;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3164;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3175;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3164;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_511_fa_cl_info.x) + int(_511_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _386 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _392 = fa_light_texel(param_1);\n    float _395 = _392.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _401 = _395 < 0.5f;\n    float3 l;\n    if (_401)\n    {\n        l = normalize(_386.xyz);\n    }\n    else\n    {\n        float3 _413 = _386.xyz - world_pos;\n        float _415 = length(_413);\n        dist = _415;\n        l = _413 / max(_415, 9.9999997473787516355514526367188e-05f).xxx;\n        float _430 = _415 / max(_386.w, 0.001000000047497451305389404296875f);\n        float _436 = clamp(1.0f - (_430 * _430), 0.0f, 1.0f);\n        atten = _436 * _436;\n        if (_395 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _450 = fa_light_texel(param_2);\n            float _460 = _450.w;\n            int param_3 = (li * 4) + 3;\n            float4 _466 = fa_light_texel(param_3);\n            float _467 = _466.x;\n            float cos_inner = _467;\n            if (_467 > 1.5f)\n            {\n                cos_inner = lerp(_460, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_460, cos_inner, dot(-l, normalize(_450.xyz)));\n        }\n    }\n    int _497;\n    if (_401)\n    {\n        _497 = 0;\n    }\n    else\n    {\n        _497 = (_395 > 1.5f) ? 2 : 1;\n    }\n    LightSample _4553 = { l, _392.xyz * atten, atten, 1.0f, dist, _497 };\n    return _4553;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1241;\n    if (i == 0)\n    {\n        _1241 = _1251_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1257;\n        if (i == 1)\n        {\n            _1257 = _1251_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1265;\n            if (i == 2)\n            {\n                _1265 = _1251_fa_shadow_split.z;\n            }\n            else\n            {\n                _1265 = _1251_fa_shadow_split.w;\n            }\n            _1257 = _1265;\n        }\n        _1241 = _1257;\n    }\n    return _1241;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1298 = fa_shadow_depth(param, param_1);\n    float _1302;\n    if (conv.x < 0.5f)\n    {\n        _1302 = _1298;\n    }\n    else\n    {\n        _1302 = (conv.y * conv.z) / (conv.z - (_1298 * (conv.z - conv.y)));\n    }\n    return _1302;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1229 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1229), sin(_1229)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1348 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1362 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1348;\n            float2 _1381 = fa_shadow_vogel(param_3, param_4, param_5) * _1362;\n            float2 param_6 = uv + (_1381 * _1251_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1393 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1393 < (zr - (length(_1381) * plane)))\n            {\n                sum += _1393;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1437 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1437; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1437;\n        float param_11 = _1348;\n        float2 _1456 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1456 * _1251_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1456) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1437);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1498 = max(_1251_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1503 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1509 = sqrt(1.0f - (_1503 * _1503));\n    float _1516 = min(_1509 / max(_1503, 0.20000000298023223876953125f), 4.0f);\n    float _1521;\n    if (_1251_fa_shadow_bias.y > 0.0f)\n    {\n        _1521 = _1251_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1521 = 1.5f * _1251_fa_shadow_info[ci].x;\n    }\n    float4 _1546 = mul(float4(world + (n * (_1521 * _1509)), 1.0f), _1251_fa_shadow_mat[ci]);\n    float _1553 = _1546.x;\n    bool _1556 = _1553 < _1251_fa_shadow_rect[ci].x;\n    bool _1565;\n    if (!_1556)\n    {\n        _1565 = _1553 > _1251_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1565 = _1556;\n    }\n    bool _1574;\n    if (!_1565)\n    {\n        _1574 = _1546.y < _1251_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1574 = _1565;\n    }\n    bool _1583;\n    if (!_1574)\n    {\n        _1583 = _1546.y > _1251_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1583 = _1574;\n    }\n    bool _1590;\n    if (!_1583)\n    {\n        _1590 = _1546.z > 1.0f;\n    }\n    else\n    {\n        _1590 = _1583;\n    }\n    if (_1590)\n    {\n        return -1.0f;\n    }\n    float _1599;\n    if (_1251_fa_shadow_bias.x > 0.0f)\n    {\n        _1599 = _1251_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1599 = 1.5f * _1251_fa_shadow_info[ci].x;\n    }\n    float2 param = _1546.xy;\n    float4 param_1 = _1251_fa_shadow_rect[ci];\n    float param_2 = _1546.z - ((_1599 * (1.0f + (0.5f * _1516))) / _1498);\n    float param_3 = _1251_fa_shadow_info[ci].x;\n    float param_4 = _1498;\n    float param_5 = _1498 * 0.25f;\n    float param_6 = ((_1251_fa_shadow_info[ci].x * min(_1516, 3.0f)) * 0.5f) / _1498;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1251_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1251_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_511_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2026 = int(_1251_fa_shadow_cfg.x + 0.5f);\n    if (_2026 < 1)\n    {\n        return 1.0f;\n    }\n    float _2041 = dot(world - _1251_fa_shadow_eye.xyz, _1251_fa_shadow_fwd.xyz);\n    int param = _2026 - 1;\n    if (_2041 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2053 = _2026 > 1;\n    bool _2060;\n    if (_2053)\n    {\n        _2060 = _2041 > _1251_fa_shadow_split.x;\n    }\n    else\n    {\n        _2060 = _2053;\n    }\n    if (_2060)\n    {\n        ci = 1;\n    }\n    bool _2064 = _2026 > 2;\n    bool _2071;\n    if (_2064)\n    {\n        _2071 = _2041 > _1251_fa_shadow_split.y;\n    }\n    else\n    {\n        _2071 = _2064;\n    }\n    if (_2071)\n    {\n        ci = 2;\n    }\n    bool _2075 = _2026 > 3;\n    bool _2082;\n    if (_2075)\n    {\n        _2082 = _2041 > _1251_fa_shadow_split.z;\n    }\n    else\n    {\n        _2082 = _2075;\n    }\n    if (_2082)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2026)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2108 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2108;\n        if (_2108 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1251_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2133;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2133 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2133 = _1251_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2152 = _1251_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2133, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2163 = clamp((_2041 - (fa_shadow_split_at(param_7) - _2152)) / _2152, 0.0f, 1.0f);\n        if (_2163 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2026)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2184 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2184;\n                if (_2184 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2163);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1657 = _511_fa_pbr.z < 0.5f;\n    bool _1665;\n    if (!_1657)\n    {\n        _1665 = _1251_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1665 = _1657;\n    }\n    if (_1665)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1251_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1678 = fa_light_texel(param);\n    float _1679 = _1678.x;\n    if (_1679 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1688 = int(_1679 + 0.5f);\n    int param_1 = _1688;\n    float4 _1692 = fa_light_texel(param_1);\n    int param_2 = _1688 + 1;\n    float4 _1697 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1700 = _1692.y;\n    if (_1700 > 0.0f)\n    {\n        float _1717 = 1.0f - smoothstep(0.75f * _1700, _1700, length(world - _1251_fa_shadow_eye.xyz));\n        fade = _1717;\n        if (_1717 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1692.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1736 = world - fa_light_texel(param_3).xyz;\n        float3 _1739 = abs(_1736);\n        float _1741 = _1739.x;\n        float _1743 = _1739.y;\n        bool _1744 = _1741 >= _1743;\n        bool _1752;\n        if (_1744)\n        {\n            _1752 = _1741 >= _1739.z;\n        }\n        else\n        {\n            _1752 = _1744;\n        }\n        int _1753;\n        if (_1752)\n        {\n            _1753 = (_1736.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1766;\n            if (_1743 >= _1739.z)\n            {\n                _1766 = (_1736.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1766 = (_1736.z > 0.0f) ? 4 : 5;\n            }\n            _1753 = _1766;\n        }\n        face = _1753;\n    }\n    int _1785 = (_1688 + 2) + (face * 6);\n    int param_4 = _1785;\n    int param_5 = _1785 + 1;\n    int param_6 = _1785 + 3;\n    float4 _1799 = fa_light_texel(param_6);\n    int param_7 = _1785 + 4;\n    float4 _1804 = fa_light_texel(param_7);\n    int param_8 = _1785 + 5;\n    float4 _1809 = fa_light_texel(param_8);\n    float _1821 = _1809.x * max(dot(_1799, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1826 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1849 = clamp(dot(n, _1799.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1872 = min(sqrt(1.0f - (_1849 * _1849)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1799, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1875 = _1697.y;\n    float _1877;\n    if (_1875 > 0.0f)\n    {\n        _1877 = _1875;\n    }\n    else\n    {\n        _1877 = 1.5f * _1821;\n    }\n    float4 _1897 = float4(world + (n * (_1877 * sqrt(1.0f - (_1826 * _1826)))), 1.0f);\n    float _1901 = dot(_1799, _1897);\n    float _1904 = _1809.y;\n    if (_1901 < _1904)\n    {\n        return 1.0f;\n    }\n    float2 _1919 = float2(dot(fa_light_texel(param_4), _1897), dot(fa_light_texel(param_5), _1897)) / _1901.xx;\n    float _1921 = _1919.x;\n    bool _1924 = _1921 < _1804.x;\n    bool _1933;\n    if (!_1924)\n    {\n        _1933 = _1921 > _1804.z;\n    }\n    else\n    {\n        _1933 = _1924;\n    }\n    bool _1942;\n    if (!_1933)\n    {\n        _1942 = _1919.y < _1804.y;\n    }\n    else\n    {\n        _1942 = _1933;\n    }\n    bool _1951;\n    if (!_1942)\n    {\n        _1951 = _1919.y > _1804.w;\n    }\n    else\n    {\n        _1951 = _1942;\n    }\n    if (_1951)\n    {\n        return 1.0f;\n    }\n    float _1957 = _1697.x;\n    float _1959;\n    if (_1957 > 0.0f)\n    {\n        _1959 = _1957;\n    }\n    else\n    {\n        _1959 = 1.5f * _1821;\n    }\n    float2 param_10 = _1919;\n    float4 param_11 = _1804;\n    float param_12 = _1901 - (_1959 * (1.0f + (0.5f * _1872)));\n    float param_13 = _1821;\n    float param_14 = 1.0f;\n    float param_15 = _1809.z * 0.25f;\n    float param_16 = (_1821 * min(_1872, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1904, _1809.z);\n    int param_18 = int(_1692.z + 0.5f);\n    float param_19 = _1692.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3231 = _511_fa_ct_a.x < 0.5f;\n    bool _3238;\n    if (!_3231)\n    {\n        _3238 = _1251_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3238 = _3231;\n    }\n    if (_3238)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1251_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3251 = fa_light_texel(param);\n    float _3252 = _3251.y;\n    float len = _3252;\n    if (_3252 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3264 = length(world - _511_fa_camera_pos.xyz);\n    float _3274 = 1.0f - smoothstep(0.5f * _511_fa_ct_b.x, _511_fa_ct_b.x, _3264);\n    if (_3274 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3280 = len;\n    float _3283 = min(_3280, 0.89999997615814208984375f * dist);\n    len = _3283;\n    float _3288 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3264);\n    float _3293 = _3288 + (0.5f * _3283);\n    float3 _3299 = world + (gn * _3288);\n    float _3301 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3365;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3316 = (float(k) + _3301) * 0.083333335816860198974609375f;\n        float3 _3324 = _3299 + (l * (_3316 * len));\n        float4 _3330 = float4(_3324, 1.0f);\n        float _3336 = dot(_511_fa_ct_vpw, _3330);\n        if (_3336 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3356 = float2(dot(_511_fa_ct_vpx, _3330), dot(_511_fa_ct_vpy, _3330)) / _3336.xx;\n        float _3360 = _3356.x * 0.5f;\n        float _3361 = _3360 + 0.5f;\n        if (_511_fa_ct_a.y > 0.5f)\n        {\n            _3365 = (_3356.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3365 = 0.5f - (_3356.y * 0.5f);\n        }\n        bool _3381 = _3361 < 0.0f;\n        bool _3388;\n        if (!_3381)\n        {\n            _3388 = _3361 >= 1.0f;\n        }\n        else\n        {\n            _3388 = _3381;\n        }\n        bool _3395;\n        if (!_3388)\n        {\n            _3395 = _3365 < 0.0f;\n        }\n        else\n        {\n            _3395 = _3388;\n        }\n        bool _3402;\n        if (!_3395)\n        {\n            _3402 = _3365 >= 1.0f;\n        }\n        else\n        {\n            _3402 = _3395;\n        }\n        if (_3402)\n        {\n            break;\n        }\n        float4 _3421 = fa_screen_tex.Load(int3(int2(float2(_3361, _3365) * _511_fa_ct_a.zw), 0));\n        if (_3421.w < 0.5f)\n        {\n            continue;\n        }\n        float _3440 = (dot(_511_fa_ct_fwd.xyz, _3324) + _511_fa_ct_fwd.w) - _3421.x;\n        if ((_3440 > _3288) && (_3440 < _3293))\n        {\n            occ = max(occ, (1.0f - (_3316 * _3316)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3361, 0.5f - _3360), min(_3365, 1.0f - _3365))));\n        }\n    }\n    return 1.0f - (occ * _3274);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3516 = fa_lm.z > 0.5f;\n    bool _3522;\n    if (_3516)\n    {\n        int param = li;\n        _3522 = fa_light_baked(param);\n    }\n    else\n    {\n        _3522 = _3516;\n    }\n    if (_3522)\n    {\n        int param_1 = li;\n        LightSample _4673 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4673;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3544 = fa_light_sample(param_2, param_3);\n    float3 _4680 = _3544.direction;\n    float3 _4675 = _3544.color;\n    float _4682 = _3544.attenuation;\n    float _4677 = _3544.shadow;\n    float _4684 = _3544._distance;\n    int _4685 = _3544.type;\n    bool _3547 = _4685 == 0;\n    if (_3547 && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4680;\n        float _3558 = fa_shadow_factor(param_4, param_5);\n        _4677 = _3558;\n        _4675 *= _3558;\n    }\n    else\n    {\n        bool _3569 = _4685 != 0;\n        bool _3575;\n        if (_3569)\n        {\n            _3575 = _4682 > 0.0f;\n        }\n        else\n        {\n            _3575 = _3569;\n        }\n        if (_3575)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4680;\n            float _3587 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4677 = _3587;\n            _4675 *= _3587;\n        }\n    }\n    bool _3597 = _511_fa_ct_a.x > 0.5f;\n    bool _3603;\n    if (_3597)\n    {\n        _3603 = _4682 > 0.0f;\n    }\n    else\n    {\n        _3603 = _3597;\n    }\n    if (_3603)\n    {\n        float _3610;\n        if (_3547)\n        {\n            _3610 = 1000000000.0f;\n        }\n        else\n        {\n            _3610 = _4684;\n        }\n        int param_10 = li;\n        float3 param_11 = world_pos;\n        float3 param_12 = gn;\n        float3 param_13 = _4680;\n        float param_14 = _3610;\n        float _3628 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14);\n        _4677 *= _3628;\n        _4675 *= _3628;\n    }\n    LightSample _4692 = { _4680, _4675, _4682, _4677, _4684, _4685 };\n    return _4692;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1251_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2208 = int(_1251_fa_shadow_cfg.x + 0.5f);\n    float _2218 = dot(world - _1251_fa_shadow_eye.xyz, _1251_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2223 = _2208 > 0;\n    bool _2232;\n    if (_2223)\n    {\n        int param = _2208 - 1;\n        _2232 = _2218 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2232 = _2223;\n    }\n    if (_2232)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2239 = _2208 > 1;\n        bool _2246;\n        if (_2239)\n        {\n            _2246 = _2218 > _1251_fa_shadow_split.x;\n        }\n        else\n        {\n            _2246 = _2239;\n        }\n        if (_2246)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2252 = _2208 > 2;\n        bool _2259;\n        if (_2252)\n        {\n            _2259 = _2218 > _1251_fa_shadow_split.y;\n        }\n        else\n        {\n            _2259 = _2252;\n        }\n        if (_2259)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2265 = _2208 > 3;\n        bool _2272;\n        if (_2265)\n        {\n            _2272 = _2218 > _1251_fa_shadow_split.z;\n        }\n        else\n        {\n            _2272 = _2265;\n        }\n        if (_2272)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4384 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4384 = -_4384;\n    }\n    float3 _4019 = normalize(_511_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4397 = { fa_world_pos, _4384, fa_world_tangent, fa_uv, fa_vertex_color, _4019, gl_FrontFacing };\n    SurfaceInput param_1 = _4397;\n    Surface _4027 = fa_standard_surface(param_1);\n    float3 _4423 = _4027.albedo;\n    float _4424 = _4027.alpha;\n    float3 _4425 = _4027.normal;\n    float _4426 = _4027.metallic;\n    float _4427 = _4027.roughness;\n    float _4428 = _4027.occlusion;\n    float3 _4429 = _4027.emission;\n    float _4430 = _4027.clearcoat;\n    float _4431 = _4027.clearcoat_roughness;\n    float3 _4432 = _4027.sheen_color;\n    float _4433 = _4027.sheen_roughness;\n    float _4434 = _4027.anisotropy;\n    float _4435 = _4027.anisotropy_rotation;\n    float _4436 = _4027.specular;\n    float _4437 = _4027.ior;\n    float3 _4438 = _4027.specular_color;\n    SurfaceInput _4405 = { fa_world_pos, _4384, fa_world_tangent, fa_uv, fa_vertex_color, _4019, gl_FrontFacing };\n    SurfaceInput param_2 = _4405;\n    Surface param_3 = _4027;\n    surface(param_2, param_3);\n    _4423 = param_3.albedo;\n    _4424 = param_3.alpha;\n    _4425 = param_3.normal;\n    _4426 = param_3.metallic;\n    _4427 = param_3.roughness;\n    _4428 = param_3.occlusion;\n    _4429 = param_3.emission;\n    _4430 = param_3.clearcoat;\n    _4431 = param_3.clearcoat_roughness;\n    _4432 = param_3.sheen_color;\n    _4433 = param_3.sheen_roughness;\n    _4434 = param_3.anisotropy;\n    _4435 = param_3.anisotropy_rotation;\n    _4436 = param_3.specular;\n    _4437 = param_3.ior;\n    _4438 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4384;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4423 = param_6;\n    _4425 = param_7;\n    float3 result;\n    if (_511_fa_emissive.w > 0.5f)\n    {\n        result = _4423;\n    }\n    else\n    {\n        float3 _4065 = _4425;\n        float3 _4066 = normalize(_4065);\n        _4425 = _4066;\n        float3 param_8 = _4066;\n        SurfaceInput _4413 = { fa_world_pos, _4384, fa_world_tangent, fa_uv, fa_vertex_color, _4019, gl_FrontFacing };\n        SurfaceInput param_9 = _4413;\n        Surface _4504 = { _4423, _4424, _4425, _4426, _4427, _4428, _4429, _4430, _4431, _4432, _4433, _4434, _4435, _4436, _4437, _4438 };\n        Surface param_10 = _4504;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4085 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4085; ln++)\n        {\n            int param_12 = ln;\n            int _4098 = fa_cl_light(param_12);\n            bool _4101 = fa_lm.z > 0.5f;\n            bool _4107;\n            if (_4101)\n            {\n                int param_13 = _4098;\n                _4107 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _4107 = _4101;\n            }\n            if (_4107)\n            {\n                continue;\n            }\n            int param_14 = _4098;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4384;\n            SurfaceInput _4421 = { fa_world_pos, _4384, fa_world_tangent, fa_uv, fa_vertex_color, _4019, gl_FrontFacing };\n            SurfaceInput param_17 = _4421;\n            Surface _4521 = { _4423, _4424, _4425, _4426, _4427, _4428, _4429, _4430, _4431, _4432, _4433, _4434, _4435, _4436, _4437, _4438 };\n            Surface param_18 = _4521;\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4134 = result;\n    float3 _4135 = _4134 + _4429;\n    result = _4135;\n    float3 param_20 = _4135;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4144 = _511_fa_fog.w > 0.0f;\n    bool _4151;\n    if (!_4144)\n    {\n        _4151 = _511_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4151 = _4144;\n    }\n    if (_4151)\n    {\n        float3 _4160 = fa_world_pos - _511_fa_camera_pos.xyz;\n        float _4166 = dot(_4160, _511_fa_fog_c.xyz);\n        bool _4170 = _511_fa_fog_c.w > 0.5f;\n        float _4171;\n        if (_4170)\n        {\n            _4171 = _4166;\n        }\n        else\n        {\n            _4171 = length(_4160);\n        }\n        float _4183 = _4171 - _511_fa_fog_b.x;\n        if (_4183 > 0.0f)\n        {\n            float _4192 = _511_fa_fog.w * _4183;\n            float tau = _4192 * _4192;\n            if (_511_fa_fog_b.y > 0.0f)\n            {\n                float _4208;\n                if (_4170)\n                {\n                    _4208 = fa_world_pos.y - (_511_fa_fog_c.y * _4166);\n                }\n                else\n                {\n                    _4208 = _511_fa_camera_pos.y;\n                }\n                float _4229 = lerp(_4208, fa_world_pos.y, clamp(_511_fa_fog_b.x / _4171, 0.0f, 1.0f));\n                float _4233 = fa_world_pos.y - _4229;\n                float _4238 = _4229 - _511_fa_fog_b.z;\n                float _4243 = fa_world_pos.y - _511_fa_fog_b.z;\n                bool _4246 = _4238 <= 0.0f;\n                bool _4247 = !_4246;\n                bool _4253;\n                if (_4247)\n                {\n                    _4253 = _511_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4253 = _4246;\n                }\n                float _4254;\n                if (_4253)\n                {\n                    _4254 = _511_fa_fog_b.y;\n                }\n                else\n                {\n                    _4254 = _511_fa_fog_b.y * exp(-min(_511_fa_fog_b.w * _4238, 80.0f));\n                }\n                bool _4281;\n                if (_4247)\n                {\n                    _4281 = _511_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4281 = _4246;\n                }\n                float _4282;\n                if (_4281)\n                {\n                    _4282 = _511_fa_fog_b.y * _4238;\n                }\n                else\n                {\n                    _4282 = (_511_fa_fog_b.y * (1.0f - exp(-min(_511_fa_fog_b.w * _4238, 80.0f)))) / _511_fa_fog_b.w;\n                }\n                bool _4307 = _4243 <= 0.0f;\n                bool _4314;\n                if (!_4307)\n                {\n                    _4314 = _511_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4314 = _4307;\n                }\n                float _4315;\n                if (_4314)\n                {\n                    _4315 = _511_fa_fog_b.y * _4243;\n                }\n                else\n                {\n                    _4315 = (_511_fa_fog_b.y * (1.0f - exp(-min(_511_fa_fog_b.w * _4243, 80.0f)))) / _511_fa_fog_b.w;\n                }\n                float _4342;\n                if (abs(_4233) < 0.001000000047497451305389404296875f)\n                {\n                    _4342 = _4254;\n                }\n                else\n                {\n                    _4342 = (_4315 - _4282) / _4233;\n                }\n                tau += (_4183 * max(_4342, 0.0f));\n            }\n            result = lerp(result, _511_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4424);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_511",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1251",
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
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 8
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 9
            }
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 10
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n    float4 _213_fa_ct_a : packoffset(c24);\n    float4 _213_fa_ct_b : packoffset(c25);\n    float4 _213_fa_ct_vpx : packoffset(c26);\n    float4 _213_fa_ct_vpy : packoffset(c27);\n    float4 _213_fa_ct_vpw : packoffset(c28);\n    float4 _213_fa_ct_fwd : packoffset(c29);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213_fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213_fa_layers_a.x;\n    float _753 = _213_fa_layers_a.y;\n    float _756 = _213_fa_layers_a.z;\n    float _755 = _213_fa_layers_b.w;\n    float _758 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    Surface _777 = { _241.xyz, _241.w, _747, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _752, _753, _213_fa_layers_b.xyz, _755, _756, _213_fa_layers_a.w, _758, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _777;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _671 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _671;\n    SurfaceInput _679 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _679;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _413 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _413;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0f);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n    float4 _213_fa_ct_a : packoffset(c24);\n    float4 _213_fa_ct_b : packoffset(c25);\n    float4 _213_fa_ct_vpx : packoffset(c26);\n    float4 _213_fa_ct_vpy : packoffset(c27);\n    float4 _213_fa_ct_vpw : packoffset(c28);\n    float4 _213_fa_ct_fwd : packoffset(c29);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213_fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213_fa_layers_a.x;\n    float _753 = _213_fa_layers_a.y;\n    float _756 = _213_fa_layers_a.z;\n    float _755 = _213_fa_layers_b.w;\n    float _758 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    Surface _777 = { _241.xyz, _241.w, _747, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _752, _753, _213_fa_layers_b.xyz, _755, _756, _213_fa_layers_a.w, _758, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _777;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _671 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _671;\n    SurfaceInput _679 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _679;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
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
            "size": 480,
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
