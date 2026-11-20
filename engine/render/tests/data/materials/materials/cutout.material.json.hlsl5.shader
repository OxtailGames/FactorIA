{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "550ff47e6dc7e71192661fb1e526df6e96f66de981c805742262dd122b44bf86",
  "slang": "hlsl5",
  "params": [
    "alphaCutoff"
  ],
  "textures": [
    "mask"
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _269 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _269;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _276 = _160.world_pos;\n    fa_world_pos = _276;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_276, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3657[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _560_fa_camera_pos : packoffset(c0);\n    float4 _560_fa_ambient : packoffset(c1);\n    float4 _560_fa_base_color : packoffset(c2);\n    float4 _560_fa_emissive : packoffset(c3);\n    float4 _560_fa_model_emissive : packoffset(c4);\n    float4 _560_fa_pbr : packoffset(c5);\n    float4 _560_fa_maps : packoffset(c6);\n    float4 _560_fa_fog : packoffset(c7);\n    float4 _560_fa_fog_b : packoffset(c8);\n    float4 _560_fa_fog_c : packoffset(c9);\n    float4 _560_fa_counts : packoffset(c10);\n    float4 _560_fa_env_sky : packoffset(c11);\n    float4 _560_fa_env_horizon : packoffset(c12);\n    float4 _560_fa_time : packoffset(c13);\n    float4 _560_fa_cl_vpx : packoffset(c14);\n    float4 _560_fa_cl_vpy : packoffset(c15);\n    float4 _560_fa_cl_vpw : packoffset(c16);\n    float4 _560_fa_cl_fwd : packoffset(c17);\n    float4 _560_fa_cl_grid : packoffset(c18);\n    float4 _560_fa_cl_info : packoffset(c19);\n    float4 _560_fa_layers_a : packoffset(c20);\n    float4 _560_fa_layers_b : packoffset(c21);\n    float4 _560_fa_layers_c : packoffset(c22);\n    float4 _560_fa_layers_d : packoffset(c23);\n    float4 _560_fa_ct_a : packoffset(c24);\n    float4 _560_fa_ct_b : packoffset(c25);\n    float4 _560_fa_ct_vpx : packoffset(c26);\n    float4 _560_fa_ct_vpy : packoffset(c27);\n    float4 _560_fa_ct_vpw : packoffset(c28);\n    float4 _560_fa_ct_fwd : packoffset(c29);\n    float4 _560_fa_probe_sh[9] : packoffset(c30);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2227_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2227_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2227_fa_shadow_info[4] : packoffset(c20);\n    float4 _2227_fa_shadow_split : packoffset(c24);\n    float4 _2227_fa_shadow_cfg : packoffset(c25);\n    float4 _2227_fa_shadow_bias : packoffset(c26);\n    float4 _2227_fa_shadow_eye : packoffset(c27);\n    float4 _2227_fa_shadow_fwd : packoffset(c28);\n    float4 _2227_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _6303_alphaCutoff : packoffset(c0);\n    float _6303_fa_pad0 : packoffset(c0.y);\n    float _6303_fa_pad1 : packoffset(c0.z);\n    float _6303_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t7);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1498 = _560_fa_cl_info.x < 0.0f;\n    bool _1505;\n    if (!_1498)\n    {\n        _1505 = _560_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1505 = _1498;\n    }\n    bool _1513;\n    if (!_1505)\n    {\n        _1513 = _560_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1513 = _1505;\n    }\n    bool _1520;\n    if (!_1513)\n    {\n        _1520 = _560_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1520 = _1513;\n    }\n    bool _1527;\n    if (!_1520)\n    {\n        _1527 = _560_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1527 = _1520;\n    }\n    if (_1527)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1537 = float4(world_pos, 1.0f);\n    float _1543 = dot(_560_fa_cl_vpw, _1537);\n    if (!(_1543 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1565 = float2(dot(_560_fa_cl_vpx, _1537), dot(_560_fa_cl_vpy, _1537)) / _1543.xx;\n    int _1569 = int(_560_fa_cl_grid.x);\n    int _1573 = int(_560_fa_cl_grid.y);\n    int param = (int(_560_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_560_fa_cl_fwd.xyz, world_pos) + _560_fa_cl_fwd.w, _560_fa_cl_grid.w) / _560_fa_cl_grid.w) * _560_fa_cl_grid.z)), 0, int(_560_fa_cl_info.y) - 1) * _1573) + clamp(int(floor(((_1565.y * 0.5f) + 0.5f) * _560_fa_cl_grid.y)), 0, _1573 - 1)) * _1569)) + clamp(int(floor(((_1565.x * 0.5f) + 0.5f) * _560_fa_cl_grid.x)), 0, _1569 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1649 = fa_cluster_texel(param);\n    return int2(int(_1649.x), int(_1649.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_560_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4755 = fa_cluster_lookup(param);\n    fa_cl_slot = _4755.x;\n    fa_cl_local = _4755.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5900 = fa_linear_to_srgb(param);\n        c = _5900;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5908 = fa_srgb_to_linear(param_1);\n            c = _5908;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _442;\n    if (i.front_facing)\n    {\n        _442 = i.world_normal;\n    }\n    else\n    {\n        _442 = -i.world_normal;\n    }\n    float3 _466 = normalize(i.world_tangent.xyz - (_442 * dot(_442, i.world_tangent.xyz)));\n    float3 _493 = normalize(((_466 * m.x) + ((cross(_442, _466) * i.world_tangent.w) * m.y)) + (_442 * m.z));\n    float3 _496;\n    if (i.front_facing)\n    {\n        _496 = _493;\n    }\n    else\n    {\n        _496 = -_493;\n    }\n    return _496;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _560_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5939 = fa_tex_fix(param_2, param_3);\n    float4 _7410 = base_t;\n    _7410.x = _5939.x;\n    _7410.y = _5939.y;\n    _7410.z = _5939.z;\n    base_t = _7410;\n    float4 _5953 = (_7410 * _560_fa_base_color) * i.vertex_color;\n    float3 _7235 = i.world_normal;\n    if (_560_fa_maps.z > 0.5f)\n    {\n        float param_4 = _560_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5985 = fa_tex_fix(param_6, param_7);\n        float3 _5988 = (_5985 * 2.0f) - 1.0f.xxx;\n        float2 _5993 = _5988.xy * _560_fa_maps.x;\n        float3 _7418 = _5988;\n        _7418.x = _5993.x;\n        _7418.y = _5993.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _7418;\n        _7235 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _560_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _6021 = fa_tex_fix(param_12, param_13);\n    float4 _7421 = mrt;\n    _7421.x = _6021.x;\n    _7421.y = _6021.y;\n    _7421.z = _6021.z;\n    mrt = _7421;\n    float4 _6049 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _560_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _6049.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _6060 = fa_tex_fix(param_16, param_17);\n    float param_18 = _560_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _6090 = fa_tex_fix(param_20, param_21);\n    float _7240 = _560_fa_layers_a.x;\n    float _7241 = _560_fa_layers_a.y;\n    float _7244 = _560_fa_layers_a.z;\n    float _7243 = _560_fa_layers_b.w;\n    float _7246 = _560_fa_layers_c.x;\n    if (_560_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_560_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _7240 *= _6060.y;\n            _7241 *= _6060.z;\n            _7243 *= _6049.w;\n        }\n        if (_560_fa_layers_c.z > 1.5f)\n        {\n            _7244 *= mrt.x;\n            _7246 *= mrt.w;\n        }\n    }\n    Surface _7265 = { _5953.xyz, _5953.w, _7235, clamp(_560_fa_pbr.x * _6021.z, 0.0f, 1.0f), clamp(_560_fa_pbr.y * _6021.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_560_fa_maps.y * (_6060.x - 1.0f)), _560_fa_emissive.xyz + (_560_fa_model_emissive.xyz * _6090), _7240, _7241, _560_fa_layers_b.xyz, _7243, _7244, _560_fa_layers_a.w, _7246, _560_fa_layers_c.y, _560_fa_layers_d.xyz };\n    return _7265;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1729 = rect.zw - rect.xy;\n    float2 _1733 = _1729 * atlas;\n    float2 _1737 = ddx * _1733;\n    float2 _1741 = ddy * _1733;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1729), clamp(0.5f * log2(max(max(dot(_1737, _1737), dot(_1741, _1741)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1774 = _560_fa_counts.y < 0.5f;\n    bool _1781;\n    if (!_1774)\n    {\n        _1781 = _560_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1781 = _1774;\n    }\n    if (_1781)\n    {\n        return;\n    }\n    float3 _1787 = ddx(world_pos);\n    float3 _1790 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1794 = fa_cluster_texel(param);\n    int _1798 = int(_1794.w);\n    if (_1798 < 1)\n    {\n        return;\n    }\n    int _1808 = int(_560_fa_counts.y + 0.5f);\n    int param_1 = _1808;\n    float4 _1812 = fa_light_texel(param_1);\n    float2 _1815 = _1812.yz;\n    int _1819 = int(_1812.w);\n    int param_2 = _1808 + 1;\n    float4 _1824 = fa_light_texel(param_2);\n    float _1825 = _1824.x;\n    int _1831 = int(_560_fa_counts.w + 0.5f) - 1;\n    int _1835 = int(_1794.z);\n    float3 _2100;\n    for (int k = 0; k < _1798; k++)\n    {\n        int _1848 = _1835 + k;\n        int param_3 = _1819 + (_1848 >> 2);\n        int _1865 = (_1808 + 2) + (int(fa_light_texel(param_3)[_1848 & 3]) * 7);\n        int param_4 = _1865 + 6;\n        float4 _1870 = fa_light_texel(param_4);\n        if (((int(_1870.w + 0.5f) >> _1831) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1865;\n        float4 _1885 = fa_light_texel(param_5);\n        int param_6 = _1865 + 1;\n        float4 _1890 = fa_light_texel(param_6);\n        int param_7 = _1865 + 2;\n        float4 _1895 = fa_light_texel(param_7);\n        float3 _1898 = _1885.xyz;\n        float _1903 = dot(_1898, world_pos) + _1885.w;\n        float3 _1905 = _1890.xyz;\n        float _1910 = dot(_1905, world_pos) + _1890.w;\n        float3 _1912 = _1895.xyz;\n        float _1917 = dot(_1912, world_pos) + _1895.w;\n        bool _1922 = abs(_1903) > 0.5f;\n        bool _1930;\n        if (!_1922)\n        {\n            _1930 = abs(_1910) > 0.5f;\n        }\n        else\n        {\n            _1930 = _1922;\n        }\n        bool _1938;\n        if (!_1930)\n        {\n            _1938 = abs(_1917) > 0.5f;\n        }\n        else\n        {\n            _1938 = _1930;\n        }\n        if (_1938)\n        {\n            continue;\n        }\n        float _1953 = clamp(dot(geo_normal, normalize(_1912)) * _1870.z, 0.0f, 1.0f);\n        if (_1953 <= 0.0f)\n        {\n            continue;\n        }\n        float _1973 = (clamp((0.5f - abs(_1917)) * 10.0f, 0.0f, 1.0f) * _1953) * _1870.x;\n        float2 _1981 = float2(_1903 + 0.5f, 0.5f - _1910);\n        float2 _1991 = float2(dot(_1898, _1787), dot(_1905, _1787));\n        float2 _2001 = float2(dot(_1898, _1790), dot(_1905, _1790));\n        int param_8 = _1865 + 5;\n        float4 _2006 = fa_light_texel(param_8);\n        int param_9 = _1865 + 3;\n        float4 _2011 = fa_light_texel(param_9);\n        int param_10 = _1865 + 4;\n        float4 _2016 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2006.xyz;\n        bool _2026 = _2011.z > _2011.x;\n        if (_2026)\n        {\n            float4 param_11 = _2011;\n            float2 param_12 = _1981;\n            float2 param_13 = _1815;\n            float2 param_14 = _1991;\n            float2 param_15 = _2001;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1825 > 0.5f) && (_1825 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2052 = fa_dc_to_linear(param_16);\n                float4 _7315 = tx;\n                _7315.x = _2052.x;\n                _7315.y = _2052.y;\n                _7315.z = _2052.z;\n                tx = _7315;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1973 * tex_a) * _2006.w, 0.0f, 1.0f).xxx);\n        if (_2016.z > _2016.x)\n        {\n            float4 param_17 = _2016;\n            float2 param_18 = _1981;\n            float2 param_19 = _1815;\n            float2 param_20 = _1991;\n            float2 param_21 = _2001;\n            float4 _2096 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1825 > 1.5f)\n            {\n                float3 param_22 = _2096.xyz;\n                float3 _2106 = fa_dc_to_srgb(param_22);\n                _2100 = _2106;\n            }\n            else\n            {\n                _2100 = _2096.xyz;\n            }\n            float3 _2115 = (_2100 * 2.0f) - 1.0f.xxx;\n            float2 _2120 = _2115.xy * _1870.y;\n            float3 _2142 = (normalize(_1898) * _2120.x) + (normalize(_1905) * _2120.y);\n            float3 _2145 = normalize(normal);\n            normal = normalize(lerp(_2145, normalize((_2145 * max(_2115.z, 0.0500000007450580596923828125f)) + (_2142 - (_2145 * dot(_2145, _2142)))), clamp(_1973 * (_2026 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3583 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3590 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3593 = int(_3583);\n    int _3596 = int(_3590);\n    float _3606 = _3590 - float(_3596);\n    int _3661 = (_3593 * 9) + _3596;\n    int _3681 = ((_3593 + 1) * 9) + _3596;\n    return lerp(lerp(_3657[_3661], _3657[_3661 + 1], _3606), lerp(_3657[_3681], _3657[_3681 + 1], _3606), _3583 - float(_3593));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _7158 = false;\n    float _7159 = 1.0f;\n    float _7160 = 1.0f;\n    float _7161 = 1.0f;\n    float _7162 = 0.0f;\n    float _7163 = 0.0f;\n    float _7164 = 0.0f;\n    float _7165 = 0.0f;\n    float _7167 = 1.0f;\n    bool _7168 = false;\n    float3 _7169 = 0.0f.xxx;\n    float _7170 = 1.0f;\n    float _7171 = 1.0f;\n    float _7172 = 1.0f;\n    float _7173 = 0.0f;\n    float _7174 = 0.0f;\n    float3 _7175 = float3(1.0f, 0.0f, 0.0f);\n    float3 _7176 = float3(0.0f, 0.0f, 1.0f);\n    float _7177 = 1.0f;\n    float _7178 = 1.0f;\n    float _3732 = clamp(s.specular, 0.0f, 1.0f);\n    float _3736 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3741 = (_3732 != 1.0f) || (_3736 != 1.5f);\n    bool _3750;\n    if (!_3741)\n    {\n        _3750 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3750 = _3741;\n    }\n    if (_3750)\n    {\n        float _3758 = (_3736 - 1.0f) / (_3736 + 1.0f);\n        f0 = lerp(min((_3758 * _3758).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3732, s.albedo, metallic.xxx);\n        _7159 = lerp(_3732, 1.0f, metallic);\n        _7158 = true;\n    }\n    float _3785 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3785 > 0.0f)\n    {\n        float _3793 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _7162 = _3785;\n        _7163 = _3793;\n        float _3800 = _3793 * _3793;\n        _7164 = _3800;\n        _7165 = _3800 * _3800;\n        float _3812 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _7167 = _3812;\n        _7160 = 1.0f - (_3785 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3812, 0.0f, 1.0f), 5.0f))));\n        _7158 = true;\n    }\n    float3 _3831 = max(s.sheen_color, 0.0f.xxx);\n    float _3840 = max(_3831.x, max(_3831.y, _3831.z));\n    if (_3840 > 0.0f)\n    {\n        float _3848 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _7168 = true;\n        _7169 = _3831;\n        _7170 = _3848;\n        _7171 = _3848 * _3848;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3848;\n        float _3865 = fa_sheen_albedo(param, param_1);\n        _7173 = _3865;\n        _7172 = 1.0f - min(_3840 * _3865, 1.0f);\n        _7158 = true;\n    }\n    _7161 = _7160 * _7172;\n    float _3884 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3884 != 0.0f)\n    {\n        float3 _3899 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3899;\n        if (dot(_3899, _3899) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3911 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3911.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3911.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3911.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3915 = t;\n        float3 _3916 = normalize(_3915);\n        t = _3916;\n        float3 _3941 = normalize((_3916 * cos(s.anisotropy_rotation)) + ((cross(n, _3916) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _7175 = _3941;\n        _7176 = cross(n, _3941);\n        float _3951 = roughness * roughness;\n        float _3957 = lerp(_3951, 1.0f, _3884 * _3884);\n        bool _3959 = _3884 > 0.0f;\n        _7177 = _3959 ? _3957 : _3951;\n        _7178 = _3959 ? _3951 : _3957;\n        _7174 = _3884;\n        _7158 = true;\n    }\n    FaLayers _7200 = { _7158, _7159, _7160, _7161, _7162, _7163, _7164, _7165, i.world_normal, _7167, _7168, _7169, _7170, _7171, _7172, _7173, _7174, _7175, _7176, _7177, _7178 };\n    return _7200;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_560_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3340 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3340;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_560_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _560_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_560_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _560_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_560_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_560_fa_cl_info.x) + int(_560_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_560_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4725;\n    if (fa_lm.z > 0.5f)\n    {\n        _4725 = 0.0f;\n    }\n    else\n    {\n        _4725 = 1.0f - clamp(_560_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4736 = _4725 < 1.0f;\n    bool _4742;\n    if (_4736)\n    {\n        int param = li;\n        _4742 = fa_light_baked(param);\n    }\n    else\n    {\n        _4742 = _4736;\n    }\n    return _4742 ? _4725 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _628_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _628_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _747 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _760 = (c - (ru * hx)) - p;\n        float3 _766 = ru * (2.0f * hx);\n        float _772 = max(dot(_766, _766), 9.9999999392252902907785028219223e-09f);\n        float _776 = dot(_760, _766);\n        float t = clamp((-_776) / _772, 0.0f, 1.0f);\n        if (_747)\n        {\n            float _791 = dot(r, _766);\n            float _797 = _772 - (_791 * _791);\n            if (abs(_797) > (9.9999997473787516355514526367188e-06f * _772))\n            {\n                t = clamp(((dot(r, _760) * _791) - _776) / _797, 0.0f, 1.0f);\n            }\n        }\n        return (p + _760) + (_766 * t);\n    }\n    float3 q = p;\n    float _829 = dot(r, axis);\n    bool _837;\n    if (_747)\n    {\n        _837 = abs(_829) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _837 = _747;\n    }\n    if (_837)\n    {\n        float _847 = dot(c - p, axis) / _829;\n        if (_847 > 0.0f)\n        {\n            q = p + (r * _847);\n        }\n    }\n    float3 _860 = q - c;\n    float2 xy = float2(dot(_860, ru), dot(_860, uu));\n    if (shape > 0.5f)\n    {\n        float _875 = length(xy);\n        if (_875 > hx)\n        {\n            xy *= (hx / _875);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _508 = abs(d);\n    float _510 = _508.x;\n    float _512 = _508.y;\n    bool _513 = _510 >= _512;\n    bool _521;\n    if (_513)\n    {\n        _521 = _510 >= _508.z;\n    }\n    else\n    {\n        _521 = _513;\n    }\n    int _522;\n    if (_521)\n    {\n        _522 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _537;\n        if (_512 >= _508.z)\n        {\n            _537 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _537 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _522 = _537;\n    }\n    return _522;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _667 = dot(d, right);\n    float _671 = dot(d, up);\n    float _682;\n    if (((_667 * _667) + (_671 * _671)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _682 = atan2(_671, _667) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _682 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_682 - floor(_682)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _913 = fa_light_base(param);\n    bool _917 = _560_fa_ambient.w > 4.5f;\n    int param_1 = _913;\n    float4 _921 = fa_light_texel(param_1);\n    int param_2 = _913 + 1;\n    float4 _926 = fa_light_texel(param_2);\n    float _929 = _926.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _941 = _917 && (_929 > 2.5f);\n    fa_light_is_area = _941;\n    bool _943 = _929 < 0.5f;\n    float3 l;\n    if (_943)\n    {\n        l = normalize(_921.xyz);\n        if (_917)\n        {\n            int param_3 = _913 + 6;\n            float4 _957 = fa_light_texel(param_3);\n            if (_957.z > 0.5f)\n            {\n                int param_4 = _913 + 4;\n                float4 _967 = fa_light_texel(param_4);\n                int param_5 = _913 + 5;\n                float4 _972 = fa_light_texel(param_5);\n                float2 param_6 = _957.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _967.xyz) * _967.w, (-dot(world_pos, _972.xyz)) * _972.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1002 = _921.xyz;\n        float3 _1004 = _1002 - world_pos;\n        float3 to_light = _1004;\n        float _1007 = length(_1004);\n        float reach = _1007;\n        bool front = true;\n        if (_941)\n        {\n            int param_8 = _913 + 7;\n            reach = max(_1007 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _913 + 4;\n            float4 _1031 = fa_light_texel(param_9);\n            int param_10 = _913 + 5;\n            float4 _1036 = fa_light_texel(param_10);\n            int param_11 = _913 + 6;\n            float4 _1041 = fa_light_texel(param_11);\n            float _1042 = _1041.w;\n            int param_12 = _913 + 2;\n            float3 _1049 = normalize(fa_light_texel(param_12).xyz);\n            bool _1051 = _1042 > 1.5f;\n            bool _1059;\n            if (!_1051)\n            {\n                _1059 = dot(_1049, to_light) < 0.0f;\n            }\n            else\n            {\n                _1059 = _1051;\n            }\n            front = _1059;\n            float3 r = 0.0f.xxx;\n            float3 _1068 = _560_fa_camera_pos.xyz - world_pos;\n            bool _1072 = dot(n, n) > 0.5f;\n            bool _1080;\n            if (_1072)\n            {\n                _1080 = dot(_1068, _1068) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1080 = _1072;\n            }\n            if (_1080)\n            {\n                r = reflect(-normalize(_1068), normalize(n));\n            }\n            float3 param_13 = _1002;\n            float3 param_14 = _1049;\n            float3 param_15 = _1031.xyz;\n            float3 param_16 = _1036.xyz;\n            float param_17 = _1031.w;\n            float param_18 = _1036.w;\n            float param_19 = _1042;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1116 = length(to_light);\n        dist = _1116;\n        l = to_light / max(_1116, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1130 = reach / max(_921.w, 0.001000000047497451305389404296875f);\n        float _1136 = clamp(1.0f - (_1130 * _1130), 0.0f, 1.0f);\n        float _1138;\n        if (front)\n        {\n            _1138 = _1136 * _1136;\n        }\n        else\n        {\n            _1138 = 0.0f;\n        }\n        atten = _1138;\n        bool _1149 = _929 < 2.5f;\n        if ((_929 > 1.5f) && _1149)\n        {\n            int param_22 = _913 + 2;\n            float4 _1157 = fa_light_texel(param_22);\n            float _1167 = _1157.w;\n            int param_23 = _913 + 3;\n            float4 _1172 = fa_light_texel(param_23);\n            float _1173 = _1172.x;\n            float cos_inner = _1173;\n            if (_1173 > 1.5f)\n            {\n                cos_inner = lerp(_1167, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1167, cos_inner, dot(-l, normalize(_1157.xyz)));\n        }\n        if (_917 && (_929 < 1.5f))\n        {\n            int param_24 = _913 + 6;\n            float4 _1197 = fa_light_texel(param_24);\n            if (_1197.z > 0.5f)\n            {\n                float3 _1205 = -to_light;\n                int param_25 = _913 + 4;\n                int param_26 = _913 + 5;\n                float3 _1219 = fa_light_texel(param_25).xyz;\n                float3 _1223 = fa_light_texel(param_26).xyz;\n                float3 _1232 = float3(dot(_1205, _1219), dot(_1205, _1223), dot(_1205, cross(_1219, _1223)));\n                float3 param_27 = _1232;\n                int _1236 = fa_cube_face(param_27);\n                int param_28 = _1236;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1263 = float2(dot(_1232, cross(param_29, param_30)), dot(_1232, param_30)) / max(dot(_1232, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1267 = _1236 / 3;\n                float2 param_31 = _1197.xy + (float2(float(_1236 - (_1267 * 3)), float(_1267)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1263.x), 0.5f - (0.5f * _1263.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _913 + 7;\n            float4 _1297 = fa_light_texel(param_33);\n            if (_1297.z > 0.5f)\n            {\n                int param_34 = _913 + 2;\n                int param_35 = _913 + 4;\n                int param_36 = _913 + 5;\n                float2 param_37 = _1297.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_917 && _1149)\n            {\n                int param_42 = _913 + 6;\n                float4 _1344 = fa_light_texel(param_42);\n                int param_43 = _913 + 7;\n                float4 _1349 = fa_light_texel(param_43);\n                bool _1352 = _1344.z > 0.5f;\n                bool _1359;\n                if (!_1352)\n                {\n                    _1359 = _1349.z > 0.5f;\n                }\n                else\n                {\n                    _1359 = _1352;\n                }\n                if (_1359)\n                {\n                    int param_44 = _913 + 2;\n                    float4 _1366 = fa_light_texel(param_44);\n                    float3 _1370 = normalize(_1366.xyz);\n                    int param_45 = _913 + 4;\n                    float4 _1375 = fa_light_texel(param_45);\n                    int param_46 = _913 + 5;\n                    float4 _1380 = fa_light_texel(param_46);\n                    if (_1352)\n                    {\n                        float3 _1388 = -to_light;\n                        float _1395 = _1366.w;\n                        float _1411 = 0.5f / max(dot(_1388, _1370) * (sqrt(max(1.0f - (_1395 * _1395), 0.0f)) / max(_1395, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1344.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1388, _1375.xyz) * _1411), 0.5f - (dot(_1388, _1380.xyz) * _1411));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1349.z > 0.5f)\n                    {\n                        float2 param_49 = _1349.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1370;\n                        float3 param_52 = _1375.xyz;\n                        float3 param_53 = _1380.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _7146 = _926.xyz * atten;\n    if (_917)\n    {\n        _7146 *= fa_light_tint;\n    }\n    int _1480;\n    if (_943)\n    {\n        _1480 = 0;\n    }\n    else\n    {\n        _1480 = ((_929 > 1.5f) && (_929 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _7157 = { l, _7146, atten, 1.0f, dist, _1480 };\n    return _7157;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2217;\n    if (i == 0)\n    {\n        _2217 = _2227_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2233;\n        if (i == 1)\n        {\n            _2233 = _2227_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2241;\n            if (i == 2)\n            {\n                _2241 = _2227_fa_shadow_split.z;\n            }\n            else\n            {\n                _2241 = _2227_fa_shadow_split.w;\n            }\n            _2233 = _2241;\n        }\n        _2217 = _2233;\n    }\n    return _2217;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2274 = fa_shadow_depth(param, param_1);\n    float _2278;\n    if (conv.x < 0.5f)\n    {\n        _2278 = _2274;\n    }\n    else\n    {\n        _2278 = (conv.y * conv.z) / (conv.z - (_2274 * (conv.z - conv.y)));\n    }\n    return _2278;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2205 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2205), sin(_2205)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2324 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2333;\n        if (k < 0.0f)\n        {\n            _2333 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2333 = k;\n        }\n        float _2353 = clamp((_2333 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2324;\n            float2 _2372 = fa_shadow_vogel(param_3, param_4, param_5) * _2353;\n            float2 param_6 = uv + (_2372 * _2227_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2384 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2384 < (zr - (length(_2372) * plane)))\n            {\n                sum += _2384;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2410 = sum / cnt;\n        float _2420;\n        if (k < 0.0f)\n        {\n            _2420 = (-k) / max(_2410, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2420 = k;\n        }\n        radius = clamp(((max(zr - _2410, 0.0f) * unit) * _2420) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2442 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2442; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2442;\n        float param_11 = _2324;\n        float2 _2461 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2461 * _2227_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2461) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2442);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2503 = max(_2227_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2508 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2514 = sqrt(1.0f - (_2508 * _2508));\n    float _2521 = min(_2514 / max(_2508, 0.20000000298023223876953125f), 4.0f);\n    float _2526;\n    if (_2227_fa_shadow_bias.y > 0.0f)\n    {\n        _2526 = _2227_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2526 = 1.5f * _2227_fa_shadow_info[ci].x;\n    }\n    float4 _2551 = mul(float4(world + (n * (_2526 * _2514)), 1.0f), _2227_fa_shadow_mat[ci]);\n    float _2558 = _2551.x;\n    bool _2561 = _2558 < _2227_fa_shadow_rect[ci].x;\n    bool _2570;\n    if (!_2561)\n    {\n        _2570 = _2558 > _2227_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2570 = _2561;\n    }\n    bool _2579;\n    if (!_2570)\n    {\n        _2579 = _2551.y < _2227_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2579 = _2570;\n    }\n    bool _2588;\n    if (!_2579)\n    {\n        _2588 = _2551.y > _2227_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2588 = _2579;\n    }\n    bool _2595;\n    if (!_2588)\n    {\n        _2595 = _2551.z > 1.0f;\n    }\n    else\n    {\n        _2595 = _2588;\n    }\n    if (_2595)\n    {\n        return -1.0f;\n    }\n    float _2603;\n    if (_2227_fa_shadow_bias.x > 0.0f)\n    {\n        _2603 = _2227_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2603 = 1.5f * _2227_fa_shadow_info[ci].x;\n    }\n    float2 param = _2551.xy;\n    float4 param_1 = _2227_fa_shadow_rect[ci];\n    float param_2 = _2551.z - ((_2603 * (1.0f + (0.5f * _2521))) / _2503);\n    float param_3 = _2227_fa_shadow_info[ci].x;\n    float param_4 = _2503;\n    float param_5 = _2503 * 0.25f;\n    float param_6 = ((_2227_fa_shadow_info[ci].x * min(_2521, 3.0f)) * 0.5f) / _2503;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2227_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2227_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_560_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2981 = int(_2227_fa_shadow_cfg.x + 0.5f);\n    if (_2981 < 1)\n    {\n        return 1.0f;\n    }\n    float _2996 = dot(world - _2227_fa_shadow_eye.xyz, _2227_fa_shadow_fwd.xyz);\n    int param = _2981 - 1;\n    if (_2996 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3008 = _2981 > 1;\n    bool _3015;\n    if (_3008)\n    {\n        _3015 = _2996 > _2227_fa_shadow_split.x;\n    }\n    else\n    {\n        _3015 = _3008;\n    }\n    if (_3015)\n    {\n        ci = 1;\n    }\n    bool _3019 = _2981 > 2;\n    bool _3026;\n    if (_3019)\n    {\n        _3026 = _2996 > _2227_fa_shadow_split.y;\n    }\n    else\n    {\n        _3026 = _3019;\n    }\n    if (_3026)\n    {\n        ci = 2;\n    }\n    bool _3030 = _2981 > 3;\n    bool _3037;\n    if (_3030)\n    {\n        _3037 = _2996 > _2227_fa_shadow_split.z;\n    }\n    else\n    {\n        _3037 = _3030;\n    }\n    if (_3037)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2981)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3063 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3063;\n        if (_3063 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2227_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3088;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3088 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3088 = _2227_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3107 = _2227_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3088, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3118 = clamp((_2996 - (fa_shadow_split_at(param_7) - _3107)) / _3107, 0.0f, 1.0f);\n        if (_3118 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2981)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3139 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3139;\n                if (_3139 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3118);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2661 = _560_fa_pbr.z < 0.5f;\n    bool _2668;\n    if (!_2661)\n    {\n        _2668 = _2227_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2668 = _2661;\n    }\n    if (_2668)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2227_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2681 = fa_light_texel(param);\n    float _2682 = _2681.x;\n    if (_2682 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2691 = int(_2682 + 0.5f);\n    int param_1 = _2691;\n    float4 _2695 = fa_light_texel(param_1);\n    int param_2 = _2691 + 1;\n    float4 _2700 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2703 = _2695.y;\n    if (_2703 > 0.0f)\n    {\n        float _2720 = 1.0f - smoothstep(0.75f * _2703, _2703, length(world - _2227_fa_shadow_eye.xyz));\n        fade = _2720;\n        if (_2720 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2695.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2744 = (_2691 + 2) + (face * 6);\n    int param_4 = _2744;\n    int param_5 = _2744 + 1;\n    int param_6 = _2744 + 3;\n    float4 _2758 = fa_light_texel(param_6);\n    int param_7 = _2744 + 4;\n    float4 _2763 = fa_light_texel(param_7);\n    int param_8 = _2744 + 5;\n    float4 _2768 = fa_light_texel(param_8);\n    float _2780 = _2768.x * max(dot(_2758, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2785 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2808 = clamp(dot(n, _2758.xyz), -1.0f, 1.0f);\n    float _2827 = min(sqrt(1.0f - (_2808 * _2808)) / max(abs(dot(n, world - lpos)) / max(dot(_2758, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2830 = _2700.y;\n    float _2832;\n    if (_2830 > 0.0f)\n    {\n        _2832 = _2830;\n    }\n    else\n    {\n        _2832 = 1.5f * _2780;\n    }\n    float4 _2852 = float4(world + (n * (_2832 * sqrt(1.0f - (_2785 * _2785)))), 1.0f);\n    float _2856 = dot(_2758, _2852);\n    float _2859 = _2768.y;\n    if (_2856 < _2859)\n    {\n        return 1.0f;\n    }\n    float2 _2874 = float2(dot(fa_light_texel(param_4), _2852), dot(fa_light_texel(param_5), _2852)) / _2856.xx;\n    float _2876 = _2874.x;\n    bool _2879 = _2876 < _2763.x;\n    bool _2888;\n    if (!_2879)\n    {\n        _2888 = _2876 > _2763.z;\n    }\n    else\n    {\n        _2888 = _2879;\n    }\n    bool _2897;\n    if (!_2888)\n    {\n        _2897 = _2874.y < _2763.y;\n    }\n    else\n    {\n        _2897 = _2888;\n    }\n    bool _2906;\n    if (!_2897)\n    {\n        _2906 = _2874.y > _2763.w;\n    }\n    else\n    {\n        _2906 = _2897;\n    }\n    if (_2906)\n    {\n        return 1.0f;\n    }\n    float _2912 = _2700.x;\n    float _2914;\n    if (_2912 > 0.0f)\n    {\n        _2914 = _2912;\n    }\n    else\n    {\n        _2914 = 1.5f * _2780;\n    }\n    float2 param_9 = _2874;\n    float4 param_10 = _2763;\n    float param_11 = _2856 - (_2914 * (1.0f + (0.5f * _2827)));\n    float param_12 = _2780;\n    float param_13 = 1.0f;\n    float param_14 = _2768.z * 0.25f;\n    float param_15 = (_2780 * min(_2827, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2859, _2768.z);\n    int param_17 = int(_2695.z + 0.5f);\n    float param_18 = _2695.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4469 = _560_fa_ct_a.x < 0.5f;\n    bool _4476;\n    if (!_4469)\n    {\n        _4476 = _2227_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4476 = _4469;\n    }\n    if (_4476)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2227_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4489 = fa_light_texel(param);\n    float _4490 = _4489.y;\n    float len = _4490;\n    if (_4490 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4502 = length(world - _560_fa_camera_pos.xyz);\n    float _4512 = 1.0f - smoothstep(0.5f * _560_fa_ct_b.x, _560_fa_ct_b.x, _4502);\n    if (_4512 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4518 = len;\n    float _4521 = min(_4518, 0.89999997615814208984375f * dist);\n    len = _4521;\n    float _4526 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4502);\n    float _4531 = _4526 + (0.5f * _4521);\n    float3 _4537 = world + (gn * _4526);\n    float _4539 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4603;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4554 = (float(k) + _4539) * 0.083333335816860198974609375f;\n        float3 _4562 = _4537 + (l * (_4554 * len));\n        float4 _4568 = float4(_4562, 1.0f);\n        float _4574 = dot(_560_fa_ct_vpw, _4568);\n        if (_4574 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4594 = float2(dot(_560_fa_ct_vpx, _4568), dot(_560_fa_ct_vpy, _4568)) / _4574.xx;\n        float _4598 = _4594.x * 0.5f;\n        float _4599 = _4598 + 0.5f;\n        if (_560_fa_ct_a.y > 0.5f)\n        {\n            _4603 = (_4594.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4603 = 0.5f - (_4594.y * 0.5f);\n        }\n        bool _4619 = _4599 < 0.0f;\n        bool _4626;\n        if (!_4619)\n        {\n            _4626 = _4599 >= 1.0f;\n        }\n        else\n        {\n            _4626 = _4619;\n        }\n        bool _4633;\n        if (!_4626)\n        {\n            _4633 = _4603 < 0.0f;\n        }\n        else\n        {\n            _4633 = _4626;\n        }\n        bool _4640;\n        if (!_4633)\n        {\n            _4640 = _4603 >= 1.0f;\n        }\n        else\n        {\n            _4640 = _4633;\n        }\n        if (_4640)\n        {\n            break;\n        }\n        float4 _4659 = fa_screen_tex.Load(int3(int2(float2(_4599, _4603) * _560_fa_ct_a.zw), 0));\n        if (_4659.w < 0.5f)\n        {\n            continue;\n        }\n        float _4678 = (dot(_560_fa_ct_fwd.xyz, _4562) + _560_fa_ct_fwd.w) - _4659.x;\n        if ((_4678 > _4526) && (_4678 < _4531))\n        {\n            occ = max(occ, (1.0f - (_4554 * _4554)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4599, 0.5f - _4598), min(_4603, 1.0f - _4603))));\n        }\n    }\n    return 1.0f - (occ * _4512);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4781 = fa_baked_keep(param);\n    if (_4781 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _7213 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _7213;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4807 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _7215 = _4807.color;\n    float _7216 = _4807.attenuation;\n    float _7217 = _4807.shadow;\n    bool _4810 = _4807.type == 0;\n    if (_4810 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4807.direction;\n        float _4821 = fa_shadow_factor(param_5, param_6);\n        _7217 = _4821;\n        _7215 *= _4821;\n    }\n    else\n    {\n        bool _4832 = _4807.type != 0;\n        bool _4838;\n        if (_4832)\n        {\n            _4838 = _7216 > 0.0f;\n        }\n        else\n        {\n            _4838 = _4832;\n        }\n        if (_4838)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4807.direction;\n            float _4857 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7217 = _4857;\n            _7215 *= _4857;\n        }\n    }\n    bool _4867 = _560_fa_ct_a.x > 0.5f;\n    bool _4873;\n    if (_4867)\n    {\n        _4873 = _7216 > 0.0f;\n    }\n    else\n    {\n        _4873 = _4867;\n    }\n    if (_4873)\n    {\n        float _4880;\n        if (_4810)\n        {\n            _4880 = 1000000000.0f;\n        }\n        else\n        {\n            _4880 = _4807._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4807.direction;\n        float param_18 = _4880;\n        float _4898 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7217 *= _4898;\n        _7215 *= _4898;\n    }\n    float _4911 = _7216;\n    float _4912 = _4911 * _4781;\n    _7216 = _4912;\n    float3 _4916 = _7215;\n    float3 _4917 = _4916 * _4781;\n    _7215 = _4917;\n    LightSample _7232 = { _4807.direction, _4917, _4912, _7217, _4807._distance, _4807.type };\n    return _7232;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4951 = v - (n * dot(v, n));\n    float3 t = _4951;\n    float _4955 = dot(_4951, _4951);\n    float l2 = _4955;\n    if (_4955 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4965;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4965 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4965 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4965;\n        l2 = dot(_4965, _4965);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _5000 = dot(a, a);\n    float _5004 = dot(b, b);\n    if ((_5000 < 1.0000000195414813782625560981111e-24f) || (_5004 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _5018 = a * rsqrt(_5000);\n    float3 _5023 = b * rsqrt(_5004);\n    float _5027 = dot(_5018, _5023);\n    float _5030 = abs(_5027);\n    float g = (((((((((((0.0416471660137176513671875f * _5030) - 0.1924748718738555908203125f) * _5030) + 0.4179156124591827392578125f) * _5030) - 0.616057217121124267578125f) * _5030) + 0.777722418308258056640625f) * _5030) - 0.999542415142059326171875f) * _5030) + 1.570791721343994140625f;\n    if (_5027 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_5027 * _5027), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_5018, _5023) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _5087 = a.z > 0.0f;\n    bool _5091 = b.z > 0.0f;\n    if (_5087 && _5091)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5087 != _5091)\n        {\n            float3 _5126 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5126.z = 0.0f;\n            if (_5087)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _5126;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5126;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _5126;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5126;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _5175 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _5201 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _5227 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _5253 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _5175;\n    float3 param_1 = _5201;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _5201;\n    float3 param_7 = _5227;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _5227;\n    float3 param_13 = _5253;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _5253;\n    float3 param_19 = _5175;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _5403 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5427 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5443 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _5403;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _5427;\n    float4 param_9 = m;\n    float3 param_10 = _5403;\n    float3 param_11 = _5427;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _5443;\n    float4 param_14 = m;\n    float3 param_15 = _5403;\n    float3 param_16 = _5443;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5501 = fa_light_base(param);\n    int param_1 = _5501;\n    int param_2 = _5501 + 1;\n    int param_3 = _5501 + 2;\n    int param_4 = _5501 + 4;\n    float4 _5523 = fa_light_texel(param_4);\n    int param_5 = _5501 + 5;\n    float4 _5528 = fa_light_texel(param_5);\n    int param_6 = _5501 + 6;\n    float4 _5533 = fa_light_texel(param_6);\n    float _5534 = _5533.w;\n    float3 _5539 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5541 = _5534 < 1.5f;\n    bool _5548;\n    if (_5541)\n    {\n        _5548 = dot(normalize(fa_light_texel(param_3).xyz), _5539) >= 0.0f;\n    }\n    else\n    {\n        _5548 = _5541;\n    }\n    if (_5548)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5557 = (_5534 > 0.5f) && _5541;\n    float _5561 = _5557 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5564 = _5523.xyz;\n    float _5566 = _5523.w;\n    float3 _5572 = _5528.xyz;\n    float _5574 = _5528.w;\n    float3 up = _5572 * (_5574 * _5561);\n    float _5580;\n    if (_5557)\n    {\n        _5580 = (3.1415927410125732421875f * _5566) * _5566;\n    }\n    else\n    {\n        _5580 = (4.0f * _5566) * _5574;\n    }\n    if (_5534 > 1.5f)\n    {\n        float3 _5606 = cross(_5564, -_5539);\n        float3 perp = _5606;\n        float _5610 = dot(_5606, _5606);\n        float3 _5613;\n        if (_5610 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5613 = perp * rsqrt(_5610);\n        }\n        else\n        {\n            _5613 = _5572;\n        }\n        perp = _5613;\n        up = _5613 * _5574;\n    }\n    float _5634 = max(_5580, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5644 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5644;\n    float3 param_10 = n;\n    float3 param_11 = _5539;\n    float3 _5652 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5644;\n    float3 param_13 = n;\n    float3 param_14 = _5564 * (_5566 * _5561);\n    float3 _5660 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5644;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5668 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5534;\n    float3 param_20 = _5652;\n    float3 param_21 = _5660;\n    float3 param_22 = _5668;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5687 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5687;\n    float2 param_26 = _5687 + float2(64.0f, 0.0f);\n    float4 _5697 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5534;\n    float3 param_29 = _5652;\n    float3 param_30 = _5660;\n    float3 param_31 = _5668;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5697.x) + ((f90.xxx - f0) * _5697.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5539, _5539)) + _5634) / _5634) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4206 = 1.0f / alpha;\n    return ((2.0f + _4206) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4206)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4241 = max(dot(L.nc, l), 0.0f);\n    float _4247 = max(dot(L.nc, h), 0.0f);\n    float _4256 = ((_4247 * _4247) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4256) * _4256)) * (0.5f / max(lerp((2.0f * _4241) * L.coat_ndv, _4241 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4241)) * _4241;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5765;\n    if (L.sheen_on)\n    {\n        _5765 = L.sheen_scale;\n    }\n    else\n    {\n        _5765 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5765);\n    float3 _5778 = normalize(l + v);\n    int param_10 = li;\n    float3 _5789 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5798 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5778), 0.0f);\n        float param_13 = _5798;\n        float param_14 = ndv;\n        result += ((L.sheen * _5789) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5798)) * _5798) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5778;\n        float param_18 = max(dot(v, _5778), 0.0f);\n        result += (_5789 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4109 = tdh / at;\n    float _4113 = bdh / ab;\n    float _4125 = ((_4109 * _4109) + (_4113 * _4113)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4125) * _4125);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4305 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4384 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4384) * _4384);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4305);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4305));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3515 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3518 = _3515.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3518 * _3518, exp2((-9.27999973297119140625f) * ndv)) * _3518) + _3515.y)) + _3515.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_560_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _560_fa_env_horizon.w).xyz;\n    }\n    float _3369 = rough * rough;\n    float _3399 = 0.60000002384185791015625f * _3369;\n    return lerp(lerp(_560_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_560_fa_env_horizon.xyz, _560_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3369)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3399, 0.0500000007450580596923828125f + _3399, d.y).xxx), ((_560_fa_env_sky.xyz + _560_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3369 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3992;\n        if (L.aniso >= 0.0f)\n        {\n            _3992 = L.b;\n        }\n        else\n        {\n            _3992 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3992, v), _3992), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4025 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4025.x) + (L.f90.xxx * _4025.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4080 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4080.x) + _4080.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3557 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3557.x) + _3557.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2227_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3163 = int(_2227_fa_shadow_cfg.x + 0.5f);\n    float _3173 = dot(world - _2227_fa_shadow_eye.xyz, _2227_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3178 = _3163 > 0;\n    bool _3187;\n    if (_3178)\n    {\n        int param = _3163 - 1;\n        _3187 = _3173 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3187 = _3178;\n    }\n    if (_3187)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3193 = _3163 > 1;\n        bool _3200;\n        if (_3193)\n        {\n            _3200 = _3173 > _2227_fa_shadow_split.x;\n        }\n        else\n        {\n            _3200 = _3193;\n        }\n        if (_3200)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3206 = _3163 > 2;\n        bool _3213;\n        if (_3206)\n        {\n            _3213 = _3173 > _2227_fa_shadow_split.y;\n        }\n        else\n        {\n            _3213 = _3206;\n        }\n        if (_3213)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3219 = _3163 > 3;\n        bool _3226;\n        if (_3219)\n        {\n            _3226 = _3173 > _2227_fa_shadow_split.z;\n        }\n        else\n        {\n            _3226 = _3219;\n        }\n        if (_3226)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6915 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6915 = -_6915;\n    }\n    float3 _6267 = normalize(_560_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6928 = { fa_world_pos, _6915, fa_world_tangent, fa_uv, fa_vertex_color, _6267, gl_FrontFacing };\n    SurfaceInput param_1 = _6928;\n    Surface _6275 = fa_standard_surface(param_1);\n    float3 _6946 = _6275.albedo;\n    float _6947 = _6275.alpha;\n    float3 _6948 = _6275.normal;\n    float _6949 = _6275.metallic;\n    float _6950 = _6275.roughness;\n    float _6951 = _6275.occlusion;\n    float3 _6952 = _6275.emission;\n    float _6953 = _6275.clearcoat;\n    float _6954 = _6275.clearcoat_roughness;\n    float3 _6955 = _6275.sheen_color;\n    float _6956 = _6275.sheen_roughness;\n    float _6957 = _6275.anisotropy;\n    float _6958 = _6275.anisotropy_rotation;\n    float _6959 = _6275.specular;\n    float _6960 = _6275.ior;\n    float3 _6961 = _6275.specular_color;\n    SurfaceInput _6936 = { fa_world_pos, _6915, fa_world_tangent, fa_uv, fa_vertex_color, _6267, gl_FrontFacing };\n    SurfaceInput param_2 = _6936;\n    Surface param_3 = _6275;\n    surface(param_2, param_3);\n    _6946 = param_3.albedo;\n    _6947 = param_3.alpha;\n    _6948 = param_3.normal;\n    _6949 = param_3.metallic;\n    _6950 = param_3.roughness;\n    _6951 = param_3.occlusion;\n    _6952 = param_3.emission;\n    _6953 = param_3.clearcoat;\n    _6954 = param_3.clearcoat_roughness;\n    _6955 = param_3.sheen_color;\n    _6956 = param_3.sheen_roughness;\n    _6957 = param_3.anisotropy;\n    _6958 = param_3.anisotropy_rotation;\n    _6959 = param_3.specular;\n    _6960 = param_3.ior;\n    _6961 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6915;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6946 = param_6;\n    _6948 = param_7;\n    if (_6947 < _6303_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_560_fa_emissive.w > 0.5f)\n    {\n        result = _6946;\n    }\n    else\n    {\n        float3 _6325 = normalize(_6948);\n        float _6332 = clamp(_6949, 0.0f, 1.0f);\n        float _6336 = clamp(_6950, 0.0500000007450580596923828125f, 1.0f);\n        float _6340 = _6336 * _6336;\n        float _6344 = _6340 * _6340;\n        float _6349 = max(dot(_6325, _6267), 9.9999997473787516355514526367188e-05f);\n        float3 _6355 = _6946 * (1.0f - _6332);\n        float3 _6362 = lerp(0.039999999105930328369140625f.xxx, _6946, _6332.xxx);\n        float3 f0 = _6362;\n        SurfaceInput _6944 = { fa_world_pos, _6915, fa_world_tangent, fa_uv, fa_vertex_color, _6267, gl_FrontFacing };\n        SurfaceInput param_8 = _6944;\n        Surface _7027 = { _6946, _6947, _6948, _6949, _6950, _6951, _6952, _6953, _6954, _6955, _6956, _6957, _6958, _6959, _6960, _6961 };\n        Surface param_9 = _7027;\n        float3 param_10 = _6325;\n        float3 param_11 = _6267;\n        float param_12 = _6332;\n        float param_13 = _6336;\n        float3 param_14 = _6362;\n        FaLayers _6378 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _6325;\n        float3 lit = (fa_indirect_diffuse(param_15) * _6355) * _6951;\n        if (_6378.on)\n        {\n            lit *= _6378.base_scale;\n        }\n        int _6400 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6400; ln++)\n        {\n            int param_16 = ln;\n            int _6413 = fa_cl_light(param_16);\n            int param_17 = _6413;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _6413;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6915;\n            LightSample _6429 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6437 = max(dot(_6325, _6429.direction), 0.0f);\n            float _6443 = _6429.attenuation * _6429.shadow;\n            float3 _6448 = normalize(_6429.direction + _6267);\n            float _6453 = max(dot(_6325, _6448), 0.0f);\n            float _6458 = max(dot(_6267, _6448), 0.0f);\n            bool _6465;\n            if (fa_light_is_area)\n            {\n                _6465 = !_6378.on;\n            }\n            else\n            {\n                _6465 = fa_light_is_area;\n            }\n            if (_6465)\n            {\n                int param_21 = _6413;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _6325;\n                float3 param_24 = _6267;\n                float3 param_25 = _6355;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _6336;\n                float param_29 = _6349;\n                float param_30 = _6443;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6378;\n                    int param_32 = _6413;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _6325;\n                    float3 param_35 = _6267;\n                    float3 param_36 = _6429.direction;\n                    float3 param_37 = _6355;\n                    float3 param_38 = f0;\n                    float param_39 = _6336;\n                    float param_40 = _6349;\n                    float param_41 = _6443;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6378.on)\n                    {\n                        FaLayers param_42 = _6378;\n                        float3 param_43 = _6355;\n                        float3 param_44 = f0;\n                        float3 param_45 = _6325;\n                        float3 param_46 = _6267;\n                        float3 param_47 = _6429.direction;\n                        float3 param_48 = _6448;\n                        float param_49 = _6437;\n                        float param_50 = _6349;\n                        float param_51 = _6453;\n                        float param_52 = _6458;\n                        float param_53 = _6340;\n                        float param_54 = _6344;\n                        int param_55 = _6413;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6443));\n                    }\n                    else\n                    {\n                        float _6571 = ((_6453 * _6453) * (_6344 - 1.0f)) + 1.0f;\n                        int param_56 = _6413;\n                        lit += (((_6355 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _6458, 5.0f))) * (((_6344 / ((3.1415927410125732421875f * _6571) * _6571)) * (0.5f / max(lerp((2.0f * _6437) * _6349, _6437 + _6349, _6340), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _6437))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6437 * _6443));\n                    }\n                }\n            }\n        }\n        if (_6378.on)\n        {\n            FaLayers param_57 = _6378;\n            float3 param_58 = _6325;\n            float3 param_59 = _6267;\n            float3 param_60 = f0;\n            float param_61 = _6336;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6951);\n        }\n        else\n        {\n            float3 param_62 = _6325;\n            float3 param_63 = _6267;\n            float3 param_64 = f0;\n            float param_65 = _6336;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6951);\n        }\n        result = lit;\n    }\n    float3 _6666 = result;\n    float3 _6667 = _6666 + _6952;\n    result = _6667;\n    float3 param_66 = _6667;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6676 = _560_fa_fog.w > 0.0f;\n    bool _6683;\n    if (!_6676)\n    {\n        _6683 = _560_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6683 = _6676;\n    }\n    if (_6683)\n    {\n        float3 _6692 = fa_world_pos - _560_fa_camera_pos.xyz;\n        float _6698 = dot(_6692, _560_fa_fog_c.xyz);\n        bool _6702 = _560_fa_fog_c.w > 0.5f;\n        float _6703;\n        if (_6702)\n        {\n            _6703 = _6698;\n        }\n        else\n        {\n            _6703 = length(_6692);\n        }\n        float _6715 = _6703 - _560_fa_fog_b.x;\n        if (_6715 > 0.0f)\n        {\n            float _6724 = _560_fa_fog.w * _6715;\n            float tau = _6724 * _6724;\n            if (_560_fa_fog_b.y > 0.0f)\n            {\n                float _6740;\n                if (_6702)\n                {\n                    _6740 = fa_world_pos.y - (_560_fa_fog_c.y * _6698);\n                }\n                else\n                {\n                    _6740 = _560_fa_camera_pos.y;\n                }\n                float _6761 = lerp(_6740, fa_world_pos.y, clamp(_560_fa_fog_b.x / _6703, 0.0f, 1.0f));\n                float _6765 = fa_world_pos.y - _6761;\n                float _6770 = _6761 - _560_fa_fog_b.z;\n                float _6775 = fa_world_pos.y - _560_fa_fog_b.z;\n                bool _6778 = _6770 <= 0.0f;\n                bool _6779 = !_6778;\n                bool _6785;\n                if (_6779)\n                {\n                    _6785 = _560_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6785 = _6778;\n                }\n                float _6786;\n                if (_6785)\n                {\n                    _6786 = _560_fa_fog_b.y;\n                }\n                else\n                {\n                    _6786 = _560_fa_fog_b.y * exp(-min(_560_fa_fog_b.w * _6770, 80.0f));\n                }\n                bool _6813;\n                if (_6779)\n                {\n                    _6813 = _560_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6813 = _6778;\n                }\n                float _6814;\n                if (_6813)\n                {\n                    _6814 = _560_fa_fog_b.y * _6770;\n                }\n                else\n                {\n                    _6814 = (_560_fa_fog_b.y * (1.0f - exp(-min(_560_fa_fog_b.w * _6770, 80.0f)))) / _560_fa_fog_b.w;\n                }\n                bool _6839 = _6775 <= 0.0f;\n                bool _6846;\n                if (!_6839)\n                {\n                    _6846 = _560_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6846 = _6839;\n                }\n                float _6847;\n                if (_6846)\n                {\n                    _6847 = _560_fa_fog_b.y * _6775;\n                }\n                else\n                {\n                    _6847 = (_560_fa_fog_b.y * (1.0f - exp(-min(_560_fa_fog_b.w * _6775, 80.0f)))) / _560_fa_fog_b.w;\n                }\n                float _6874;\n                if (abs(_6765) < 0.001000000047497451305389404296875f)\n                {\n                    _6874 = _6786;\n                }\n                else\n                {\n                    _6874 = (_6847 - _6814) / _6765;\n                }\n                tau += (_6715 * max(_6874, 0.0f));\n            }\n            result = lerp(result, _560_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6947);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_560",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2227",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_6303",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
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
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 9
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
              "hlsl_register_t_n": 10
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
              "hlsl_register_t_n": 11
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
              "hlsl_register_t_n": 12
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 12,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _390 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _390;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _397 = _273.world_pos;\n    fa_world_pos = _397;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_397, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3657[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _560_fa_camera_pos : packoffset(c0);\n    float4 _560_fa_ambient : packoffset(c1);\n    float4 _560_fa_base_color : packoffset(c2);\n    float4 _560_fa_emissive : packoffset(c3);\n    float4 _560_fa_model_emissive : packoffset(c4);\n    float4 _560_fa_pbr : packoffset(c5);\n    float4 _560_fa_maps : packoffset(c6);\n    float4 _560_fa_fog : packoffset(c7);\n    float4 _560_fa_fog_b : packoffset(c8);\n    float4 _560_fa_fog_c : packoffset(c9);\n    float4 _560_fa_counts : packoffset(c10);\n    float4 _560_fa_env_sky : packoffset(c11);\n    float4 _560_fa_env_horizon : packoffset(c12);\n    float4 _560_fa_time : packoffset(c13);\n    float4 _560_fa_cl_vpx : packoffset(c14);\n    float4 _560_fa_cl_vpy : packoffset(c15);\n    float4 _560_fa_cl_vpw : packoffset(c16);\n    float4 _560_fa_cl_fwd : packoffset(c17);\n    float4 _560_fa_cl_grid : packoffset(c18);\n    float4 _560_fa_cl_info : packoffset(c19);\n    float4 _560_fa_layers_a : packoffset(c20);\n    float4 _560_fa_layers_b : packoffset(c21);\n    float4 _560_fa_layers_c : packoffset(c22);\n    float4 _560_fa_layers_d : packoffset(c23);\n    float4 _560_fa_ct_a : packoffset(c24);\n    float4 _560_fa_ct_b : packoffset(c25);\n    float4 _560_fa_ct_vpx : packoffset(c26);\n    float4 _560_fa_ct_vpy : packoffset(c27);\n    float4 _560_fa_ct_vpw : packoffset(c28);\n    float4 _560_fa_ct_fwd : packoffset(c29);\n    float4 _560_fa_probe_sh[9] : packoffset(c30);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2227_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2227_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2227_fa_shadow_info[4] : packoffset(c20);\n    float4 _2227_fa_shadow_split : packoffset(c24);\n    float4 _2227_fa_shadow_cfg : packoffset(c25);\n    float4 _2227_fa_shadow_bias : packoffset(c26);\n    float4 _2227_fa_shadow_eye : packoffset(c27);\n    float4 _2227_fa_shadow_fwd : packoffset(c28);\n    float4 _2227_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _6303_alphaCutoff : packoffset(c0);\n    float _6303_fa_pad0 : packoffset(c0.y);\n    float _6303_fa_pad1 : packoffset(c0.z);\n    float _6303_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t11);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t7);\nTexture2D<float4> fa_screen_tex : register(t12);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t10);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1498 = _560_fa_cl_info.x < 0.0f;\n    bool _1505;\n    if (!_1498)\n    {\n        _1505 = _560_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1505 = _1498;\n    }\n    bool _1513;\n    if (!_1505)\n    {\n        _1513 = _560_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1513 = _1505;\n    }\n    bool _1520;\n    if (!_1513)\n    {\n        _1520 = _560_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1520 = _1513;\n    }\n    bool _1527;\n    if (!_1520)\n    {\n        _1527 = _560_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1527 = _1520;\n    }\n    if (_1527)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1537 = float4(world_pos, 1.0f);\n    float _1543 = dot(_560_fa_cl_vpw, _1537);\n    if (!(_1543 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1565 = float2(dot(_560_fa_cl_vpx, _1537), dot(_560_fa_cl_vpy, _1537)) / _1543.xx;\n    int _1569 = int(_560_fa_cl_grid.x);\n    int _1573 = int(_560_fa_cl_grid.y);\n    int param = (int(_560_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_560_fa_cl_fwd.xyz, world_pos) + _560_fa_cl_fwd.w, _560_fa_cl_grid.w) / _560_fa_cl_grid.w) * _560_fa_cl_grid.z)), 0, int(_560_fa_cl_info.y) - 1) * _1573) + clamp(int(floor(((_1565.y * 0.5f) + 0.5f) * _560_fa_cl_grid.y)), 0, _1573 - 1)) * _1569)) + clamp(int(floor(((_1565.x * 0.5f) + 0.5f) * _560_fa_cl_grid.x)), 0, _1569 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1649 = fa_cluster_texel(param);\n    return int2(int(_1649.x), int(_1649.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_560_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4755 = fa_cluster_lookup(param);\n    fa_cl_slot = _4755.x;\n    fa_cl_local = _4755.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5900 = fa_linear_to_srgb(param);\n        c = _5900;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5908 = fa_srgb_to_linear(param_1);\n            c = _5908;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _442;\n    if (i.front_facing)\n    {\n        _442 = i.world_normal;\n    }\n    else\n    {\n        _442 = -i.world_normal;\n    }\n    float3 _466 = normalize(i.world_tangent.xyz - (_442 * dot(_442, i.world_tangent.xyz)));\n    float3 _493 = normalize(((_466 * m.x) + ((cross(_442, _466) * i.world_tangent.w) * m.y)) + (_442 * m.z));\n    float3 _496;\n    if (i.front_facing)\n    {\n        _496 = _493;\n    }\n    else\n    {\n        _496 = -_493;\n    }\n    return _496;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _560_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5939 = fa_tex_fix(param_2, param_3);\n    float4 _7410 = base_t;\n    _7410.x = _5939.x;\n    _7410.y = _5939.y;\n    _7410.z = _5939.z;\n    base_t = _7410;\n    float4 _5953 = (_7410 * _560_fa_base_color) * i.vertex_color;\n    float3 _7235 = i.world_normal;\n    if (_560_fa_maps.z > 0.5f)\n    {\n        float param_4 = _560_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5985 = fa_tex_fix(param_6, param_7);\n        float3 _5988 = (_5985 * 2.0f) - 1.0f.xxx;\n        float2 _5993 = _5988.xy * _560_fa_maps.x;\n        float3 _7418 = _5988;\n        _7418.x = _5993.x;\n        _7418.y = _5993.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _7418;\n        _7235 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _560_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _6021 = fa_tex_fix(param_12, param_13);\n    float4 _7421 = mrt;\n    _7421.x = _6021.x;\n    _7421.y = _6021.y;\n    _7421.z = _6021.z;\n    mrt = _7421;\n    float4 _6049 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _560_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _6049.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _6060 = fa_tex_fix(param_16, param_17);\n    float param_18 = _560_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _6090 = fa_tex_fix(param_20, param_21);\n    float _7240 = _560_fa_layers_a.x;\n    float _7241 = _560_fa_layers_a.y;\n    float _7244 = _560_fa_layers_a.z;\n    float _7243 = _560_fa_layers_b.w;\n    float _7246 = _560_fa_layers_c.x;\n    if (_560_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_560_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _7240 *= _6060.y;\n            _7241 *= _6060.z;\n            _7243 *= _6049.w;\n        }\n        if (_560_fa_layers_c.z > 1.5f)\n        {\n            _7244 *= mrt.x;\n            _7246 *= mrt.w;\n        }\n    }\n    Surface _7265 = { _5953.xyz, _5953.w, _7235, clamp(_560_fa_pbr.x * _6021.z, 0.0f, 1.0f), clamp(_560_fa_pbr.y * _6021.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_560_fa_maps.y * (_6060.x - 1.0f)), _560_fa_emissive.xyz + (_560_fa_model_emissive.xyz * _6090), _7240, _7241, _560_fa_layers_b.xyz, _7243, _7244, _560_fa_layers_a.w, _7246, _560_fa_layers_c.y, _560_fa_layers_d.xyz };\n    return _7265;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1729 = rect.zw - rect.xy;\n    float2 _1733 = _1729 * atlas;\n    float2 _1737 = ddx * _1733;\n    float2 _1741 = ddy * _1733;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1729), clamp(0.5f * log2(max(max(dot(_1737, _1737), dot(_1741, _1741)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1774 = _560_fa_counts.y < 0.5f;\n    bool _1781;\n    if (!_1774)\n    {\n        _1781 = _560_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1781 = _1774;\n    }\n    if (_1781)\n    {\n        return;\n    }\n    float3 _1787 = ddx(world_pos);\n    float3 _1790 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1794 = fa_cluster_texel(param);\n    int _1798 = int(_1794.w);\n    if (_1798 < 1)\n    {\n        return;\n    }\n    int _1808 = int(_560_fa_counts.y + 0.5f);\n    int param_1 = _1808;\n    float4 _1812 = fa_light_texel(param_1);\n    float2 _1815 = _1812.yz;\n    int _1819 = int(_1812.w);\n    int param_2 = _1808 + 1;\n    float4 _1824 = fa_light_texel(param_2);\n    float _1825 = _1824.x;\n    int _1831 = int(_560_fa_counts.w + 0.5f) - 1;\n    int _1835 = int(_1794.z);\n    float3 _2100;\n    for (int k = 0; k < _1798; k++)\n    {\n        int _1848 = _1835 + k;\n        int param_3 = _1819 + (_1848 >> 2);\n        int _1865 = (_1808 + 2) + (int(fa_light_texel(param_3)[_1848 & 3]) * 7);\n        int param_4 = _1865 + 6;\n        float4 _1870 = fa_light_texel(param_4);\n        if (((int(_1870.w + 0.5f) >> _1831) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1865;\n        float4 _1885 = fa_light_texel(param_5);\n        int param_6 = _1865 + 1;\n        float4 _1890 = fa_light_texel(param_6);\n        int param_7 = _1865 + 2;\n        float4 _1895 = fa_light_texel(param_7);\n        float3 _1898 = _1885.xyz;\n        float _1903 = dot(_1898, world_pos) + _1885.w;\n        float3 _1905 = _1890.xyz;\n        float _1910 = dot(_1905, world_pos) + _1890.w;\n        float3 _1912 = _1895.xyz;\n        float _1917 = dot(_1912, world_pos) + _1895.w;\n        bool _1922 = abs(_1903) > 0.5f;\n        bool _1930;\n        if (!_1922)\n        {\n            _1930 = abs(_1910) > 0.5f;\n        }\n        else\n        {\n            _1930 = _1922;\n        }\n        bool _1938;\n        if (!_1930)\n        {\n            _1938 = abs(_1917) > 0.5f;\n        }\n        else\n        {\n            _1938 = _1930;\n        }\n        if (_1938)\n        {\n            continue;\n        }\n        float _1953 = clamp(dot(geo_normal, normalize(_1912)) * _1870.z, 0.0f, 1.0f);\n        if (_1953 <= 0.0f)\n        {\n            continue;\n        }\n        float _1973 = (clamp((0.5f - abs(_1917)) * 10.0f, 0.0f, 1.0f) * _1953) * _1870.x;\n        float2 _1981 = float2(_1903 + 0.5f, 0.5f - _1910);\n        float2 _1991 = float2(dot(_1898, _1787), dot(_1905, _1787));\n        float2 _2001 = float2(dot(_1898, _1790), dot(_1905, _1790));\n        int param_8 = _1865 + 5;\n        float4 _2006 = fa_light_texel(param_8);\n        int param_9 = _1865 + 3;\n        float4 _2011 = fa_light_texel(param_9);\n        int param_10 = _1865 + 4;\n        float4 _2016 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _2006.xyz;\n        bool _2026 = _2011.z > _2011.x;\n        if (_2026)\n        {\n            float4 param_11 = _2011;\n            float2 param_12 = _1981;\n            float2 param_13 = _1815;\n            float2 param_14 = _1991;\n            float2 param_15 = _2001;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1825 > 0.5f) && (_1825 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _2052 = fa_dc_to_linear(param_16);\n                float4 _7315 = tx;\n                _7315.x = _2052.x;\n                _7315.y = _2052.y;\n                _7315.z = _2052.z;\n                tx = _7315;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1973 * tex_a) * _2006.w, 0.0f, 1.0f).xxx);\n        if (_2016.z > _2016.x)\n        {\n            float4 param_17 = _2016;\n            float2 param_18 = _1981;\n            float2 param_19 = _1815;\n            float2 param_20 = _1991;\n            float2 param_21 = _2001;\n            float4 _2096 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1825 > 1.5f)\n            {\n                float3 param_22 = _2096.xyz;\n                float3 _2106 = fa_dc_to_srgb(param_22);\n                _2100 = _2106;\n            }\n            else\n            {\n                _2100 = _2096.xyz;\n            }\n            float3 _2115 = (_2100 * 2.0f) - 1.0f.xxx;\n            float2 _2120 = _2115.xy * _1870.y;\n            float3 _2142 = (normalize(_1898) * _2120.x) + (normalize(_1905) * _2120.y);\n            float3 _2145 = normalize(normal);\n            normal = normalize(lerp(_2145, normalize((_2145 * max(_2115.z, 0.0500000007450580596923828125f)) + (_2142 - (_2145 * dot(_2145, _2142)))), clamp(_1973 * (_2026 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3583 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3590 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3593 = int(_3583);\n    int _3596 = int(_3590);\n    float _3606 = _3590 - float(_3596);\n    int _3661 = (_3593 * 9) + _3596;\n    int _3681 = ((_3593 + 1) * 9) + _3596;\n    return lerp(lerp(_3657[_3661], _3657[_3661 + 1], _3606), lerp(_3657[_3681], _3657[_3681 + 1], _3606), _3583 - float(_3593));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _7158 = false;\n    float _7159 = 1.0f;\n    float _7160 = 1.0f;\n    float _7161 = 1.0f;\n    float _7162 = 0.0f;\n    float _7163 = 0.0f;\n    float _7164 = 0.0f;\n    float _7165 = 0.0f;\n    float _7167 = 1.0f;\n    bool _7168 = false;\n    float3 _7169 = 0.0f.xxx;\n    float _7170 = 1.0f;\n    float _7171 = 1.0f;\n    float _7172 = 1.0f;\n    float _7173 = 0.0f;\n    float _7174 = 0.0f;\n    float3 _7175 = float3(1.0f, 0.0f, 0.0f);\n    float3 _7176 = float3(0.0f, 0.0f, 1.0f);\n    float _7177 = 1.0f;\n    float _7178 = 1.0f;\n    float _3732 = clamp(s.specular, 0.0f, 1.0f);\n    float _3736 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3741 = (_3732 != 1.0f) || (_3736 != 1.5f);\n    bool _3750;\n    if (!_3741)\n    {\n        _3750 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3750 = _3741;\n    }\n    if (_3750)\n    {\n        float _3758 = (_3736 - 1.0f) / (_3736 + 1.0f);\n        f0 = lerp(min((_3758 * _3758).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3732, s.albedo, metallic.xxx);\n        _7159 = lerp(_3732, 1.0f, metallic);\n        _7158 = true;\n    }\n    float _3785 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3785 > 0.0f)\n    {\n        float _3793 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _7162 = _3785;\n        _7163 = _3793;\n        float _3800 = _3793 * _3793;\n        _7164 = _3800;\n        _7165 = _3800 * _3800;\n        float _3812 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _7167 = _3812;\n        _7160 = 1.0f - (_3785 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3812, 0.0f, 1.0f), 5.0f))));\n        _7158 = true;\n    }\n    float3 _3831 = max(s.sheen_color, 0.0f.xxx);\n    float _3840 = max(_3831.x, max(_3831.y, _3831.z));\n    if (_3840 > 0.0f)\n    {\n        float _3848 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _7168 = true;\n        _7169 = _3831;\n        _7170 = _3848;\n        _7171 = _3848 * _3848;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3848;\n        float _3865 = fa_sheen_albedo(param, param_1);\n        _7173 = _3865;\n        _7172 = 1.0f - min(_3840 * _3865, 1.0f);\n        _7158 = true;\n    }\n    _7161 = _7160 * _7172;\n    float _3884 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3884 != 0.0f)\n    {\n        float3 _3899 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3899;\n        if (dot(_3899, _3899) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3911 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3911.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3911.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3911.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3915 = t;\n        float3 _3916 = normalize(_3915);\n        t = _3916;\n        float3 _3941 = normalize((_3916 * cos(s.anisotropy_rotation)) + ((cross(n, _3916) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _7175 = _3941;\n        _7176 = cross(n, _3941);\n        float _3951 = roughness * roughness;\n        float _3957 = lerp(_3951, 1.0f, _3884 * _3884);\n        bool _3959 = _3884 > 0.0f;\n        _7177 = _3959 ? _3957 : _3951;\n        _7178 = _3959 ? _3951 : _3957;\n        _7174 = _3884;\n        _7158 = true;\n    }\n    FaLayers _7200 = { _7158, _7159, _7160, _7161, _7162, _7163, _7164, _7165, i.world_normal, _7167, _7168, _7169, _7170, _7171, _7172, _7173, _7174, _7175, _7176, _7177, _7178 };\n    return _7200;\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_560_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3340 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3340;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_560_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _560_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_560_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _560_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_560_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_560_fa_cl_info.x) + int(_560_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_560_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4725;\n    if (fa_lm.z > 0.5f)\n    {\n        _4725 = 0.0f;\n    }\n    else\n    {\n        _4725 = 1.0f - clamp(_560_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4736 = _4725 < 1.0f;\n    bool _4742;\n    if (_4736)\n    {\n        int param = li;\n        _4742 = fa_light_baked(param);\n    }\n    else\n    {\n        _4742 = _4736;\n    }\n    return _4742 ? _4725 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _628_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _628_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _747 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _760 = (c - (ru * hx)) - p;\n        float3 _766 = ru * (2.0f * hx);\n        float _772 = max(dot(_766, _766), 9.9999999392252902907785028219223e-09f);\n        float _776 = dot(_760, _766);\n        float t = clamp((-_776) / _772, 0.0f, 1.0f);\n        if (_747)\n        {\n            float _791 = dot(r, _766);\n            float _797 = _772 - (_791 * _791);\n            if (abs(_797) > (9.9999997473787516355514526367188e-06f * _772))\n            {\n                t = clamp(((dot(r, _760) * _791) - _776) / _797, 0.0f, 1.0f);\n            }\n        }\n        return (p + _760) + (_766 * t);\n    }\n    float3 q = p;\n    float _829 = dot(r, axis);\n    bool _837;\n    if (_747)\n    {\n        _837 = abs(_829) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _837 = _747;\n    }\n    if (_837)\n    {\n        float _847 = dot(c - p, axis) / _829;\n        if (_847 > 0.0f)\n        {\n            q = p + (r * _847);\n        }\n    }\n    float3 _860 = q - c;\n    float2 xy = float2(dot(_860, ru), dot(_860, uu));\n    if (shape > 0.5f)\n    {\n        float _875 = length(xy);\n        if (_875 > hx)\n        {\n            xy *= (hx / _875);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _508 = abs(d);\n    float _510 = _508.x;\n    float _512 = _508.y;\n    bool _513 = _510 >= _512;\n    bool _521;\n    if (_513)\n    {\n        _521 = _510 >= _508.z;\n    }\n    else\n    {\n        _521 = _513;\n    }\n    int _522;\n    if (_521)\n    {\n        _522 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _537;\n        if (_512 >= _508.z)\n        {\n            _537 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _537 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _522 = _537;\n    }\n    return _522;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _667 = dot(d, right);\n    float _671 = dot(d, up);\n    float _682;\n    if (((_667 * _667) + (_671 * _671)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _682 = atan2(_671, _667) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _682 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_682 - floor(_682)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _913 = fa_light_base(param);\n    bool _917 = _560_fa_ambient.w > 4.5f;\n    int param_1 = _913;\n    float4 _921 = fa_light_texel(param_1);\n    int param_2 = _913 + 1;\n    float4 _926 = fa_light_texel(param_2);\n    float _929 = _926.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _941 = _917 && (_929 > 2.5f);\n    fa_light_is_area = _941;\n    bool _943 = _929 < 0.5f;\n    float3 l;\n    if (_943)\n    {\n        l = normalize(_921.xyz);\n        if (_917)\n        {\n            int param_3 = _913 + 6;\n            float4 _957 = fa_light_texel(param_3);\n            if (_957.z > 0.5f)\n            {\n                int param_4 = _913 + 4;\n                float4 _967 = fa_light_texel(param_4);\n                int param_5 = _913 + 5;\n                float4 _972 = fa_light_texel(param_5);\n                float2 param_6 = _957.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _967.xyz) * _967.w, (-dot(world_pos, _972.xyz)) * _972.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _1002 = _921.xyz;\n        float3 _1004 = _1002 - world_pos;\n        float3 to_light = _1004;\n        float _1007 = length(_1004);\n        float reach = _1007;\n        bool front = true;\n        if (_941)\n        {\n            int param_8 = _913 + 7;\n            reach = max(_1007 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _913 + 4;\n            float4 _1031 = fa_light_texel(param_9);\n            int param_10 = _913 + 5;\n            float4 _1036 = fa_light_texel(param_10);\n            int param_11 = _913 + 6;\n            float4 _1041 = fa_light_texel(param_11);\n            float _1042 = _1041.w;\n            int param_12 = _913 + 2;\n            float3 _1049 = normalize(fa_light_texel(param_12).xyz);\n            bool _1051 = _1042 > 1.5f;\n            bool _1059;\n            if (!_1051)\n            {\n                _1059 = dot(_1049, to_light) < 0.0f;\n            }\n            else\n            {\n                _1059 = _1051;\n            }\n            front = _1059;\n            float3 r = 0.0f.xxx;\n            float3 _1068 = _560_fa_camera_pos.xyz - world_pos;\n            bool _1072 = dot(n, n) > 0.5f;\n            bool _1080;\n            if (_1072)\n            {\n                _1080 = dot(_1068, _1068) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1080 = _1072;\n            }\n            if (_1080)\n            {\n                r = reflect(-normalize(_1068), normalize(n));\n            }\n            float3 param_13 = _1002;\n            float3 param_14 = _1049;\n            float3 param_15 = _1031.xyz;\n            float3 param_16 = _1036.xyz;\n            float param_17 = _1031.w;\n            float param_18 = _1036.w;\n            float param_19 = _1042;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1116 = length(to_light);\n        dist = _1116;\n        l = to_light / max(_1116, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1130 = reach / max(_921.w, 0.001000000047497451305389404296875f);\n        float _1136 = clamp(1.0f - (_1130 * _1130), 0.0f, 1.0f);\n        float _1138;\n        if (front)\n        {\n            _1138 = _1136 * _1136;\n        }\n        else\n        {\n            _1138 = 0.0f;\n        }\n        atten = _1138;\n        bool _1149 = _929 < 2.5f;\n        if ((_929 > 1.5f) && _1149)\n        {\n            int param_22 = _913 + 2;\n            float4 _1157 = fa_light_texel(param_22);\n            float _1167 = _1157.w;\n            int param_23 = _913 + 3;\n            float4 _1172 = fa_light_texel(param_23);\n            float _1173 = _1172.x;\n            float cos_inner = _1173;\n            if (_1173 > 1.5f)\n            {\n                cos_inner = lerp(_1167, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1167, cos_inner, dot(-l, normalize(_1157.xyz)));\n        }\n        if (_917 && (_929 < 1.5f))\n        {\n            int param_24 = _913 + 6;\n            float4 _1197 = fa_light_texel(param_24);\n            if (_1197.z > 0.5f)\n            {\n                float3 _1205 = -to_light;\n                int param_25 = _913 + 4;\n                int param_26 = _913 + 5;\n                float3 _1219 = fa_light_texel(param_25).xyz;\n                float3 _1223 = fa_light_texel(param_26).xyz;\n                float3 _1232 = float3(dot(_1205, _1219), dot(_1205, _1223), dot(_1205, cross(_1219, _1223)));\n                float3 param_27 = _1232;\n                int _1236 = fa_cube_face(param_27);\n                int param_28 = _1236;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1263 = float2(dot(_1232, cross(param_29, param_30)), dot(_1232, param_30)) / max(dot(_1232, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1267 = _1236 / 3;\n                float2 param_31 = _1197.xy + (float2(float(_1236 - (_1267 * 3)), float(_1267)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1263.x), 0.5f - (0.5f * _1263.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _913 + 7;\n            float4 _1297 = fa_light_texel(param_33);\n            if (_1297.z > 0.5f)\n            {\n                int param_34 = _913 + 2;\n                int param_35 = _913 + 4;\n                int param_36 = _913 + 5;\n                float2 param_37 = _1297.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_917 && _1149)\n            {\n                int param_42 = _913 + 6;\n                float4 _1344 = fa_light_texel(param_42);\n                int param_43 = _913 + 7;\n                float4 _1349 = fa_light_texel(param_43);\n                bool _1352 = _1344.z > 0.5f;\n                bool _1359;\n                if (!_1352)\n                {\n                    _1359 = _1349.z > 0.5f;\n                }\n                else\n                {\n                    _1359 = _1352;\n                }\n                if (_1359)\n                {\n                    int param_44 = _913 + 2;\n                    float4 _1366 = fa_light_texel(param_44);\n                    float3 _1370 = normalize(_1366.xyz);\n                    int param_45 = _913 + 4;\n                    float4 _1375 = fa_light_texel(param_45);\n                    int param_46 = _913 + 5;\n                    float4 _1380 = fa_light_texel(param_46);\n                    if (_1352)\n                    {\n                        float3 _1388 = -to_light;\n                        float _1395 = _1366.w;\n                        float _1411 = 0.5f / max(dot(_1388, _1370) * (sqrt(max(1.0f - (_1395 * _1395), 0.0f)) / max(_1395, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1344.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1388, _1375.xyz) * _1411), 0.5f - (dot(_1388, _1380.xyz) * _1411));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1349.z > 0.5f)\n                    {\n                        float2 param_49 = _1349.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1370;\n                        float3 param_52 = _1375.xyz;\n                        float3 param_53 = _1380.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _7146 = _926.xyz * atten;\n    if (_917)\n    {\n        _7146 *= fa_light_tint;\n    }\n    int _1480;\n    if (_943)\n    {\n        _1480 = 0;\n    }\n    else\n    {\n        _1480 = ((_929 > 1.5f) && (_929 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _7157 = { l, _7146, atten, 1.0f, dist, _1480 };\n    return _7157;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2217;\n    if (i == 0)\n    {\n        _2217 = _2227_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2233;\n        if (i == 1)\n        {\n            _2233 = _2227_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2241;\n            if (i == 2)\n            {\n                _2241 = _2227_fa_shadow_split.z;\n            }\n            else\n            {\n                _2241 = _2227_fa_shadow_split.w;\n            }\n            _2233 = _2241;\n        }\n        _2217 = _2233;\n    }\n    return _2217;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2274 = fa_shadow_depth(param, param_1);\n    float _2278;\n    if (conv.x < 0.5f)\n    {\n        _2278 = _2274;\n    }\n    else\n    {\n        _2278 = (conv.y * conv.z) / (conv.z - (_2274 * (conv.z - conv.y)));\n    }\n    return _2278;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2205 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2205), sin(_2205)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2324 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2333;\n        if (k < 0.0f)\n        {\n            _2333 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2333 = k;\n        }\n        float _2353 = clamp((_2333 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2324;\n            float2 _2372 = fa_shadow_vogel(param_3, param_4, param_5) * _2353;\n            float2 param_6 = uv + (_2372 * _2227_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2384 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2384 < (zr - (length(_2372) * plane)))\n            {\n                sum += _2384;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2410 = sum / cnt;\n        float _2420;\n        if (k < 0.0f)\n        {\n            _2420 = (-k) / max(_2410, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2420 = k;\n        }\n        radius = clamp(((max(zr - _2410, 0.0f) * unit) * _2420) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2442 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2442; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2442;\n        float param_11 = _2324;\n        float2 _2461 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2461 * _2227_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2461) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2442);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2503 = max(_2227_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2508 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2514 = sqrt(1.0f - (_2508 * _2508));\n    float _2521 = min(_2514 / max(_2508, 0.20000000298023223876953125f), 4.0f);\n    float _2526;\n    if (_2227_fa_shadow_bias.y > 0.0f)\n    {\n        _2526 = _2227_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2526 = 1.5f * _2227_fa_shadow_info[ci].x;\n    }\n    float4 _2551 = mul(float4(world + (n * (_2526 * _2514)), 1.0f), _2227_fa_shadow_mat[ci]);\n    float _2558 = _2551.x;\n    bool _2561 = _2558 < _2227_fa_shadow_rect[ci].x;\n    bool _2570;\n    if (!_2561)\n    {\n        _2570 = _2558 > _2227_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2570 = _2561;\n    }\n    bool _2579;\n    if (!_2570)\n    {\n        _2579 = _2551.y < _2227_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2579 = _2570;\n    }\n    bool _2588;\n    if (!_2579)\n    {\n        _2588 = _2551.y > _2227_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2588 = _2579;\n    }\n    bool _2595;\n    if (!_2588)\n    {\n        _2595 = _2551.z > 1.0f;\n    }\n    else\n    {\n        _2595 = _2588;\n    }\n    if (_2595)\n    {\n        return -1.0f;\n    }\n    float _2603;\n    if (_2227_fa_shadow_bias.x > 0.0f)\n    {\n        _2603 = _2227_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2603 = 1.5f * _2227_fa_shadow_info[ci].x;\n    }\n    float2 param = _2551.xy;\n    float4 param_1 = _2227_fa_shadow_rect[ci];\n    float param_2 = _2551.z - ((_2603 * (1.0f + (0.5f * _2521))) / _2503);\n    float param_3 = _2227_fa_shadow_info[ci].x;\n    float param_4 = _2503;\n    float param_5 = _2503 * 0.25f;\n    float param_6 = ((_2227_fa_shadow_info[ci].x * min(_2521, 3.0f)) * 0.5f) / _2503;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2227_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2227_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_560_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2981 = int(_2227_fa_shadow_cfg.x + 0.5f);\n    if (_2981 < 1)\n    {\n        return 1.0f;\n    }\n    float _2996 = dot(world - _2227_fa_shadow_eye.xyz, _2227_fa_shadow_fwd.xyz);\n    int param = _2981 - 1;\n    if (_2996 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _3008 = _2981 > 1;\n    bool _3015;\n    if (_3008)\n    {\n        _3015 = _2996 > _2227_fa_shadow_split.x;\n    }\n    else\n    {\n        _3015 = _3008;\n    }\n    if (_3015)\n    {\n        ci = 1;\n    }\n    bool _3019 = _2981 > 2;\n    bool _3026;\n    if (_3019)\n    {\n        _3026 = _2996 > _2227_fa_shadow_split.y;\n    }\n    else\n    {\n        _3026 = _3019;\n    }\n    if (_3026)\n    {\n        ci = 2;\n    }\n    bool _3030 = _2981 > 3;\n    bool _3037;\n    if (_3030)\n    {\n        _3037 = _2996 > _2227_fa_shadow_split.z;\n    }\n    else\n    {\n        _3037 = _3030;\n    }\n    if (_3037)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2981)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3063 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3063;\n        if (_3063 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2227_fa_shadow_cfg.y > 0.0f)\n    {\n        float _3088;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3088 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3088 = _2227_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _3107 = _2227_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3088, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _3118 = clamp((_2996 - (fa_shadow_split_at(param_7) - _3107)) / _3107, 0.0f, 1.0f);\n        if (_3118 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2981)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3139 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3139;\n                if (_3139 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _3118);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2661 = _560_fa_pbr.z < 0.5f;\n    bool _2668;\n    if (!_2661)\n    {\n        _2668 = _2227_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2668 = _2661;\n    }\n    if (_2668)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2227_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2681 = fa_light_texel(param);\n    float _2682 = _2681.x;\n    if (_2682 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2691 = int(_2682 + 0.5f);\n    int param_1 = _2691;\n    float4 _2695 = fa_light_texel(param_1);\n    int param_2 = _2691 + 1;\n    float4 _2700 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2703 = _2695.y;\n    if (_2703 > 0.0f)\n    {\n        float _2720 = 1.0f - smoothstep(0.75f * _2703, _2703, length(world - _2227_fa_shadow_eye.xyz));\n        fade = _2720;\n        if (_2720 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2695.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2744 = (_2691 + 2) + (face * 6);\n    int param_4 = _2744;\n    int param_5 = _2744 + 1;\n    int param_6 = _2744 + 3;\n    float4 _2758 = fa_light_texel(param_6);\n    int param_7 = _2744 + 4;\n    float4 _2763 = fa_light_texel(param_7);\n    int param_8 = _2744 + 5;\n    float4 _2768 = fa_light_texel(param_8);\n    float _2780 = _2768.x * max(dot(_2758, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2785 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2808 = clamp(dot(n, _2758.xyz), -1.0f, 1.0f);\n    float _2827 = min(sqrt(1.0f - (_2808 * _2808)) / max(abs(dot(n, world - lpos)) / max(dot(_2758, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2830 = _2700.y;\n    float _2832;\n    if (_2830 > 0.0f)\n    {\n        _2832 = _2830;\n    }\n    else\n    {\n        _2832 = 1.5f * _2780;\n    }\n    float4 _2852 = float4(world + (n * (_2832 * sqrt(1.0f - (_2785 * _2785)))), 1.0f);\n    float _2856 = dot(_2758, _2852);\n    float _2859 = _2768.y;\n    if (_2856 < _2859)\n    {\n        return 1.0f;\n    }\n    float2 _2874 = float2(dot(fa_light_texel(param_4), _2852), dot(fa_light_texel(param_5), _2852)) / _2856.xx;\n    float _2876 = _2874.x;\n    bool _2879 = _2876 < _2763.x;\n    bool _2888;\n    if (!_2879)\n    {\n        _2888 = _2876 > _2763.z;\n    }\n    else\n    {\n        _2888 = _2879;\n    }\n    bool _2897;\n    if (!_2888)\n    {\n        _2897 = _2874.y < _2763.y;\n    }\n    else\n    {\n        _2897 = _2888;\n    }\n    bool _2906;\n    if (!_2897)\n    {\n        _2906 = _2874.y > _2763.w;\n    }\n    else\n    {\n        _2906 = _2897;\n    }\n    if (_2906)\n    {\n        return 1.0f;\n    }\n    float _2912 = _2700.x;\n    float _2914;\n    if (_2912 > 0.0f)\n    {\n        _2914 = _2912;\n    }\n    else\n    {\n        _2914 = 1.5f * _2780;\n    }\n    float2 param_9 = _2874;\n    float4 param_10 = _2763;\n    float param_11 = _2856 - (_2914 * (1.0f + (0.5f * _2827)));\n    float param_12 = _2780;\n    float param_13 = 1.0f;\n    float param_14 = _2768.z * 0.25f;\n    float param_15 = (_2780 * min(_2827, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2859, _2768.z);\n    int param_17 = int(_2695.z + 0.5f);\n    float param_18 = _2695.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4469 = _560_fa_ct_a.x < 0.5f;\n    bool _4476;\n    if (!_4469)\n    {\n        _4476 = _2227_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4476 = _4469;\n    }\n    if (_4476)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2227_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4489 = fa_light_texel(param);\n    float _4490 = _4489.y;\n    float len = _4490;\n    if (_4490 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4502 = length(world - _560_fa_camera_pos.xyz);\n    float _4512 = 1.0f - smoothstep(0.5f * _560_fa_ct_b.x, _560_fa_ct_b.x, _4502);\n    if (_4512 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4518 = len;\n    float _4521 = min(_4518, 0.89999997615814208984375f * dist);\n    len = _4521;\n    float _4526 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4502);\n    float _4531 = _4526 + (0.5f * _4521);\n    float3 _4537 = world + (gn * _4526);\n    float _4539 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4603;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4554 = (float(k) + _4539) * 0.083333335816860198974609375f;\n        float3 _4562 = _4537 + (l * (_4554 * len));\n        float4 _4568 = float4(_4562, 1.0f);\n        float _4574 = dot(_560_fa_ct_vpw, _4568);\n        if (_4574 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4594 = float2(dot(_560_fa_ct_vpx, _4568), dot(_560_fa_ct_vpy, _4568)) / _4574.xx;\n        float _4598 = _4594.x * 0.5f;\n        float _4599 = _4598 + 0.5f;\n        if (_560_fa_ct_a.y > 0.5f)\n        {\n            _4603 = (_4594.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4603 = 0.5f - (_4594.y * 0.5f);\n        }\n        bool _4619 = _4599 < 0.0f;\n        bool _4626;\n        if (!_4619)\n        {\n            _4626 = _4599 >= 1.0f;\n        }\n        else\n        {\n            _4626 = _4619;\n        }\n        bool _4633;\n        if (!_4626)\n        {\n            _4633 = _4603 < 0.0f;\n        }\n        else\n        {\n            _4633 = _4626;\n        }\n        bool _4640;\n        if (!_4633)\n        {\n            _4640 = _4603 >= 1.0f;\n        }\n        else\n        {\n            _4640 = _4633;\n        }\n        if (_4640)\n        {\n            break;\n        }\n        float4 _4659 = fa_screen_tex.Load(int3(int2(float2(_4599, _4603) * _560_fa_ct_a.zw), 0));\n        if (_4659.w < 0.5f)\n        {\n            continue;\n        }\n        float _4678 = (dot(_560_fa_ct_fwd.xyz, _4562) + _560_fa_ct_fwd.w) - _4659.x;\n        if ((_4678 > _4526) && (_4678 < _4531))\n        {\n            occ = max(occ, (1.0f - (_4554 * _4554)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4599, 0.5f - _4598), min(_4603, 1.0f - _4603))));\n        }\n    }\n    return 1.0f - (occ * _4512);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4781 = fa_baked_keep(param);\n    if (_4781 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _7213 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _7213;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4807 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _7215 = _4807.color;\n    float _7216 = _4807.attenuation;\n    float _7217 = _4807.shadow;\n    bool _4810 = _4807.type == 0;\n    if (_4810 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4807.direction;\n        float _4821 = fa_shadow_factor(param_5, param_6);\n        _7217 = _4821;\n        _7215 *= _4821;\n    }\n    else\n    {\n        bool _4832 = _4807.type != 0;\n        bool _4838;\n        if (_4832)\n        {\n            _4838 = _7216 > 0.0f;\n        }\n        else\n        {\n            _4838 = _4832;\n        }\n        if (_4838)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4807.direction;\n            float _4857 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7217 = _4857;\n            _7215 *= _4857;\n        }\n    }\n    bool _4867 = _560_fa_ct_a.x > 0.5f;\n    bool _4873;\n    if (_4867)\n    {\n        _4873 = _7216 > 0.0f;\n    }\n    else\n    {\n        _4873 = _4867;\n    }\n    if (_4873)\n    {\n        float _4880;\n        if (_4810)\n        {\n            _4880 = 1000000000.0f;\n        }\n        else\n        {\n            _4880 = _4807._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4807.direction;\n        float param_18 = _4880;\n        float _4898 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7217 *= _4898;\n        _7215 *= _4898;\n    }\n    float _4911 = _7216;\n    float _4912 = _4911 * _4781;\n    _7216 = _4912;\n    float3 _4916 = _7215;\n    float3 _4917 = _4916 * _4781;\n    _7215 = _4917;\n    LightSample _7232 = { _4807.direction, _4917, _4912, _7217, _4807._distance, _4807.type };\n    return _7232;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _4951 = v - (n * dot(v, n));\n    float3 t = _4951;\n    float _4955 = dot(_4951, _4951);\n    float l2 = _4955;\n    if (_4955 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _4965;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _4965 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _4965 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _4965;\n        l2 = dot(_4965, _4965);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _5000 = dot(a, a);\n    float _5004 = dot(b, b);\n    if ((_5000 < 1.0000000195414813782625560981111e-24f) || (_5004 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _5018 = a * rsqrt(_5000);\n    float3 _5023 = b * rsqrt(_5004);\n    float _5027 = dot(_5018, _5023);\n    float _5030 = abs(_5027);\n    float g = (((((((((((0.0416471660137176513671875f * _5030) - 0.1924748718738555908203125f) * _5030) + 0.4179156124591827392578125f) * _5030) - 0.616057217121124267578125f) * _5030) + 0.777722418308258056640625f) * _5030) - 0.999542415142059326171875f) * _5030) + 1.570791721343994140625f;\n    if (_5027 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_5027 * _5027), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_5018, _5023) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _5087 = a.z > 0.0f;\n    bool _5091 = b.z > 0.0f;\n    if (_5087 && _5091)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5087 != _5091)\n        {\n            float3 _5126 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5126.z = 0.0f;\n            if (_5087)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _5126;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5126;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _5126;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5126;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _5175 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _5201 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _5227 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _5253 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _5175;\n    float3 param_1 = _5201;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _5201;\n    float3 param_7 = _5227;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _5227;\n    float3 param_13 = _5253;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _5253;\n    float3 param_19 = _5175;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _5403 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5427 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _5443 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _5403;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _5427;\n    float4 param_9 = m;\n    float3 param_10 = _5403;\n    float3 param_11 = _5427;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _5443;\n    float4 param_14 = m;\n    float3 param_15 = _5403;\n    float3 param_16 = _5443;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5501 = fa_light_base(param);\n    int param_1 = _5501;\n    int param_2 = _5501 + 1;\n    int param_3 = _5501 + 2;\n    int param_4 = _5501 + 4;\n    float4 _5523 = fa_light_texel(param_4);\n    int param_5 = _5501 + 5;\n    float4 _5528 = fa_light_texel(param_5);\n    int param_6 = _5501 + 6;\n    float4 _5533 = fa_light_texel(param_6);\n    float _5534 = _5533.w;\n    float3 _5539 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5541 = _5534 < 1.5f;\n    bool _5548;\n    if (_5541)\n    {\n        _5548 = dot(normalize(fa_light_texel(param_3).xyz), _5539) >= 0.0f;\n    }\n    else\n    {\n        _5548 = _5541;\n    }\n    if (_5548)\n    {\n        return 0.0f.xxx;\n    }\n    bool _5557 = (_5534 > 0.5f) && _5541;\n    float _5561 = _5557 ? 1.0539000034332275390625f : 1.0f;\n    float3 _5564 = _5523.xyz;\n    float _5566 = _5523.w;\n    float3 _5572 = _5528.xyz;\n    float _5574 = _5528.w;\n    float3 up = _5572 * (_5574 * _5561);\n    float _5580;\n    if (_5557)\n    {\n        _5580 = (3.1415927410125732421875f * _5566) * _5566;\n    }\n    else\n    {\n        _5580 = (4.0f * _5566) * _5574;\n    }\n    if (_5534 > 1.5f)\n    {\n        float3 _5606 = cross(_5564, -_5539);\n        float3 perp = _5606;\n        float _5610 = dot(_5606, _5606);\n        float3 _5613;\n        if (_5610 > 1.0000000133514319600180897396058e-10f)\n        {\n            _5613 = perp * rsqrt(_5610);\n        }\n        else\n        {\n            _5613 = _5572;\n        }\n        perp = _5613;\n        up = _5613 * _5574;\n    }\n    float _5634 = max(_5580, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _5644 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _5644;\n    float3 param_10 = n;\n    float3 param_11 = _5539;\n    float3 _5652 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _5644;\n    float3 param_13 = n;\n    float3 param_14 = _5564 * (_5566 * _5561);\n    float3 _5660 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _5644;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _5668 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _5534;\n    float3 param_20 = _5652;\n    float3 param_21 = _5660;\n    float3 param_22 = _5668;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _5687 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _5687;\n    float2 param_26 = _5687 + float2(64.0f, 0.0f);\n    float4 _5697 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5534;\n    float3 param_29 = _5652;\n    float3 param_30 = _5660;\n    float3 param_31 = _5668;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5697.x) + ((f90.xxx - f0) * _5697.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_5539, _5539)) + _5634) / _5634) * window);\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4206 = 1.0f / alpha;\n    return ((2.0f + _4206) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _4206)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat fa_layers_coat(FaLayers L, float3 l, float3 h, float vdh)\n{\n    float _4241 = max(dot(L.nc, l), 0.0f);\n    float _4247 = max(dot(L.nc, h), 0.0f);\n    float _4256 = ((_4247 * _4247) * (L.coat_a2 - 1.0f)) + 1.0f;\n    return (((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _4256) * _4256)) * (0.5f / max(lerp((2.0f * _4241) * L.coat_ndv, _4241 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4241)) * _4241;\n}\n\nfloat3 fa_area_layers(FaLayers L, int li, float3 world_pos, float3 n, float3 v, float3 l, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    float3 param_2 = n;\n    float3 param_3 = v;\n    float3 param_4 = diffuse_color;\n    float3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5765;\n    if (L.sheen_on)\n    {\n        _5765 = L.sheen_scale;\n    }\n    else\n    {\n        _5765 = 1.0f;\n    }\n    float3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5765);\n    float3 _5778 = normalize(l + v);\n    int param_10 = li;\n    float3 _5789 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5798 = max(dot(n, l), 0.0f);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5778), 0.0f);\n        float param_13 = _5798;\n        float param_14 = ndv;\n        result += ((L.sheen * _5789) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875f) * step(9.9999997473787516355514526367188e-05f, _5798)) * _5798) * L.keep));\n    }\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_15 = L;\n        float3 param_16 = l;\n        float3 param_17 = _5778;\n        float param_18 = max(dot(v, _5778), 0.0f);\n        result += (_5789 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4109 = tdh / at;\n    float _4113 = bdh / ab;\n    float _4125 = ((_4109 * _4109) + (_4113 * _4113)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _4125) * _4125);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4305 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4384 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _4384) * _4384);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _4305);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _4305));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        FaLayers param_17 = L;\n        float3 param_18 = l;\n        float3 param_19 = h;\n        float param_20 = vdh;\n        result += fa_layers_coat(param_17, param_18, param_19, param_20).xxx;\n    }\n    return result;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3515 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3518 = _3515.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3518 * _3518, exp2((-9.27999973297119140625f) * ndv)) * _3518) + _3515.y)) + _3515.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_560_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _560_fa_env_horizon.w).xyz;\n    }\n    float _3369 = rough * rough;\n    float _3399 = 0.60000002384185791015625f * _3369;\n    return lerp(lerp(_560_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_560_fa_env_horizon.xyz, _560_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3369)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3399, 0.0500000007450580596923828125f + _3399, d.y).xxx), ((_560_fa_env_sky.xyz + _560_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3369 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3992;\n        if (L.aniso >= 0.0f)\n        {\n            _3992 = L.b;\n        }\n        else\n        {\n            _3992 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3992, v), _3992), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4025 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4025.x) + (L.f90.xxx * _4025.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4080 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4080.x) + _4080.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3557 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3557.x) + _3557.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2227_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3163 = int(_2227_fa_shadow_cfg.x + 0.5f);\n    float _3173 = dot(world - _2227_fa_shadow_eye.xyz, _2227_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3178 = _3163 > 0;\n    bool _3187;\n    if (_3178)\n    {\n        int param = _3163 - 1;\n        _3187 = _3173 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3187 = _3178;\n    }\n    if (_3187)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3193 = _3163 > 1;\n        bool _3200;\n        if (_3193)\n        {\n            _3200 = _3173 > _2227_fa_shadow_split.x;\n        }\n        else\n        {\n            _3200 = _3193;\n        }\n        if (_3200)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3206 = _3163 > 2;\n        bool _3213;\n        if (_3206)\n        {\n            _3213 = _3173 > _2227_fa_shadow_split.y;\n        }\n        else\n        {\n            _3213 = _3206;\n        }\n        if (_3213)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3219 = _3163 > 3;\n        bool _3226;\n        if (_3219)\n        {\n            _3226 = _3173 > _2227_fa_shadow_split.z;\n        }\n        else\n        {\n            _3226 = _3219;\n        }\n        if (_3226)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _6915 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6915 = -_6915;\n    }\n    float3 _6267 = normalize(_560_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6928 = { fa_world_pos, _6915, fa_world_tangent, fa_uv, fa_vertex_color, _6267, gl_FrontFacing };\n    SurfaceInput param_1 = _6928;\n    Surface _6275 = fa_standard_surface(param_1);\n    float3 _6946 = _6275.albedo;\n    float _6947 = _6275.alpha;\n    float3 _6948 = _6275.normal;\n    float _6949 = _6275.metallic;\n    float _6950 = _6275.roughness;\n    float _6951 = _6275.occlusion;\n    float3 _6952 = _6275.emission;\n    float _6953 = _6275.clearcoat;\n    float _6954 = _6275.clearcoat_roughness;\n    float3 _6955 = _6275.sheen_color;\n    float _6956 = _6275.sheen_roughness;\n    float _6957 = _6275.anisotropy;\n    float _6958 = _6275.anisotropy_rotation;\n    float _6959 = _6275.specular;\n    float _6960 = _6275.ior;\n    float3 _6961 = _6275.specular_color;\n    SurfaceInput _6936 = { fa_world_pos, _6915, fa_world_tangent, fa_uv, fa_vertex_color, _6267, gl_FrontFacing };\n    SurfaceInput param_2 = _6936;\n    Surface param_3 = _6275;\n    surface(param_2, param_3);\n    _6946 = param_3.albedo;\n    _6947 = param_3.alpha;\n    _6948 = param_3.normal;\n    _6949 = param_3.metallic;\n    _6950 = param_3.roughness;\n    _6951 = param_3.occlusion;\n    _6952 = param_3.emission;\n    _6953 = param_3.clearcoat;\n    _6954 = param_3.clearcoat_roughness;\n    _6955 = param_3.sheen_color;\n    _6956 = param_3.sheen_roughness;\n    _6957 = param_3.anisotropy;\n    _6958 = param_3.anisotropy_rotation;\n    _6959 = param_3.specular;\n    _6960 = param_3.ior;\n    _6961 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6915;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6946 = param_6;\n    _6948 = param_7;\n    if (_6947 < _6303_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_560_fa_emissive.w > 0.5f)\n    {\n        result = _6946;\n    }\n    else\n    {\n        float3 _6325 = normalize(_6948);\n        float _6332 = clamp(_6949, 0.0f, 1.0f);\n        float _6336 = clamp(_6950, 0.0500000007450580596923828125f, 1.0f);\n        float _6340 = _6336 * _6336;\n        float _6344 = _6340 * _6340;\n        float _6349 = max(dot(_6325, _6267), 9.9999997473787516355514526367188e-05f);\n        float3 _6355 = _6946 * (1.0f - _6332);\n        float3 _6362 = lerp(0.039999999105930328369140625f.xxx, _6946, _6332.xxx);\n        float3 f0 = _6362;\n        SurfaceInput _6944 = { fa_world_pos, _6915, fa_world_tangent, fa_uv, fa_vertex_color, _6267, gl_FrontFacing };\n        SurfaceInput param_8 = _6944;\n        Surface _7027 = { _6946, _6947, _6948, _6949, _6950, _6951, _6952, _6953, _6954, _6955, _6956, _6957, _6958, _6959, _6960, _6961 };\n        Surface param_9 = _7027;\n        float3 param_10 = _6325;\n        float3 param_11 = _6267;\n        float param_12 = _6332;\n        float param_13 = _6336;\n        float3 param_14 = _6362;\n        FaLayers _6378 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _6325;\n        float3 lit = (fa_indirect_diffuse(param_15) * _6355) * _6951;\n        if (_6378.on)\n        {\n            lit *= _6378.base_scale;\n        }\n        int _6400 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6400; ln++)\n        {\n            int param_16 = ln;\n            int _6413 = fa_cl_light(param_16);\n            int param_17 = _6413;\n            if (fa_baked_keep(param_17) <= 0.0f)\n            {\n                continue;\n            }\n            int param_18 = _6413;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _6915;\n            LightSample _6429 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6437 = max(dot(_6325, _6429.direction), 0.0f);\n            float _6443 = _6429.attenuation * _6429.shadow;\n            float3 _6448 = normalize(_6429.direction + _6267);\n            float _6453 = max(dot(_6325, _6448), 0.0f);\n            float _6458 = max(dot(_6267, _6448), 0.0f);\n            bool _6465;\n            if (fa_light_is_area)\n            {\n                _6465 = !_6378.on;\n            }\n            else\n            {\n                _6465 = fa_light_is_area;\n            }\n            if (_6465)\n            {\n                int param_21 = _6413;\n                float3 param_22 = fa_world_pos;\n                float3 param_23 = _6325;\n                float3 param_24 = _6267;\n                float3 param_25 = _6355;\n                float3 param_26 = f0;\n                float param_27 = 1.0f;\n                float param_28 = _6336;\n                float param_29 = _6349;\n                float param_30 = _6443;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6378;\n                    int param_32 = _6413;\n                    float3 param_33 = fa_world_pos;\n                    float3 param_34 = _6325;\n                    float3 param_35 = _6267;\n                    float3 param_36 = _6429.direction;\n                    float3 param_37 = _6355;\n                    float3 param_38 = f0;\n                    float param_39 = _6336;\n                    float param_40 = _6349;\n                    float param_41 = _6443;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6378.on)\n                    {\n                        FaLayers param_42 = _6378;\n                        float3 param_43 = _6355;\n                        float3 param_44 = f0;\n                        float3 param_45 = _6325;\n                        float3 param_46 = _6267;\n                        float3 param_47 = _6429.direction;\n                        float3 param_48 = _6448;\n                        float param_49 = _6437;\n                        float param_50 = _6349;\n                        float param_51 = _6453;\n                        float param_52 = _6458;\n                        float param_53 = _6340;\n                        float param_54 = _6344;\n                        int param_55 = _6413;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6443));\n                    }\n                    else\n                    {\n                        float _6571 = ((_6453 * _6453) * (_6344 - 1.0f)) + 1.0f;\n                        int param_56 = _6413;\n                        lit += (((_6355 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _6458, 5.0f))) * (((_6344 / ((3.1415927410125732421875f * _6571) * _6571)) * (0.5f / max(lerp((2.0f * _6437) * _6349, _6437 + _6349, _6340), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _6437))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6437 * _6443));\n                    }\n                }\n            }\n        }\n        if (_6378.on)\n        {\n            FaLayers param_57 = _6378;\n            float3 param_58 = _6325;\n            float3 param_59 = _6267;\n            float3 param_60 = f0;\n            float param_61 = _6336;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6951);\n        }\n        else\n        {\n            float3 param_62 = _6325;\n            float3 param_63 = _6267;\n            float3 param_64 = f0;\n            float param_65 = _6336;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6951);\n        }\n        result = lit;\n    }\n    float3 _6666 = result;\n    float3 _6667 = _6666 + _6952;\n    result = _6667;\n    float3 param_66 = _6667;\n    float3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6676 = _560_fa_fog.w > 0.0f;\n    bool _6683;\n    if (!_6676)\n    {\n        _6683 = _560_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _6683 = _6676;\n    }\n    if (_6683)\n    {\n        float3 _6692 = fa_world_pos - _560_fa_camera_pos.xyz;\n        float _6698 = dot(_6692, _560_fa_fog_c.xyz);\n        bool _6702 = _560_fa_fog_c.w > 0.5f;\n        float _6703;\n        if (_6702)\n        {\n            _6703 = _6698;\n        }\n        else\n        {\n            _6703 = length(_6692);\n        }\n        float _6715 = _6703 - _560_fa_fog_b.x;\n        if (_6715 > 0.0f)\n        {\n            float _6724 = _560_fa_fog.w * _6715;\n            float tau = _6724 * _6724;\n            if (_560_fa_fog_b.y > 0.0f)\n            {\n                float _6740;\n                if (_6702)\n                {\n                    _6740 = fa_world_pos.y - (_560_fa_fog_c.y * _6698);\n                }\n                else\n                {\n                    _6740 = _560_fa_camera_pos.y;\n                }\n                float _6761 = lerp(_6740, fa_world_pos.y, clamp(_560_fa_fog_b.x / _6703, 0.0f, 1.0f));\n                float _6765 = fa_world_pos.y - _6761;\n                float _6770 = _6761 - _560_fa_fog_b.z;\n                float _6775 = fa_world_pos.y - _560_fa_fog_b.z;\n                bool _6778 = _6770 <= 0.0f;\n                bool _6779 = !_6778;\n                bool _6785;\n                if (_6779)\n                {\n                    _6785 = _560_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6785 = _6778;\n                }\n                float _6786;\n                if (_6785)\n                {\n                    _6786 = _560_fa_fog_b.y;\n                }\n                else\n                {\n                    _6786 = _560_fa_fog_b.y * exp(-min(_560_fa_fog_b.w * _6770, 80.0f));\n                }\n                bool _6813;\n                if (_6779)\n                {\n                    _6813 = _560_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6813 = _6778;\n                }\n                float _6814;\n                if (_6813)\n                {\n                    _6814 = _560_fa_fog_b.y * _6770;\n                }\n                else\n                {\n                    _6814 = (_560_fa_fog_b.y * (1.0f - exp(-min(_560_fa_fog_b.w * _6770, 80.0f)))) / _560_fa_fog_b.w;\n                }\n                bool _6839 = _6775 <= 0.0f;\n                bool _6846;\n                if (!_6839)\n                {\n                    _6846 = _560_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _6846 = _6839;\n                }\n                float _6847;\n                if (_6846)\n                {\n                    _6847 = _560_fa_fog_b.y * _6775;\n                }\n                else\n                {\n                    _6847 = (_560_fa_fog_b.y * (1.0f - exp(-min(_560_fa_fog_b.w * _6775, 80.0f)))) / _560_fa_fog_b.w;\n                }\n                float _6874;\n                if (abs(_6765) < 0.001000000047497451305389404296875f)\n                {\n                    _6874 = _6786;\n                }\n                else\n                {\n                    _6874 = (_6847 - _6814) / _6765;\n                }\n                tau += (_6715 * max(_6874, 0.0f));\n            }\n            result = lerp(result, _560_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6947);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_560",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2227",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_6303",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
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
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 9
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
              "hlsl_register_t_n": 10
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
              "hlsl_register_t_n": 11
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
              "hlsl_register_t_n": 12
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 12,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _301 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _301;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _308 = _160.world_pos;\n    float4 _171 = float4(_308, 1.0f);\n    fa_world_pos = _308;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _227_fa_camera_pos : packoffset(c0);\n    float4 _227_fa_ambient : packoffset(c1);\n    float4 _227_fa_base_color : packoffset(c2);\n    float4 _227_fa_emissive : packoffset(c3);\n    float4 _227_fa_model_emissive : packoffset(c4);\n    float4 _227_fa_pbr : packoffset(c5);\n    float4 _227_fa_maps : packoffset(c6);\n    float4 _227_fa_fog : packoffset(c7);\n    float4 _227_fa_fog_b : packoffset(c8);\n    float4 _227_fa_fog_c : packoffset(c9);\n    float4 _227_fa_counts : packoffset(c10);\n    float4 _227_fa_env_sky : packoffset(c11);\n    float4 _227_fa_env_horizon : packoffset(c12);\n    float4 _227_fa_time : packoffset(c13);\n    float4 _227_fa_cl_vpx : packoffset(c14);\n    float4 _227_fa_cl_vpy : packoffset(c15);\n    float4 _227_fa_cl_vpw : packoffset(c16);\n    float4 _227_fa_cl_fwd : packoffset(c17);\n    float4 _227_fa_cl_grid : packoffset(c18);\n    float4 _227_fa_cl_info : packoffset(c19);\n    float4 _227_fa_layers_a : packoffset(c20);\n    float4 _227_fa_layers_b : packoffset(c21);\n    float4 _227_fa_layers_c : packoffset(c22);\n    float4 _227_fa_layers_d : packoffset(c23);\n    float4 _227_fa_ct_a : packoffset(c24);\n    float4 _227_fa_ct_b : packoffset(c25);\n    float4 _227_fa_ct_vpx : packoffset(c26);\n    float4 _227_fa_ct_vpy : packoffset(c27);\n    float4 _227_fa_ct_vpw : packoffset(c28);\n    float4 _227_fa_ct_fwd : packoffset(c29);\n    float4 _227_fa_probe_sh[9] : packoffset(c30);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _548_alphaCutoff : packoffset(c0);\n    float _548_fa_pad0 : packoffset(c0.y);\n    float _548_fa_pad1 : packoffset(c0.z);\n    float _548_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _227_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _239 = fa_tex_fix(param_2, param_3);\n    float4 _759 = base_t;\n    _759.x = _239.x;\n    _759.y = _239.y;\n    _759.z = _239.z;\n    base_t = _759;\n    float4 _255 = (_759 * _227_fa_base_color) * i.vertex_color;\n    float3 _722 = i.world_normal;\n    if (_227_fa_maps.z > 0.5f)\n    {\n        float param_4 = _227_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _292 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _297 = _292.xy * _227_fa_maps.x;\n        float3 _767 = _292;\n        _767.x = _297.x;\n        _767.y = _297.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _767;\n        _722 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _227_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _326 = fa_tex_fix(param_12, param_13);\n    float4 _770 = mrt;\n    _770.x = _326.x;\n    _770.y = _326.y;\n    _770.z = _326.z;\n    mrt = _770;\n    float4 _356 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _227_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _227_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _727 = _227_fa_layers_a.x;\n    float _728 = _227_fa_layers_a.y;\n    float _731 = _227_fa_layers_a.z;\n    float _730 = _227_fa_layers_b.w;\n    float _733 = _227_fa_layers_c.x;\n    if (_227_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_227_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _727 *= _368.y;\n            _728 *= _368.z;\n            _730 *= _356.w;\n        }\n        if (_227_fa_layers_c.z > 1.5f)\n        {\n            _731 *= mrt.x;\n            _733 *= mrt.w;\n        }\n    }\n    Surface _752 = { _255.xyz, _255.w, _722, clamp(_227_fa_pbr.x * _326.z, 0.0f, 1.0f), clamp(_227_fa_pbr.y * _326.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_227_fa_maps.y * (_368.x - 1.0f)), _227_fa_emissive.xyz + (_227_fa_model_emissive.xyz * _398), _727, _728, _227_fa_layers_b.xyz, _730, _731, _227_fa_layers_a.w, _733, _227_fa_layers_c.y, _227_fa_layers_d.xyz };\n    return _752;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _633 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _633 = -_633;\n    }\n    float3 _532 = normalize(_227_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _646 = { fa_world_pos, _633, fa_world_tangent, fa_uv, fa_vertex_color, _532, gl_FrontFacing };\n    SurfaceInput param = _646;\n    Surface _537 = fa_standard_surface(param);\n    float3 _657 = _537.normal;\n    SurfaceInput _654 = { fa_world_pos, _633, fa_world_tangent, fa_uv, fa_vertex_color, _532, gl_FrontFacing };\n    SurfaceInput param_1 = _654;\n    Surface param_2 = _537;\n    surface(param_1, param_2);\n    _657 = param_2.normal;\n    if (param_2.alpha < _548_alphaCutoff)\n    {\n        discard;\n    }\n    float3 _558 = normalize(_657);\n    float3 _573 = normalize(float3(dot(fa_pre_r0, _558), dot(fa_pre_r1, _558), dot(fa_pre_r2, _558)));\n    float _585 = _573.z;\n    float2 e = _573.xy / ((abs(_573.x) + abs(_573.y)) + abs(_585)).xx;\n    if (_585 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_227",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_548",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _422 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _422;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _429 = _273.world_pos;\n    float4 _284 = float4(_429, 1.0f);\n    fa_world_pos = _429;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _227_fa_camera_pos : packoffset(c0);\n    float4 _227_fa_ambient : packoffset(c1);\n    float4 _227_fa_base_color : packoffset(c2);\n    float4 _227_fa_emissive : packoffset(c3);\n    float4 _227_fa_model_emissive : packoffset(c4);\n    float4 _227_fa_pbr : packoffset(c5);\n    float4 _227_fa_maps : packoffset(c6);\n    float4 _227_fa_fog : packoffset(c7);\n    float4 _227_fa_fog_b : packoffset(c8);\n    float4 _227_fa_fog_c : packoffset(c9);\n    float4 _227_fa_counts : packoffset(c10);\n    float4 _227_fa_env_sky : packoffset(c11);\n    float4 _227_fa_env_horizon : packoffset(c12);\n    float4 _227_fa_time : packoffset(c13);\n    float4 _227_fa_cl_vpx : packoffset(c14);\n    float4 _227_fa_cl_vpy : packoffset(c15);\n    float4 _227_fa_cl_vpw : packoffset(c16);\n    float4 _227_fa_cl_fwd : packoffset(c17);\n    float4 _227_fa_cl_grid : packoffset(c18);\n    float4 _227_fa_cl_info : packoffset(c19);\n    float4 _227_fa_layers_a : packoffset(c20);\n    float4 _227_fa_layers_b : packoffset(c21);\n    float4 _227_fa_layers_c : packoffset(c22);\n    float4 _227_fa_layers_d : packoffset(c23);\n    float4 _227_fa_ct_a : packoffset(c24);\n    float4 _227_fa_ct_b : packoffset(c25);\n    float4 _227_fa_ct_vpx : packoffset(c26);\n    float4 _227_fa_ct_vpy : packoffset(c27);\n    float4 _227_fa_ct_vpw : packoffset(c28);\n    float4 _227_fa_ct_fwd : packoffset(c29);\n    float4 _227_fa_probe_sh[9] : packoffset(c30);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _548_alphaCutoff : packoffset(c0);\n    float _548_fa_pad0 : packoffset(c0.y);\n    float _548_fa_pad1 : packoffset(c0.z);\n    float _548_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _227_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _239 = fa_tex_fix(param_2, param_3);\n    float4 _759 = base_t;\n    _759.x = _239.x;\n    _759.y = _239.y;\n    _759.z = _239.z;\n    base_t = _759;\n    float4 _255 = (_759 * _227_fa_base_color) * i.vertex_color;\n    float3 _722 = i.world_normal;\n    if (_227_fa_maps.z > 0.5f)\n    {\n        float param_4 = _227_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _292 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _297 = _292.xy * _227_fa_maps.x;\n        float3 _767 = _292;\n        _767.x = _297.x;\n        _767.y = _297.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _767;\n        _722 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _227_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _326 = fa_tex_fix(param_12, param_13);\n    float4 _770 = mrt;\n    _770.x = _326.x;\n    _770.y = _326.y;\n    _770.z = _326.z;\n    mrt = _770;\n    float4 _356 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _227_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _227_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _727 = _227_fa_layers_a.x;\n    float _728 = _227_fa_layers_a.y;\n    float _731 = _227_fa_layers_a.z;\n    float _730 = _227_fa_layers_b.w;\n    float _733 = _227_fa_layers_c.x;\n    if (_227_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_227_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _727 *= _368.y;\n            _728 *= _368.z;\n            _730 *= _356.w;\n        }\n        if (_227_fa_layers_c.z > 1.5f)\n        {\n            _731 *= mrt.x;\n            _733 *= mrt.w;\n        }\n    }\n    Surface _752 = { _255.xyz, _255.w, _722, clamp(_227_fa_pbr.x * _326.z, 0.0f, 1.0f), clamp(_227_fa_pbr.y * _326.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_227_fa_maps.y * (_368.x - 1.0f)), _227_fa_emissive.xyz + (_227_fa_model_emissive.xyz * _398), _727, _728, _227_fa_layers_b.xyz, _730, _731, _227_fa_layers_a.w, _733, _227_fa_layers_c.y, _227_fa_layers_d.xyz };\n    return _752;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _633 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _633 = -_633;\n    }\n    float3 _532 = normalize(_227_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _646 = { fa_world_pos, _633, fa_world_tangent, fa_uv, fa_vertex_color, _532, gl_FrontFacing };\n    SurfaceInput param = _646;\n    Surface _537 = fa_standard_surface(param);\n    float3 _657 = _537.normal;\n    SurfaceInput _654 = { fa_world_pos, _633, fa_world_tangent, fa_uv, fa_vertex_color, _532, gl_FrontFacing };\n    SurfaceInput param_1 = _654;\n    Surface param_2 = _537;\n    surface(param_1, param_2);\n    _657 = param_2.normal;\n    if (param_2.alpha < _548_alphaCutoff)\n    {\n        discard;\n    }\n    float3 _558 = normalize(_657);\n    float3 _573 = normalize(float3(dot(fa_pre_r0, _558), dot(fa_pre_r1, _558), dot(fa_pre_r2, _558)));\n    float _585 = _573.z;\n    float2 e = _573.xy / ((abs(_573.x) + abs(_573.y)) + abs(_585)).xx;\n    if (_585 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_227",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_548",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _122_fa_view_proj : packoffset(c0);\n    row_major float4x4 _122_fa_light_vp : packoffset(c4);\n    float4 _122_fa_uv_scale : packoffset(c8);\n    float4 _122_fa_time : packoffset(c9);\n    float4 _122_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _256 = { mul(float4(position, 1.0f), model).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * _122_fa_uv_scale.xy, color, position };\n    return _256;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _239 = _190.world_pos;\n    fa_world_pos = _239;\n    fa_world_normal = _190.world_normal;\n    fa_world_tangent = _190.world_tangent;\n    fa_uv = _190.uv;\n    fa_vertex_color = _190.color;\n    gl_Position = mul(float4(_239, 1.0f), _122_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _227_fa_camera_pos : packoffset(c0);\n    float4 _227_fa_ambient : packoffset(c1);\n    float4 _227_fa_base_color : packoffset(c2);\n    float4 _227_fa_emissive : packoffset(c3);\n    float4 _227_fa_model_emissive : packoffset(c4);\n    float4 _227_fa_pbr : packoffset(c5);\n    float4 _227_fa_maps : packoffset(c6);\n    float4 _227_fa_fog : packoffset(c7);\n    float4 _227_fa_fog_b : packoffset(c8);\n    float4 _227_fa_fog_c : packoffset(c9);\n    float4 _227_fa_counts : packoffset(c10);\n    float4 _227_fa_env_sky : packoffset(c11);\n    float4 _227_fa_env_horizon : packoffset(c12);\n    float4 _227_fa_time : packoffset(c13);\n    float4 _227_fa_cl_vpx : packoffset(c14);\n    float4 _227_fa_cl_vpy : packoffset(c15);\n    float4 _227_fa_cl_vpw : packoffset(c16);\n    float4 _227_fa_cl_fwd : packoffset(c17);\n    float4 _227_fa_cl_grid : packoffset(c18);\n    float4 _227_fa_cl_info : packoffset(c19);\n    float4 _227_fa_layers_a : packoffset(c20);\n    float4 _227_fa_layers_b : packoffset(c21);\n    float4 _227_fa_layers_c : packoffset(c22);\n    float4 _227_fa_layers_d : packoffset(c23);\n    float4 _227_fa_ct_a : packoffset(c24);\n    float4 _227_fa_ct_b : packoffset(c25);\n    float4 _227_fa_ct_vpx : packoffset(c26);\n    float4 _227_fa_ct_vpy : packoffset(c27);\n    float4 _227_fa_ct_vpw : packoffset(c28);\n    float4 _227_fa_ct_fwd : packoffset(c29);\n    float4 _227_fa_probe_sh[9] : packoffset(c30);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _548_alphaCutoff : packoffset(c0);\n    float _548_fa_pad0 : packoffset(c0.y);\n    float _548_fa_pad1 : packoffset(c0.z);\n    float _548_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _227_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _239 = fa_tex_fix(param_2, param_3);\n    float4 _693 = base_t;\n    _693.x = _239.x;\n    _693.y = _239.y;\n    _693.z = _239.z;\n    base_t = _693;\n    float4 _255 = (_693 * _227_fa_base_color) * i.vertex_color;\n    float3 _662 = i.world_normal;\n    if (_227_fa_maps.z > 0.5f)\n    {\n        float param_4 = _227_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _292 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _297 = _292.xy * _227_fa_maps.x;\n        float3 _701 = _292;\n        _701.x = _297.x;\n        _701.y = _297.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _701;\n        _662 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _227_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _326 = fa_tex_fix(param_12, param_13);\n    float4 _704 = mrt;\n    _704.x = _326.x;\n    _704.y = _326.y;\n    _704.z = _326.z;\n    mrt = _704;\n    float4 _356 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _227_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _227_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _667 = _227_fa_layers_a.x;\n    float _668 = _227_fa_layers_a.y;\n    float _671 = _227_fa_layers_a.z;\n    float _670 = _227_fa_layers_b.w;\n    float _673 = _227_fa_layers_c.x;\n    if (_227_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_227_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _667 *= _368.y;\n            _668 *= _368.z;\n            _670 *= _356.w;\n        }\n        if (_227_fa_layers_c.z > 1.5f)\n        {\n            _671 *= mrt.x;\n            _673 *= mrt.w;\n        }\n    }\n    Surface _692 = { _255.xyz, _255.w, _662, clamp(_227_fa_pbr.x * _326.z, 0.0f, 1.0f), clamp(_227_fa_pbr.y * _326.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_227_fa_maps.y * (_368.x - 1.0f)), _227_fa_emissive.xyz + (_227_fa_model_emissive.xyz * _398), _667, _668, _227_fa_layers_b.xyz, _670, _671, _227_fa_layers_a.w, _673, _227_fa_layers_c.y, _227_fa_layers_d.xyz };\n    return _692;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _573 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _573 = -_573;\n    }\n    float3 _532 = normalize(_227_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _586 = { fa_world_pos, _573, fa_world_tangent, fa_uv, fa_vertex_color, _532, gl_FrontFacing };\n    SurfaceInput param = _586;\n    SurfaceInput _594 = { fa_world_pos, _573, fa_world_tangent, fa_uv, fa_vertex_color, _532, gl_FrontFacing };\n    SurfaceInput param_1 = _594;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _548_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_122",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_227",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_548",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _127_fa_view_proj : packoffset(c0);\n    row_major float4x4 _127_fa_light_vp : packoffset(c4);\n    float4 _127_fa_uv_scale : packoffset(c8);\n    float4 _127_fa_time : packoffset(c9);\n    float4 _127_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _174_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _165 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_174_fa_joint_rows[_165] * weights[i]);\n        r1 += (_174_fa_joint_rows[_165 + 1] * weights[i]);\n        r2 += (_174_fa_joint_rows[_165 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _377 = { mul(float4(position, 1.0f), model).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * _127_fa_uv_scale.xy, color, position };\n    return _377;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData _311 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    float3 _360 = _311.world_pos;\n    fa_world_pos = _360;\n    fa_world_normal = _311.world_normal;\n    fa_world_tangent = _311.world_tangent;\n    fa_uv = _311.uv;\n    fa_vertex_color = _311.color;\n    gl_Position = mul(float4(_360, 1.0f), _127_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _227_fa_camera_pos : packoffset(c0);\n    float4 _227_fa_ambient : packoffset(c1);\n    float4 _227_fa_base_color : packoffset(c2);\n    float4 _227_fa_emissive : packoffset(c3);\n    float4 _227_fa_model_emissive : packoffset(c4);\n    float4 _227_fa_pbr : packoffset(c5);\n    float4 _227_fa_maps : packoffset(c6);\n    float4 _227_fa_fog : packoffset(c7);\n    float4 _227_fa_fog_b : packoffset(c8);\n    float4 _227_fa_fog_c : packoffset(c9);\n    float4 _227_fa_counts : packoffset(c10);\n    float4 _227_fa_env_sky : packoffset(c11);\n    float4 _227_fa_env_horizon : packoffset(c12);\n    float4 _227_fa_time : packoffset(c13);\n    float4 _227_fa_cl_vpx : packoffset(c14);\n    float4 _227_fa_cl_vpy : packoffset(c15);\n    float4 _227_fa_cl_vpw : packoffset(c16);\n    float4 _227_fa_cl_fwd : packoffset(c17);\n    float4 _227_fa_cl_grid : packoffset(c18);\n    float4 _227_fa_cl_info : packoffset(c19);\n    float4 _227_fa_layers_a : packoffset(c20);\n    float4 _227_fa_layers_b : packoffset(c21);\n    float4 _227_fa_layers_c : packoffset(c22);\n    float4 _227_fa_layers_d : packoffset(c23);\n    float4 _227_fa_ct_a : packoffset(c24);\n    float4 _227_fa_ct_b : packoffset(c25);\n    float4 _227_fa_ct_vpx : packoffset(c26);\n    float4 _227_fa_ct_vpy : packoffset(c27);\n    float4 _227_fa_ct_vpw : packoffset(c28);\n    float4 _227_fa_ct_fwd : packoffset(c29);\n    float4 _227_fa_probe_sh[9] : packoffset(c30);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _548_alphaCutoff : packoffset(c0);\n    float _548_fa_pad0 : packoffset(c0.y);\n    float _548_fa_pad1 : packoffset(c0.z);\n    float _548_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _227_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _239 = fa_tex_fix(param_2, param_3);\n    float4 _693 = base_t;\n    _693.x = _239.x;\n    _693.y = _239.y;\n    _693.z = _239.z;\n    base_t = _693;\n    float4 _255 = (_693 * _227_fa_base_color) * i.vertex_color;\n    float3 _662 = i.world_normal;\n    if (_227_fa_maps.z > 0.5f)\n    {\n        float param_4 = _227_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _292 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _297 = _292.xy * _227_fa_maps.x;\n        float3 _701 = _292;\n        _701.x = _297.x;\n        _701.y = _297.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _701;\n        _662 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _227_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _326 = fa_tex_fix(param_12, param_13);\n    float4 _704 = mrt;\n    _704.x = _326.x;\n    _704.y = _326.y;\n    _704.z = _326.z;\n    mrt = _704;\n    float4 _356 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _227_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _227_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _667 = _227_fa_layers_a.x;\n    float _668 = _227_fa_layers_a.y;\n    float _671 = _227_fa_layers_a.z;\n    float _670 = _227_fa_layers_b.w;\n    float _673 = _227_fa_layers_c.x;\n    if (_227_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_227_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _667 *= _368.y;\n            _668 *= _368.z;\n            _670 *= _356.w;\n        }\n        if (_227_fa_layers_c.z > 1.5f)\n        {\n            _671 *= mrt.x;\n            _673 *= mrt.w;\n        }\n    }\n    Surface _692 = { _255.xyz, _255.w, _662, clamp(_227_fa_pbr.x * _326.z, 0.0f, 1.0f), clamp(_227_fa_pbr.y * _326.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_227_fa_maps.y * (_368.x - 1.0f)), _227_fa_emissive.xyz + (_227_fa_model_emissive.xyz * _398), _667, _668, _227_fa_layers_b.xyz, _670, _671, _227_fa_layers_a.w, _673, _227_fa_layers_c.y, _227_fa_layers_d.xyz };\n    return _692;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _573 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _573 = -_573;\n    }\n    float3 _532 = normalize(_227_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _586 = { fa_world_pos, _573, fa_world_tangent, fa_uv, fa_vertex_color, _532, gl_FrontFacing };\n    SurfaceInput param = _586;\n    SurfaceInput _594 = { fa_world_pos, _573, fa_world_tangent, fa_uv, fa_vertex_color, _532, gl_FrontFacing };\n    SurfaceInput param_1 = _594;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _548_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_127",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_174",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_227",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_548",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    }
  }
}
