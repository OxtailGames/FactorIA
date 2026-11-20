{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "bccfdbb53ee48b05b8dde63187158cf27ea0b93537445c8a05fdc4dbc713dc01",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "vertexAttributes": [
    "color1",
    "uv1"
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _144_fa_view_proj : packoffset(c0);\n    row_major float4x4 _144_fa_light_vp : packoffset(c4);\n    float4 _144_fa_uv_scale : packoffset(c8);\n    float4 _144_fa_time : packoffset(c9);\n    float4 _144_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float2 fa_attr_uv1 : TEXCOORD9;\n    float4 fa_attr_color1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _296 = { mul(float4(position, 1.0f), model).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _144_fa_uv_scale.xy, color, position };\n    return _296;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _144_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = float3((fa_attr_uv1 * _144_fa_lm_so.xy) + _144_fa_lm_so.zw, float(_144_fa_lm_so.x > 0.0f));\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _2582[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _536_fa_camera_pos : packoffset(c0);\n    float4 _536_fa_ambient : packoffset(c1);\n    float4 _536_fa_base_color : packoffset(c2);\n    float4 _536_fa_emissive : packoffset(c3);\n    float4 _536_fa_model_emissive : packoffset(c4);\n    float4 _536_fa_pbr : packoffset(c5);\n    float4 _536_fa_maps : packoffset(c6);\n    float4 _536_fa_fog : packoffset(c7);\n    float4 _536_fa_fog_b : packoffset(c8);\n    float4 _536_fa_fog_c : packoffset(c9);\n    float4 _536_fa_counts : packoffset(c10);\n    float4 _536_fa_env_sky : packoffset(c11);\n    float4 _536_fa_env_horizon : packoffset(c12);\n    float4 _536_fa_time : packoffset(c13);\n    float4 _536_fa_cl_vpx : packoffset(c14);\n    float4 _536_fa_cl_vpy : packoffset(c15);\n    float4 _536_fa_cl_vpw : packoffset(c16);\n    float4 _536_fa_cl_fwd : packoffset(c17);\n    float4 _536_fa_cl_grid : packoffset(c18);\n    float4 _536_fa_cl_info : packoffset(c19);\n    float4 _536_fa_layers_a : packoffset(c20);\n    float4 _536_fa_layers_b : packoffset(c21);\n    float4 _536_fa_layers_c : packoffset(c22);\n    float4 _536_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1276_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1276_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1276_fa_shadow_info[4] : packoffset(c20);\n    float4 _1276_fa_shadow_split : packoffset(c24);\n    float4 _1276_fa_shadow_cfg : packoffset(c25);\n    float4 _1276_fa_shadow_bias : packoffset(c26);\n    float4 _1276_fa_shadow_eye : packoffset(c27);\n    float4 _1276_fa_shadow_fwd : packoffset(c28);\n    float4 _1276_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t10);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _541 = _536_fa_cl_info.x < 0.0f;\n    bool _548;\n    if (!_541)\n    {\n        _548 = _536_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _548 = _541;\n    }\n    bool _556;\n    if (!_548)\n    {\n        _556 = _536_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _556 = _548;\n    }\n    bool _563;\n    if (!_556)\n    {\n        _563 = _536_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _563 = _556;\n    }\n    bool _570;\n    if (!_563)\n    {\n        _570 = _536_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _570 = _563;\n    }\n    if (_570)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _580 = float4(world_pos, 1.0f);\n    float _587 = dot(_536_fa_cl_vpw, _580);\n    if (!(_587 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _609 = float2(dot(_536_fa_cl_vpx, _580), dot(_536_fa_cl_vpy, _580)) / _587.xx;\n    int _613 = int(_536_fa_cl_grid.x);\n    int _617 = int(_536_fa_cl_grid.y);\n    int param = (int(_536_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_536_fa_cl_fwd.xyz, world_pos) + _536_fa_cl_fwd.w, _536_fa_cl_grid.w) / _536_fa_cl_grid.w) * _536_fa_cl_grid.z)), 0, int(_536_fa_cl_info.y) - 1) * _617) + clamp(int(floor(((_609.y * 0.5f) + 0.5f) * _536_fa_cl_grid.y)), 0, _617 - 1)) * _613)) + clamp(int(floor(((_609.x * 0.5f) + 0.5f) * _536_fa_cl_grid.x)), 0, _613 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _693 = fa_cluster_texel(param);\n    return int2(int(_693.x), int(_693.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_536_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3397 = fa_cluster_lookup(param);\n    fa_cl_slot = _3397.x;\n    fa_cl_local = _3397.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3553 = fa_linear_to_srgb(param);\n        c = _3553;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3561 = fa_srgb_to_linear(param_1);\n            c = _3561;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _291;\n    if (i.front_facing)\n    {\n        _291 = i.world_normal;\n    }\n    else\n    {\n        _291 = -i.world_normal;\n    }\n    float3 _315 = normalize(i.world_tangent.xyz - (_291 * dot(_291, i.world_tangent.xyz)));\n    float3 _343 = normalize(((_315 * m.x) + ((cross(_291, _315) * i.world_tangent.w) * m.y)) + (_291 * m.z));\n    float3 _346;\n    if (i.front_facing)\n    {\n        _346 = _343;\n    }\n    else\n    {\n        _346 = -_343;\n    }\n    return _346;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _536_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3592 = fa_tex_fix(param_2, param_3);\n    float4 _4891 = base_t;\n    _4891.x = _3592.x;\n    _4891.y = _3592.y;\n    _4891.z = _3592.z;\n    base_t = _4891;\n    float4 _3606 = (_4891 * _536_fa_base_color) * i.vertex_color;\n    float3 _4758 = i.world_normal;\n    if (_536_fa_maps.z > 0.5f)\n    {\n        float param_4 = _536_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3638 = fa_tex_fix(param_6, param_7);\n        float3 _3641 = (_3638 * 2.0f) - 1.0f.xxx;\n        float2 _3646 = _3641.xy * _536_fa_maps.x;\n        float3 _4899 = _3641;\n        _4899.x = _3646.x;\n        _4899.y = _3646.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4899;\n        _4758 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _536_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3675 = fa_tex_fix(param_12, param_13);\n    float4 _4902 = mrt;\n    _4902.x = _3675.x;\n    _4902.y = _3675.y;\n    _4902.z = _3675.z;\n    mrt = _4902;\n    float4 _3703 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _536_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3703.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3715 = fa_tex_fix(param_16, param_17);\n    float param_18 = _536_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3745 = fa_tex_fix(param_20, param_21);\n    float _4763 = _536_fa_layers_a.x;\n    float _4764 = _536_fa_layers_a.y;\n    float _4767 = _536_fa_layers_a.z;\n    float _4766 = _536_fa_layers_b.w;\n    float _4769 = _536_fa_layers_c.x;\n    if (_536_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_536_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4763 *= _3715.y;\n            _4764 *= _3715.z;\n            _4766 *= _3703.w;\n        }\n        if (_536_fa_layers_c.z > 1.5f)\n        {\n            _4767 *= mrt.x;\n            _4769 *= mrt.w;\n        }\n    }\n    Surface _4788 = { _3606.xyz, _3606.w, _4758, clamp(_536_fa_pbr.x * _3675.z, 0.0f, 1.0f), clamp(_536_fa_pbr.y * _3675.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_536_fa_maps.y * (_3715.x - 1.0f)), _536_fa_emissive.xyz + (_536_fa_model_emissive.xyz * _3745), _4763, _4764, _536_fa_layers_b.xyz, _4766, _4767, _536_fa_layers_a.w, _4769, _536_fa_layers_c.y, _536_fa_layers_d.xyz };\n    return _4788;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0f));\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _774 = rect.zw - rect.xy;\n    float2 _778 = _774 * atlas;\n    float2 _782 = ddx * _778;\n    float2 _786 = ddy * _778;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _774), clamp(0.5f * log2(max(max(dot(_782, _782), dot(_786, _786)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _821 = _536_fa_counts.y < 0.5f;\n    bool _828;\n    if (!_821)\n    {\n        _828 = _536_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _828 = _821;\n    }\n    if (_828)\n    {\n        return;\n    }\n    float3 _834 = ddx(world_pos);\n    float3 _837 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _841 = fa_cluster_texel(param);\n    int _845 = int(_841.w);\n    if (_845 < 1)\n    {\n        return;\n    }\n    int _855 = int(_536_fa_counts.y + 0.5f);\n    int param_1 = _855;\n    float4 _859 = fa_light_texel(param_1);\n    float2 _862 = _859.yz;\n    int _866 = int(_859.w);\n    int param_2 = _855 + 1;\n    float4 _871 = fa_light_texel(param_2);\n    float _872 = _871.x;\n    int _878 = int(_536_fa_counts.w + 0.5f) - 1;\n    int _882 = int(_841.z);\n    float3 _1148;\n    for (int k = 0; k < _845; k++)\n    {\n        int _895 = _882 + k;\n        int param_3 = _866 + (_895 >> 2);\n        int _913 = (_855 + 2) + (int(fa_light_texel(param_3)[_895 & 3]) * 7);\n        int param_4 = _913 + 6;\n        float4 _918 = fa_light_texel(param_4);\n        if (((int(_918.w + 0.5f) >> _878) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _913;\n        float4 _933 = fa_light_texel(param_5);\n        int param_6 = _913 + 1;\n        float4 _938 = fa_light_texel(param_6);\n        int param_7 = _913 + 2;\n        float4 _943 = fa_light_texel(param_7);\n        float3 _946 = _933.xyz;\n        float _951 = dot(_946, world_pos) + _933.w;\n        float3 _953 = _938.xyz;\n        float _958 = dot(_953, world_pos) + _938.w;\n        float3 _960 = _943.xyz;\n        float _965 = dot(_960, world_pos) + _943.w;\n        bool _970 = abs(_951) > 0.5f;\n        bool _978;\n        if (!_970)\n        {\n            _978 = abs(_958) > 0.5f;\n        }\n        else\n        {\n            _978 = _970;\n        }\n        bool _986;\n        if (!_978)\n        {\n            _986 = abs(_965) > 0.5f;\n        }\n        else\n        {\n            _986 = _978;\n        }\n        if (_986)\n        {\n            continue;\n        }\n        float _1001 = clamp(dot(geo_normal, normalize(_960)) * _918.z, 0.0f, 1.0f);\n        if (_1001 <= 0.0f)\n        {\n            continue;\n        }\n        float _1021 = (clamp((0.5f - abs(_965)) * 10.0f, 0.0f, 1.0f) * _1001) * _918.x;\n        float2 _1029 = float2(_951 + 0.5f, 0.5f - _958);\n        float2 _1039 = float2(dot(_946, _834), dot(_953, _834));\n        float2 _1049 = float2(dot(_946, _837), dot(_953, _837));\n        int param_8 = _913 + 5;\n        float4 _1054 = fa_light_texel(param_8);\n        int param_9 = _913 + 3;\n        float4 _1059 = fa_light_texel(param_9);\n        int param_10 = _913 + 4;\n        float4 _1064 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1054.xyz;\n        bool _1074 = _1059.z > _1059.x;\n        if (_1074)\n        {\n            float4 param_11 = _1059;\n            float2 param_12 = _1029;\n            float2 param_13 = _862;\n            float2 param_14 = _1039;\n            float2 param_15 = _1049;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_872 > 0.5f) && (_872 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1100 = fa_dc_to_linear(param_16);\n                float4 _4814 = tx;\n                _4814.x = _1100.x;\n                _4814.y = _1100.y;\n                _4814.z = _1100.z;\n                tx = _4814;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1021 * tex_a) * _1054.w, 0.0f, 1.0f).xxx);\n        if (_1064.z > _1064.x)\n        {\n            float4 param_17 = _1064;\n            float2 param_18 = _1029;\n            float2 param_19 = _862;\n            float2 param_20 = _1039;\n            float2 param_21 = _1049;\n            float4 _1144 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_872 > 1.5f)\n            {\n                float3 param_22 = _1144.xyz;\n                float3 _1154 = fa_dc_to_srgb(param_22);\n                _1148 = _1154;\n            }\n            else\n            {\n                _1148 = _1144.xyz;\n            }\n            float3 _1164 = (_1148 * 2.0f) - 1.0f.xxx;\n            float2 _1169 = _1164.xy * _918.y;\n            float3 _1191 = (normalize(_946) * _1169.x) + (normalize(_953) * _1169.y);\n            float3 _1194 = normalize(normal);\n            normal = normalize(lerp(_1194, normalize((_1194 * max(_1164.z, 0.0500000007450580596923828125f)) + (_1191 - (_1194 * dot(_1194, _1191)))), clamp(_1021 * (_1074 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2507 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _2515 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _2518 = int(_2507);\n    int _2521 = int(_2515);\n    float _2531 = _2515 - float(_2521);\n    int _2587 = (_2518 * 9) + _2521;\n    int _2607 = ((_2518 + 1) * 9) + _2521;\n    return lerp(lerp(_2582[_2587], _2582[_2587 + 1], _2531), lerp(_2582[_2607], _2582[_2607 + 1], _2531), _2507 - float(_2518));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4681 = false;\n    float _4682 = 1.0f;\n    float _4683 = 1.0f;\n    float _4684 = 1.0f;\n    float _4685 = 0.0f;\n    float _4686 = 0.0f;\n    float _4687 = 0.0f;\n    float _4688 = 0.0f;\n    float _4690 = 1.0f;\n    bool _4691 = false;\n    float3 _4692 = 0.0f.xxx;\n    float _4693 = 1.0f;\n    float _4694 = 1.0f;\n    float _4695 = 1.0f;\n    float _4696 = 0.0f;\n    float _4697 = 0.0f;\n    float3 _4698 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4699 = float3(0.0f, 0.0f, 1.0f);\n    float _4700 = 1.0f;\n    float _4701 = 1.0f;\n    float _2660 = clamp(s.specular, 0.0f, 1.0f);\n    float _2664 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2669 = (_2660 != 1.0f) || (_2664 != 1.5f);\n    bool _2679;\n    if (!_2669)\n    {\n        _2679 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2679 = _2669;\n    }\n    if (_2679)\n    {\n        float _2687 = (_2664 - 1.0f) / (_2664 + 1.0f);\n        f0 = lerp(min((_2687 * _2687).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2660, s.albedo, metallic.xxx);\n        _4682 = lerp(_2660, 1.0f, metallic);\n        _4681 = true;\n    }\n    float _2715 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2715 > 0.0f)\n    {\n        float _2723 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4685 = _2715;\n        _4686 = _2723;\n        float _2730 = _2723 * _2723;\n        _4687 = _2730;\n        _4688 = _2730 * _2730;\n        float _2742 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4690 = _2742;\n        _4683 = 1.0f - (_2715 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2742, 0.0f, 1.0f), 5.0f))));\n        _4681 = true;\n    }\n    float3 _2762 = max(s.sheen_color, 0.0f.xxx);\n    float _2771 = max(_2762.x, max(_2762.y, _2762.z));\n    if (_2771 > 0.0f)\n    {\n        float _2779 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4691 = true;\n        _4692 = _2762;\n        _4693 = _2779;\n        _4694 = _2779 * _2779;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2779;\n        float _2796 = fa_sheen_albedo(param, param_1);\n        _4696 = _2796;\n        _4695 = 1.0f - min(_2771 * _2796, 1.0f);\n        _4681 = true;\n    }\n    _4684 = _4683 * _4695;\n    float _2815 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2815 != 0.0f)\n    {\n        float3 _2830 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2830;\n        if (dot(_2830, _2830) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2843 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2843.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2843.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2843.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2847 = t;\n        float3 _2848 = normalize(_2847);\n        t = _2848;\n        float3 _2873 = normalize((_2848 * cos(s.anisotropy_rotation)) + ((cross(n, _2848) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4698 = _2873;\n        _4699 = cross(n, _2873);\n        float _2883 = roughness * roughness;\n        float _2889 = lerp(_2883, 1.0f, _2815 * _2815);\n        bool _2891 = _2815 > 0.0f;\n        _4700 = _2891 ? _2889 : _2883;\n        _4701 = _2891 ? _2883 : _2889;\n        _4697 = _2815;\n        _4681 = true;\n    }\n    FaLayers _4723 = { _4681, _4682, _4683, _4684, _4685, _4686, _4687, _4688, i.world_normal, _4690, _4691, _4692, _4693, _4694, _4695, _4696, _4697, _4698, _4699, _4700, _4701 };\n    return _4723;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_536_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _536_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_536_fa_cl_info.x) + int(_536_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _410 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _416 = fa_light_texel(param_1);\n    float _419 = _416.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _425 = _419 < 0.5f;\n    float3 l;\n    if (_425)\n    {\n        l = normalize(_410.xyz);\n    }\n    else\n    {\n        float3 _437 = _410.xyz - world_pos;\n        float _439 = length(_437);\n        dist = _439;\n        l = _437 / max(_439, 9.9999997473787516355514526367188e-05f).xxx;\n        float _454 = _439 / max(_410.w, 0.001000000047497451305389404296875f);\n        float _460 = clamp(1.0f - (_454 * _454), 0.0f, 1.0f);\n        atten = _460 * _460;\n        if (_419 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _474 = fa_light_texel(param_2);\n            float _484 = _474.w;\n            int param_3 = (li * 4) + 3;\n            float4 _490 = fa_light_texel(param_3);\n            float _491 = _490.x;\n            float cos_inner = _491;\n            if (_491 > 1.5f)\n            {\n                cos_inner = lerp(_484, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_484, cos_inner, dot(-l, normalize(_474.xyz)));\n        }\n    }\n    int _522;\n    if (_425)\n    {\n        _522 = 0;\n    }\n    else\n    {\n        _522 = (_419 > 1.5f) ? 2 : 1;\n    }\n    LightSample _4680 = { l, _416.xyz * atten, atten, 1.0f, dist, _522 };\n    return _4680;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1266;\n    if (i == 0)\n    {\n        _1266 = _1276_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1282;\n        if (i == 1)\n        {\n            _1282 = _1276_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1290;\n            if (i == 2)\n            {\n                _1290 = _1276_fa_shadow_split.z;\n            }\n            else\n            {\n                _1290 = _1276_fa_shadow_split.w;\n            }\n            _1282 = _1290;\n        }\n        _1266 = _1282;\n    }\n    return _1266;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1323 = fa_shadow_depth(param, param_1);\n    float _1327;\n    if (conv.x < 0.5f)\n    {\n        _1327 = _1323;\n    }\n    else\n    {\n        _1327 = (conv.y * conv.z) / (conv.z - (_1323 * (conv.z - conv.y)));\n    }\n    return _1327;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1254 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1254), sin(_1254)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1373 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1387 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1373;\n            float2 _1406 = fa_shadow_vogel(param_3, param_4, param_5) * _1387;\n            float2 param_6 = uv + (_1406 * _1276_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1418 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1418 < (zr - (length(_1406) * plane)))\n            {\n                sum += _1418;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1462 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1462; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1462;\n        float param_11 = _1373;\n        float2 _1481 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1481 * _1276_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1481) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1462);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1523 = max(_1276_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1528 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1534 = sqrt(1.0f - (_1528 * _1528));\n    float _1541 = min(_1534 / max(_1528, 0.20000000298023223876953125f), 4.0f);\n    float _1546;\n    if (_1276_fa_shadow_bias.y > 0.0f)\n    {\n        _1546 = _1276_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1546 = 1.5f * _1276_fa_shadow_info[ci].x;\n    }\n    float4 _1571 = mul(float4(world + (n * (_1546 * _1534)), 1.0f), _1276_fa_shadow_mat[ci]);\n    float _1578 = _1571.x;\n    bool _1581 = _1578 < _1276_fa_shadow_rect[ci].x;\n    bool _1590;\n    if (!_1581)\n    {\n        _1590 = _1578 > _1276_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1590 = _1581;\n    }\n    bool _1599;\n    if (!_1590)\n    {\n        _1599 = _1571.y < _1276_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1599 = _1590;\n    }\n    bool _1608;\n    if (!_1599)\n    {\n        _1608 = _1571.y > _1276_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1608 = _1599;\n    }\n    bool _1615;\n    if (!_1608)\n    {\n        _1615 = _1571.z > 1.0f;\n    }\n    else\n    {\n        _1615 = _1608;\n    }\n    if (_1615)\n    {\n        return -1.0f;\n    }\n    float _1624;\n    if (_1276_fa_shadow_bias.x > 0.0f)\n    {\n        _1624 = _1276_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1624 = 1.5f * _1276_fa_shadow_info[ci].x;\n    }\n    float2 param = _1571.xy;\n    float4 param_1 = _1276_fa_shadow_rect[ci];\n    float param_2 = _1571.z - ((_1624 * (1.0f + (0.5f * _1541))) / _1523);\n    float param_3 = _1276_fa_shadow_info[ci].x;\n    float param_4 = _1523;\n    float param_5 = _1523 * 0.25f;\n    float param_6 = ((_1276_fa_shadow_info[ci].x * min(_1541, 3.0f)) * 0.5f) / _1523;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1276_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1276_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_536_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2051 = int(_1276_fa_shadow_cfg.x + 0.5f);\n    if (_2051 < 1)\n    {\n        return 1.0f;\n    }\n    float _2066 = dot(world - _1276_fa_shadow_eye.xyz, _1276_fa_shadow_fwd.xyz);\n    int param = _2051 - 1;\n    if (_2066 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2078 = _2051 > 1;\n    bool _2085;\n    if (_2078)\n    {\n        _2085 = _2066 > _1276_fa_shadow_split.x;\n    }\n    else\n    {\n        _2085 = _2078;\n    }\n    if (_2085)\n    {\n        ci = 1;\n    }\n    bool _2089 = _2051 > 2;\n    bool _2096;\n    if (_2089)\n    {\n        _2096 = _2066 > _1276_fa_shadow_split.y;\n    }\n    else\n    {\n        _2096 = _2089;\n    }\n    if (_2096)\n    {\n        ci = 2;\n    }\n    bool _2100 = _2051 > 3;\n    bool _2107;\n    if (_2100)\n    {\n        _2107 = _2066 > _1276_fa_shadow_split.z;\n    }\n    else\n    {\n        _2107 = _2100;\n    }\n    if (_2107)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2051)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2133 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2133;\n        if (_2133 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1276_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2158;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2158 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2158 = _1276_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2177 = _1276_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2158, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2188 = clamp((_2066 - (fa_shadow_split_at(param_7) - _2177)) / _2177, 0.0f, 1.0f);\n        if (_2188 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2051)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2209 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2209;\n                if (_2209 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2188);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1682 = _536_fa_pbr.z < 0.5f;\n    bool _1690;\n    if (!_1682)\n    {\n        _1690 = _1276_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1690 = _1682;\n    }\n    if (_1690)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1276_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1703 = fa_light_texel(param);\n    float _1704 = _1703.x;\n    if (_1704 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1713 = int(_1704 + 0.5f);\n    int param_1 = _1713;\n    float4 _1717 = fa_light_texel(param_1);\n    int param_2 = _1713 + 1;\n    float4 _1722 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1725 = _1717.y;\n    if (_1725 > 0.0f)\n    {\n        float _1742 = 1.0f - smoothstep(0.75f * _1725, _1725, length(world - _1276_fa_shadow_eye.xyz));\n        fade = _1742;\n        if (_1742 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1717.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1761 = world - fa_light_texel(param_3).xyz;\n        float3 _1764 = abs(_1761);\n        float _1766 = _1764.x;\n        float _1768 = _1764.y;\n        bool _1769 = _1766 >= _1768;\n        bool _1777;\n        if (_1769)\n        {\n            _1777 = _1766 >= _1764.z;\n        }\n        else\n        {\n            _1777 = _1769;\n        }\n        int _1778;\n        if (_1777)\n        {\n            _1778 = (_1761.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1791;\n            if (_1768 >= _1764.z)\n            {\n                _1791 = (_1761.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1791 = (_1761.z > 0.0f) ? 4 : 5;\n            }\n            _1778 = _1791;\n        }\n        face = _1778;\n    }\n    int _1810 = (_1713 + 2) + (face * 6);\n    int param_4 = _1810;\n    int param_5 = _1810 + 1;\n    int param_6 = _1810 + 3;\n    float4 _1824 = fa_light_texel(param_6);\n    int param_7 = _1810 + 4;\n    float4 _1829 = fa_light_texel(param_7);\n    int param_8 = _1810 + 5;\n    float4 _1834 = fa_light_texel(param_8);\n    float _1846 = _1834.x * max(dot(_1824, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1851 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1874 = clamp(dot(n, _1824.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1897 = min(sqrt(1.0f - (_1874 * _1874)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1824, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1900 = _1722.y;\n    float _1902;\n    if (_1900 > 0.0f)\n    {\n        _1902 = _1900;\n    }\n    else\n    {\n        _1902 = 1.5f * _1846;\n    }\n    float4 _1922 = float4(world + (n * (_1902 * sqrt(1.0f - (_1851 * _1851)))), 1.0f);\n    float _1926 = dot(_1824, _1922);\n    float _1929 = _1834.y;\n    if (_1926 < _1929)\n    {\n        return 1.0f;\n    }\n    float2 _1944 = float2(dot(fa_light_texel(param_4), _1922), dot(fa_light_texel(param_5), _1922)) / _1926.xx;\n    float _1946 = _1944.x;\n    bool _1949 = _1946 < _1829.x;\n    bool _1958;\n    if (!_1949)\n    {\n        _1958 = _1946 > _1829.z;\n    }\n    else\n    {\n        _1958 = _1949;\n    }\n    bool _1967;\n    if (!_1958)\n    {\n        _1967 = _1944.y < _1829.y;\n    }\n    else\n    {\n        _1967 = _1958;\n    }\n    bool _1976;\n    if (!_1967)\n    {\n        _1976 = _1944.y > _1829.w;\n    }\n    else\n    {\n        _1976 = _1967;\n    }\n    if (_1976)\n    {\n        return 1.0f;\n    }\n    float _1982 = _1722.x;\n    float _1984;\n    if (_1982 > 0.0f)\n    {\n        _1984 = _1982;\n    }\n    else\n    {\n        _1984 = 1.5f * _1846;\n    }\n    float2 param_10 = _1944;\n    float4 param_11 = _1829;\n    float param_12 = _1926 - (_1984 * (1.0f + (0.5f * _1897)));\n    float param_13 = _1846;\n    float param_14 = 1.0f;\n    float param_15 = _1834.z * 0.25f;\n    float param_16 = (_1846 * min(_1897, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1929, _1834.z);\n    int param_18 = int(_1717.z + 0.5f);\n    float param_19 = _1717.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3424 = fa_lm.z > 0.5f;\n    bool _3430;\n    if (_3424)\n    {\n        int param = li;\n        _3430 = fa_light_baked(param);\n    }\n    else\n    {\n        _3430 = _3424;\n    }\n    if (_3430)\n    {\n        int param_1 = li;\n        LightSample _4736 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4736;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3452 = fa_light_sample(param_2, param_3);\n    float3 _4743 = _3452.direction;\n    float3 _4738 = _3452.color;\n    float _4745 = _3452.attenuation;\n    float _4740 = _3452.shadow;\n    int _4748 = _3452.type;\n    if ((_4748 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4743;\n        float _3466 = fa_shadow_factor(param_4, param_5);\n        _4740 = _3466;\n        _4738 *= _3466;\n    }\n    else\n    {\n        bool _3477 = _4748 != 0;\n        bool _3483;\n        if (_3477)\n        {\n            _3483 = _4745 > 0.0f;\n        }\n        else\n        {\n            _3483 = _3477;\n        }\n        if (_3483)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4743;\n            float _3495 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4740 = _3495;\n            _4738 *= _3495;\n        }\n    }\n    LightSample _4755 = { _4743, _4738, _4745, _4740, _3452._distance, _4748 };\n    return _4755;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3041 = tdh / at;\n    float _3045 = bdh / ab;\n    float _3057 = ((_3041 * _3041) + (_3045 * _3045)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _3057) * _3057);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _3138 = 1.0f / alpha;\n    return ((2.0f + _3138) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _3138)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _3170 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3249 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _3249) * _3249);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _3170);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _3170));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _3322 = max(dot(L.nc, l), 0.0f);\n        float _3328 = max(dot(L.nc, h), 0.0f);\n        float _3337 = ((_3328 * _3328) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _3337) * _3337)) * (0.5f / max(lerp((2.0f * _3322) * L.coat_ndv, _3322 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _3322)) * _3322).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _2439 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _2442 = _2439.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_2442 * _2442, exp2((-9.27999973297119140625f) * ndv)) * _2442) + _2439.y)) + _2439.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_536_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _536_fa_env_horizon.w).xyz;\n    }\n    float _2345 = rough * rough;\n    float _2375 = 0.60000002384185791015625f * _2345;\n    return lerp(lerp(_536_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_536_fa_env_horizon.xyz, _536_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _2345)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _2375, 0.0500000007450580596923828125f + _2375, d.y).xxx), ((_536_fa_env_sky.xyz + _536_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_2345 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2924;\n        if (L.aniso >= 0.0f)\n        {\n            _2924 = L.b;\n        }\n        else\n        {\n            _2924 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2924, v), _2924), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2957 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2957.x) + (L.f90.xxx * _2957.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3012 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3012.x) + _3012.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2481 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2481.x) + _2481.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1276_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2233 = int(_1276_fa_shadow_cfg.x + 0.5f);\n    float _2243 = dot(world - _1276_fa_shadow_eye.xyz, _1276_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2248 = _2233 > 0;\n    bool _2257;\n    if (_2248)\n    {\n        int param = _2233 - 1;\n        _2257 = _2243 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2257 = _2248;\n    }\n    if (_2257)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2264 = _2233 > 1;\n        bool _2271;\n        if (_2264)\n        {\n            _2271 = _2243 > _1276_fa_shadow_split.x;\n        }\n        else\n        {\n            _2271 = _2264;\n        }\n        if (_2271)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2277 = _2233 > 2;\n        bool _2284;\n        if (_2277)\n        {\n            _2284 = _2243 > _1276_fa_shadow_split.y;\n        }\n        else\n        {\n            _2284 = _2277;\n        }\n        if (_2284)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2290 = _2233 > 3;\n        bool _2297;\n        if (_2290)\n        {\n            _2297 = _2243 > _1276_fa_shadow_split.z;\n        }\n        else\n        {\n            _2297 = _2290;\n        }\n        if (_2297)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4460 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4460 = -_4460;\n    }\n    float3 _3885 = normalize(_536_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4473 = { fa_world_pos, _4460, fa_world_tangent, fa_uv, fa_vertex_color, _3885, gl_FrontFacing };\n    SurfaceInput param_1 = _4473;\n    Surface _3893 = fa_standard_surface(param_1);\n    float3 _4491 = _3893.albedo;\n    float _4492 = _3893.alpha;\n    float3 _4493 = _3893.normal;\n    float _4494 = _3893.metallic;\n    float _4495 = _3893.roughness;\n    float _4496 = _3893.occlusion;\n    float3 _4497 = _3893.emission;\n    float _4498 = _3893.clearcoat;\n    float _4499 = _3893.clearcoat_roughness;\n    float3 _4500 = _3893.sheen_color;\n    float _4501 = _3893.sheen_roughness;\n    float _4502 = _3893.anisotropy;\n    float _4503 = _3893.anisotropy_rotation;\n    float _4504 = _3893.specular;\n    float _4505 = _3893.ior;\n    float3 _4506 = _3893.specular_color;\n    SurfaceInput _4481 = { fa_world_pos, _4460, fa_world_tangent, fa_uv, fa_vertex_color, _3885, gl_FrontFacing };\n    SurfaceInput param_2 = _4481;\n    Surface param_3 = _3893;\n    surface(param_2, param_3);\n    _4491 = param_3.albedo;\n    _4492 = param_3.alpha;\n    _4493 = param_3.normal;\n    _4494 = param_3.metallic;\n    _4495 = param_3.roughness;\n    _4496 = param_3.occlusion;\n    _4497 = param_3.emission;\n    _4498 = param_3.clearcoat;\n    _4499 = param_3.clearcoat_roughness;\n    _4500 = param_3.sheen_color;\n    _4501 = param_3.sheen_roughness;\n    _4502 = param_3.anisotropy;\n    _4503 = param_3.anisotropy_rotation;\n    _4504 = param_3.specular;\n    _4505 = param_3.ior;\n    _4506 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4460;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4491 = param_6;\n    _4493 = param_7;\n    float3 result;\n    if (_536_fa_emissive.w > 0.5f)\n    {\n        result = _4491;\n    }\n    else\n    {\n        float3 _3932 = normalize(_4493);\n        float _3939 = clamp(_4494, 0.0f, 1.0f);\n        float _3943 = clamp(_4495, 0.0500000007450580596923828125f, 1.0f);\n        float _3947 = _3943 * _3943;\n        float _3951 = _3947 * _3947;\n        float _3956 = max(dot(_3932, _3885), 9.9999997473787516355514526367188e-05f);\n        float3 _3962 = _4491 * (1.0f - _3939);\n        float3 _3969 = lerp(0.039999999105930328369140625f.xxx, _4491, _3939.xxx);\n        float3 f0 = _3969;\n        SurfaceInput _4489 = { fa_world_pos, _4460, fa_world_tangent, fa_uv, fa_vertex_color, _3885, gl_FrontFacing };\n        SurfaceInput param_8 = _4489;\n        Surface _4572 = { _4491, _4492, _4493, _4494, _4495, _4496, _4497, _4498, _4499, _4500, _4501, _4502, _4503, _4504, _4505, _4506 };\n        Surface param_9 = _4572;\n        float3 param_10 = _3932;\n        float3 param_11 = _3885;\n        float param_12 = _3939;\n        float param_13 = _3943;\n        float3 param_14 = _3969;\n        FaLayers _3985 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _3932;\n        float3 lit = (fa_indirect_diffuse(param_15) * _3962) * _4496;\n        if (_3985.on)\n        {\n            lit *= _3985.base_scale;\n        }\n        int _4007 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4007; ln++)\n        {\n            int param_16 = ln;\n            int _4020 = fa_cl_light(param_16);\n            bool _4023 = fa_lm.z > 0.5f;\n            bool _4029;\n            if (_4023)\n            {\n                int param_17 = _4020;\n                _4029 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _4029 = _4023;\n            }\n            if (_4029)\n            {\n                continue;\n            }\n            int param_18 = _4020;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _4460;\n            LightSample _4041 = fa_light_shadowed(param_18, param_19, param_20);\n            float3 _4665 = _4041.direction;\n            float _4049 = max(dot(_3932, _4665), 0.0f);\n            float _4055 = _4041.attenuation * _4041.shadow;\n            float3 _4060 = normalize(_4665 + _3885);\n            float _4065 = max(dot(_3932, _4060), 0.0f);\n            float _4070 = max(dot(_3885, _4060), 0.0f);\n            if (_3985.on)\n            {\n                FaLayers param_21 = _3985;\n                float3 param_22 = _3962;\n                float3 param_23 = f0;\n                float3 param_24 = _3932;\n                float3 param_25 = _3885;\n                float3 param_26 = _4665;\n                float3 param_27 = _4060;\n                float param_28 = _4049;\n                float param_29 = _3956;\n                float param_30 = _4065;\n                float param_31 = _4070;\n                float param_32 = _3947;\n                float param_33 = _3951;\n                int param_34 = _4020;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34) * _4055));\n            }\n            else\n            {\n                float _4118 = ((_4065 * _4065) * (_3951 - 1.0f)) + 1.0f;\n                int param_35 = _4020;\n                lit += (((_3962 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _4070, 5.0f))) * (((_3951 / ((3.1415927410125732421875f * _4118) * _4118)) * (0.5f / max(lerp((2.0f * _4049) * _3956, _4049 + _3956, _3947), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4049))) * fa_light_rgb(param_35)) * (_4049 * _4055));\n            }\n        }\n        if (_3985.on)\n        {\n            FaLayers param_36 = _3985;\n            float3 param_37 = _3932;\n            float3 param_38 = _3885;\n            float3 param_39 = f0;\n            float param_40 = _3943;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40) * _4496);\n        }\n        else\n        {\n            float3 param_41 = _3932;\n            float3 param_42 = _3885;\n            float3 param_43 = f0;\n            float param_44 = _3943;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44) * _4496);\n        }\n        result = lit;\n    }\n    float3 _4211 = result;\n    float3 _4212 = _4211 + _4497;\n    result = _4212;\n    float3 param_45 = _4212;\n    float3 param_46 = fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46);\n    bool _4221 = _536_fa_fog.w > 0.0f;\n    bool _4228;\n    if (!_4221)\n    {\n        _4228 = _536_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4228 = _4221;\n    }\n    if (_4228)\n    {\n        float3 _4237 = fa_world_pos - _536_fa_camera_pos.xyz;\n        float _4243 = dot(_4237, _536_fa_fog_c.xyz);\n        bool _4247 = _536_fa_fog_c.w > 0.5f;\n        float _4248;\n        if (_4247)\n        {\n            _4248 = _4243;\n        }\n        else\n        {\n            _4248 = length(_4237);\n        }\n        float _4260 = _4248 - _536_fa_fog_b.x;\n        if (_4260 > 0.0f)\n        {\n            float _4269 = _536_fa_fog.w * _4260;\n            float tau = _4269 * _4269;\n            if (_536_fa_fog_b.y > 0.0f)\n            {\n                float _4285;\n                if (_4247)\n                {\n                    _4285 = fa_world_pos.y - (_536_fa_fog_c.y * _4243);\n                }\n                else\n                {\n                    _4285 = _536_fa_camera_pos.y;\n                }\n                float _4306 = lerp(_4285, fa_world_pos.y, clamp(_536_fa_fog_b.x / _4248, 0.0f, 1.0f));\n                float _4310 = fa_world_pos.y - _4306;\n                float _4315 = _4306 - _536_fa_fog_b.z;\n                float _4320 = fa_world_pos.y - _536_fa_fog_b.z;\n                bool _4323 = _4315 <= 0.0f;\n                bool _4324 = !_4323;\n                bool _4330;\n                if (_4324)\n                {\n                    _4330 = _536_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4330 = _4323;\n                }\n                float _4331;\n                if (_4330)\n                {\n                    _4331 = _536_fa_fog_b.y;\n                }\n                else\n                {\n                    _4331 = _536_fa_fog_b.y * exp(-min(_536_fa_fog_b.w * _4315, 80.0f));\n                }\n                bool _4358;\n                if (_4324)\n                {\n                    _4358 = _536_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4358 = _4323;\n                }\n                float _4359;\n                if (_4358)\n                {\n                    _4359 = _536_fa_fog_b.y * _4315;\n                }\n                else\n                {\n                    _4359 = (_536_fa_fog_b.y * (1.0f - exp(-min(_536_fa_fog_b.w * _4315, 80.0f)))) / _536_fa_fog_b.w;\n                }\n                bool _4384 = _4320 <= 0.0f;\n                bool _4391;\n                if (!_4384)\n                {\n                    _4391 = _536_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4391 = _4384;\n                }\n                float _4392;\n                if (_4391)\n                {\n                    _4392 = _536_fa_fog_b.y * _4320;\n                }\n                else\n                {\n                    _4392 = (_536_fa_fog_b.y * (1.0f - exp(-min(_536_fa_fog_b.w * _4320, 80.0f)))) / _536_fa_fog_b.w;\n                }\n                float _4419;\n                if (abs(_4310) < 0.001000000047497451305389404296875f)\n                {\n                    _4419 = _4331;\n                }\n                else\n                {\n                    _4419 = (_4392 - _4359) / _4310;\n                }\n                tau += (_4260 * max(_4419, 0.0f));\n            }\n            result = lerp(result, _536_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4492);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec2",
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
            "inst_name": "_144",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_536",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1276",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 9
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _149_fa_view_proj : packoffset(c0);\n    row_major float4x4 _149_fa_light_vp : packoffset(c4);\n    float4 _149_fa_uv_scale : packoffset(c8);\n    float4 _149_fa_time : packoffset(c9);\n    float4 _149_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _195_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float2 fa_attr_uv1 : TEXCOORD11;\n    float4 fa_attr_color1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _186 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_195_fa_joint_rows[_186] * weights[i]);\n        r1 += (_195_fa_joint_rows[_186 + 1] * weights[i]);\n        r2 += (_195_fa_joint_rows[_186 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _401 = { mul(float4(position, 1.0f), model).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _149_fa_uv_scale.xy, color, position };\n    return _401;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _149_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _2582[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _536_fa_camera_pos : packoffset(c0);\n    float4 _536_fa_ambient : packoffset(c1);\n    float4 _536_fa_base_color : packoffset(c2);\n    float4 _536_fa_emissive : packoffset(c3);\n    float4 _536_fa_model_emissive : packoffset(c4);\n    float4 _536_fa_pbr : packoffset(c5);\n    float4 _536_fa_maps : packoffset(c6);\n    float4 _536_fa_fog : packoffset(c7);\n    float4 _536_fa_fog_b : packoffset(c8);\n    float4 _536_fa_fog_c : packoffset(c9);\n    float4 _536_fa_counts : packoffset(c10);\n    float4 _536_fa_env_sky : packoffset(c11);\n    float4 _536_fa_env_horizon : packoffset(c12);\n    float4 _536_fa_time : packoffset(c13);\n    float4 _536_fa_cl_vpx : packoffset(c14);\n    float4 _536_fa_cl_vpy : packoffset(c15);\n    float4 _536_fa_cl_vpw : packoffset(c16);\n    float4 _536_fa_cl_fwd : packoffset(c17);\n    float4 _536_fa_cl_grid : packoffset(c18);\n    float4 _536_fa_cl_info : packoffset(c19);\n    float4 _536_fa_layers_a : packoffset(c20);\n    float4 _536_fa_layers_b : packoffset(c21);\n    float4 _536_fa_layers_c : packoffset(c22);\n    float4 _536_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1276_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1276_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1276_fa_shadow_info[4] : packoffset(c20);\n    float4 _1276_fa_shadow_split : packoffset(c24);\n    float4 _1276_fa_shadow_cfg : packoffset(c25);\n    float4 _1276_fa_shadow_bias : packoffset(c26);\n    float4 _1276_fa_shadow_eye : packoffset(c27);\n    float4 _1276_fa_shadow_fwd : packoffset(c28);\n    float4 _1276_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_decal_tex : register(t10);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _541 = _536_fa_cl_info.x < 0.0f;\n    bool _548;\n    if (!_541)\n    {\n        _548 = _536_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _548 = _541;\n    }\n    bool _556;\n    if (!_548)\n    {\n        _556 = _536_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _556 = _548;\n    }\n    bool _563;\n    if (!_556)\n    {\n        _563 = _536_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _563 = _556;\n    }\n    bool _570;\n    if (!_563)\n    {\n        _570 = _536_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _570 = _563;\n    }\n    if (_570)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _580 = float4(world_pos, 1.0f);\n    float _587 = dot(_536_fa_cl_vpw, _580);\n    if (!(_587 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _609 = float2(dot(_536_fa_cl_vpx, _580), dot(_536_fa_cl_vpy, _580)) / _587.xx;\n    int _613 = int(_536_fa_cl_grid.x);\n    int _617 = int(_536_fa_cl_grid.y);\n    int param = (int(_536_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_536_fa_cl_fwd.xyz, world_pos) + _536_fa_cl_fwd.w, _536_fa_cl_grid.w) / _536_fa_cl_grid.w) * _536_fa_cl_grid.z)), 0, int(_536_fa_cl_info.y) - 1) * _617) + clamp(int(floor(((_609.y * 0.5f) + 0.5f) * _536_fa_cl_grid.y)), 0, _617 - 1)) * _613)) + clamp(int(floor(((_609.x * 0.5f) + 0.5f) * _536_fa_cl_grid.x)), 0, _613 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _693 = fa_cluster_texel(param);\n    return int2(int(_693.x), int(_693.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_536_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3397 = fa_cluster_lookup(param);\n    fa_cl_slot = _3397.x;\n    fa_cl_local = _3397.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3553 = fa_linear_to_srgb(param);\n        c = _3553;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3561 = fa_srgb_to_linear(param_1);\n            c = _3561;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _291;\n    if (i.front_facing)\n    {\n        _291 = i.world_normal;\n    }\n    else\n    {\n        _291 = -i.world_normal;\n    }\n    float3 _315 = normalize(i.world_tangent.xyz - (_291 * dot(_291, i.world_tangent.xyz)));\n    float3 _343 = normalize(((_315 * m.x) + ((cross(_291, _315) * i.world_tangent.w) * m.y)) + (_291 * m.z));\n    float3 _346;\n    if (i.front_facing)\n    {\n        _346 = _343;\n    }\n    else\n    {\n        _346 = -_343;\n    }\n    return _346;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _536_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3592 = fa_tex_fix(param_2, param_3);\n    float4 _4891 = base_t;\n    _4891.x = _3592.x;\n    _4891.y = _3592.y;\n    _4891.z = _3592.z;\n    base_t = _4891;\n    float4 _3606 = (_4891 * _536_fa_base_color) * i.vertex_color;\n    float3 _4758 = i.world_normal;\n    if (_536_fa_maps.z > 0.5f)\n    {\n        float param_4 = _536_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3638 = fa_tex_fix(param_6, param_7);\n        float3 _3641 = (_3638 * 2.0f) - 1.0f.xxx;\n        float2 _3646 = _3641.xy * _536_fa_maps.x;\n        float3 _4899 = _3641;\n        _4899.x = _3646.x;\n        _4899.y = _3646.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4899;\n        _4758 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _536_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3675 = fa_tex_fix(param_12, param_13);\n    float4 _4902 = mrt;\n    _4902.x = _3675.x;\n    _4902.y = _3675.y;\n    _4902.z = _3675.z;\n    mrt = _4902;\n    float4 _3703 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _536_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3703.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3715 = fa_tex_fix(param_16, param_17);\n    float param_18 = _536_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3745 = fa_tex_fix(param_20, param_21);\n    float _4763 = _536_fa_layers_a.x;\n    float _4764 = _536_fa_layers_a.y;\n    float _4767 = _536_fa_layers_a.z;\n    float _4766 = _536_fa_layers_b.w;\n    float _4769 = _536_fa_layers_c.x;\n    if (_536_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_536_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4763 *= _3715.y;\n            _4764 *= _3715.z;\n            _4766 *= _3703.w;\n        }\n        if (_536_fa_layers_c.z > 1.5f)\n        {\n            _4767 *= mrt.x;\n            _4769 *= mrt.w;\n        }\n    }\n    Surface _4788 = { _3606.xyz, _3606.w, _4758, clamp(_536_fa_pbr.x * _3675.z, 0.0f, 1.0f), clamp(_536_fa_pbr.y * _3675.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_536_fa_maps.y * (_3715.x - 1.0f)), _536_fa_emissive.xyz + (_536_fa_model_emissive.xyz * _3745), _4763, _4764, _536_fa_layers_b.xyz, _4766, _4767, _536_fa_layers_a.w, _4769, _536_fa_layers_c.y, _536_fa_layers_d.xyz };\n    return _4788;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0f));\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _774 = rect.zw - rect.xy;\n    float2 _778 = _774 * atlas;\n    float2 _782 = ddx * _778;\n    float2 _786 = ddy * _778;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _774), clamp(0.5f * log2(max(max(dot(_782, _782), dot(_786, _786)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _821 = _536_fa_counts.y < 0.5f;\n    bool _828;\n    if (!_821)\n    {\n        _828 = _536_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _828 = _821;\n    }\n    if (_828)\n    {\n        return;\n    }\n    float3 _834 = ddx(world_pos);\n    float3 _837 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _841 = fa_cluster_texel(param);\n    int _845 = int(_841.w);\n    if (_845 < 1)\n    {\n        return;\n    }\n    int _855 = int(_536_fa_counts.y + 0.5f);\n    int param_1 = _855;\n    float4 _859 = fa_light_texel(param_1);\n    float2 _862 = _859.yz;\n    int _866 = int(_859.w);\n    int param_2 = _855 + 1;\n    float4 _871 = fa_light_texel(param_2);\n    float _872 = _871.x;\n    int _878 = int(_536_fa_counts.w + 0.5f) - 1;\n    int _882 = int(_841.z);\n    float3 _1148;\n    for (int k = 0; k < _845; k++)\n    {\n        int _895 = _882 + k;\n        int param_3 = _866 + (_895 >> 2);\n        int _913 = (_855 + 2) + (int(fa_light_texel(param_3)[_895 & 3]) * 7);\n        int param_4 = _913 + 6;\n        float4 _918 = fa_light_texel(param_4);\n        if (((int(_918.w + 0.5f) >> _878) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _913;\n        float4 _933 = fa_light_texel(param_5);\n        int param_6 = _913 + 1;\n        float4 _938 = fa_light_texel(param_6);\n        int param_7 = _913 + 2;\n        float4 _943 = fa_light_texel(param_7);\n        float3 _946 = _933.xyz;\n        float _951 = dot(_946, world_pos) + _933.w;\n        float3 _953 = _938.xyz;\n        float _958 = dot(_953, world_pos) + _938.w;\n        float3 _960 = _943.xyz;\n        float _965 = dot(_960, world_pos) + _943.w;\n        bool _970 = abs(_951) > 0.5f;\n        bool _978;\n        if (!_970)\n        {\n            _978 = abs(_958) > 0.5f;\n        }\n        else\n        {\n            _978 = _970;\n        }\n        bool _986;\n        if (!_978)\n        {\n            _986 = abs(_965) > 0.5f;\n        }\n        else\n        {\n            _986 = _978;\n        }\n        if (_986)\n        {\n            continue;\n        }\n        float _1001 = clamp(dot(geo_normal, normalize(_960)) * _918.z, 0.0f, 1.0f);\n        if (_1001 <= 0.0f)\n        {\n            continue;\n        }\n        float _1021 = (clamp((0.5f - abs(_965)) * 10.0f, 0.0f, 1.0f) * _1001) * _918.x;\n        float2 _1029 = float2(_951 + 0.5f, 0.5f - _958);\n        float2 _1039 = float2(dot(_946, _834), dot(_953, _834));\n        float2 _1049 = float2(dot(_946, _837), dot(_953, _837));\n        int param_8 = _913 + 5;\n        float4 _1054 = fa_light_texel(param_8);\n        int param_9 = _913 + 3;\n        float4 _1059 = fa_light_texel(param_9);\n        int param_10 = _913 + 4;\n        float4 _1064 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1054.xyz;\n        bool _1074 = _1059.z > _1059.x;\n        if (_1074)\n        {\n            float4 param_11 = _1059;\n            float2 param_12 = _1029;\n            float2 param_13 = _862;\n            float2 param_14 = _1039;\n            float2 param_15 = _1049;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_872 > 0.5f) && (_872 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1100 = fa_dc_to_linear(param_16);\n                float4 _4814 = tx;\n                _4814.x = _1100.x;\n                _4814.y = _1100.y;\n                _4814.z = _1100.z;\n                tx = _4814;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1021 * tex_a) * _1054.w, 0.0f, 1.0f).xxx);\n        if (_1064.z > _1064.x)\n        {\n            float4 param_17 = _1064;\n            float2 param_18 = _1029;\n            float2 param_19 = _862;\n            float2 param_20 = _1039;\n            float2 param_21 = _1049;\n            float4 _1144 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_872 > 1.5f)\n            {\n                float3 param_22 = _1144.xyz;\n                float3 _1154 = fa_dc_to_srgb(param_22);\n                _1148 = _1154;\n            }\n            else\n            {\n                _1148 = _1144.xyz;\n            }\n            float3 _1164 = (_1148 * 2.0f) - 1.0f.xxx;\n            float2 _1169 = _1164.xy * _918.y;\n            float3 _1191 = (normalize(_946) * _1169.x) + (normalize(_953) * _1169.y);\n            float3 _1194 = normalize(normal);\n            normal = normalize(lerp(_1194, normalize((_1194 * max(_1164.z, 0.0500000007450580596923828125f)) + (_1191 - (_1194 * dot(_1194, _1191)))), clamp(_1021 * (_1074 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2507 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _2515 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _2518 = int(_2507);\n    int _2521 = int(_2515);\n    float _2531 = _2515 - float(_2521);\n    int _2587 = (_2518 * 9) + _2521;\n    int _2607 = ((_2518 + 1) * 9) + _2521;\n    return lerp(lerp(_2582[_2587], _2582[_2587 + 1], _2531), lerp(_2582[_2607], _2582[_2607 + 1], _2531), _2507 - float(_2518));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4681 = false;\n    float _4682 = 1.0f;\n    float _4683 = 1.0f;\n    float _4684 = 1.0f;\n    float _4685 = 0.0f;\n    float _4686 = 0.0f;\n    float _4687 = 0.0f;\n    float _4688 = 0.0f;\n    float _4690 = 1.0f;\n    bool _4691 = false;\n    float3 _4692 = 0.0f.xxx;\n    float _4693 = 1.0f;\n    float _4694 = 1.0f;\n    float _4695 = 1.0f;\n    float _4696 = 0.0f;\n    float _4697 = 0.0f;\n    float3 _4698 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4699 = float3(0.0f, 0.0f, 1.0f);\n    float _4700 = 1.0f;\n    float _4701 = 1.0f;\n    float _2660 = clamp(s.specular, 0.0f, 1.0f);\n    float _2664 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2669 = (_2660 != 1.0f) || (_2664 != 1.5f);\n    bool _2679;\n    if (!_2669)\n    {\n        _2679 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2679 = _2669;\n    }\n    if (_2679)\n    {\n        float _2687 = (_2664 - 1.0f) / (_2664 + 1.0f);\n        f0 = lerp(min((_2687 * _2687).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2660, s.albedo, metallic.xxx);\n        _4682 = lerp(_2660, 1.0f, metallic);\n        _4681 = true;\n    }\n    float _2715 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2715 > 0.0f)\n    {\n        float _2723 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4685 = _2715;\n        _4686 = _2723;\n        float _2730 = _2723 * _2723;\n        _4687 = _2730;\n        _4688 = _2730 * _2730;\n        float _2742 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4690 = _2742;\n        _4683 = 1.0f - (_2715 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2742, 0.0f, 1.0f), 5.0f))));\n        _4681 = true;\n    }\n    float3 _2762 = max(s.sheen_color, 0.0f.xxx);\n    float _2771 = max(_2762.x, max(_2762.y, _2762.z));\n    if (_2771 > 0.0f)\n    {\n        float _2779 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4691 = true;\n        _4692 = _2762;\n        _4693 = _2779;\n        _4694 = _2779 * _2779;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2779;\n        float _2796 = fa_sheen_albedo(param, param_1);\n        _4696 = _2796;\n        _4695 = 1.0f - min(_2771 * _2796, 1.0f);\n        _4681 = true;\n    }\n    _4684 = _4683 * _4695;\n    float _2815 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2815 != 0.0f)\n    {\n        float3 _2830 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2830;\n        if (dot(_2830, _2830) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2843 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2843.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2843.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2843.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2847 = t;\n        float3 _2848 = normalize(_2847);\n        t = _2848;\n        float3 _2873 = normalize((_2848 * cos(s.anisotropy_rotation)) + ((cross(n, _2848) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4698 = _2873;\n        _4699 = cross(n, _2873);\n        float _2883 = roughness * roughness;\n        float _2889 = lerp(_2883, 1.0f, _2815 * _2815);\n        bool _2891 = _2815 > 0.0f;\n        _4700 = _2891 ? _2889 : _2883;\n        _4701 = _2891 ? _2883 : _2889;\n        _4697 = _2815;\n        _4681 = true;\n    }\n    FaLayers _4723 = { _4681, _4682, _4683, _4684, _4685, _4686, _4687, _4688, i.world_normal, _4690, _4691, _4692, _4693, _4694, _4695, _4696, _4697, _4698, _4699, _4700, _4701 };\n    return _4723;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_536_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _536_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_536_fa_cl_info.x) + int(_536_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _410 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _416 = fa_light_texel(param_1);\n    float _419 = _416.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _425 = _419 < 0.5f;\n    float3 l;\n    if (_425)\n    {\n        l = normalize(_410.xyz);\n    }\n    else\n    {\n        float3 _437 = _410.xyz - world_pos;\n        float _439 = length(_437);\n        dist = _439;\n        l = _437 / max(_439, 9.9999997473787516355514526367188e-05f).xxx;\n        float _454 = _439 / max(_410.w, 0.001000000047497451305389404296875f);\n        float _460 = clamp(1.0f - (_454 * _454), 0.0f, 1.0f);\n        atten = _460 * _460;\n        if (_419 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _474 = fa_light_texel(param_2);\n            float _484 = _474.w;\n            int param_3 = (li * 4) + 3;\n            float4 _490 = fa_light_texel(param_3);\n            float _491 = _490.x;\n            float cos_inner = _491;\n            if (_491 > 1.5f)\n            {\n                cos_inner = lerp(_484, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_484, cos_inner, dot(-l, normalize(_474.xyz)));\n        }\n    }\n    int _522;\n    if (_425)\n    {\n        _522 = 0;\n    }\n    else\n    {\n        _522 = (_419 > 1.5f) ? 2 : 1;\n    }\n    LightSample _4680 = { l, _416.xyz * atten, atten, 1.0f, dist, _522 };\n    return _4680;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1266;\n    if (i == 0)\n    {\n        _1266 = _1276_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1282;\n        if (i == 1)\n        {\n            _1282 = _1276_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1290;\n            if (i == 2)\n            {\n                _1290 = _1276_fa_shadow_split.z;\n            }\n            else\n            {\n                _1290 = _1276_fa_shadow_split.w;\n            }\n            _1282 = _1290;\n        }\n        _1266 = _1282;\n    }\n    return _1266;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _1323 = fa_shadow_depth(param, param_1);\n    float _1327;\n    if (conv.x < 0.5f)\n    {\n        _1327 = _1323;\n    }\n    else\n    {\n        _1327 = (conv.y * conv.z) / (conv.z - (_1323 * (conv.z - conv.y)));\n    }\n    return _1327;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1254 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1254), sin(_1254)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1373 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _1387 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1373;\n            float2 _1406 = fa_shadow_vogel(param_3, param_4, param_5) * _1387;\n            float2 param_6 = uv + (_1406 * _1276_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _1418 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1418 < (zr - (length(_1406) * plane)))\n            {\n                sum += _1418;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1462 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1462; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1462;\n        float param_11 = _1373;\n        float2 _1481 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_1481 * _1276_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_1481) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1462);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1523 = max(_1276_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1528 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1534 = sqrt(1.0f - (_1528 * _1528));\n    float _1541 = min(_1534 / max(_1528, 0.20000000298023223876953125f), 4.0f);\n    float _1546;\n    if (_1276_fa_shadow_bias.y > 0.0f)\n    {\n        _1546 = _1276_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1546 = 1.5f * _1276_fa_shadow_info[ci].x;\n    }\n    float4 _1571 = mul(float4(world + (n * (_1546 * _1534)), 1.0f), _1276_fa_shadow_mat[ci]);\n    float _1578 = _1571.x;\n    bool _1581 = _1578 < _1276_fa_shadow_rect[ci].x;\n    bool _1590;\n    if (!_1581)\n    {\n        _1590 = _1578 > _1276_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1590 = _1581;\n    }\n    bool _1599;\n    if (!_1590)\n    {\n        _1599 = _1571.y < _1276_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1599 = _1590;\n    }\n    bool _1608;\n    if (!_1599)\n    {\n        _1608 = _1571.y > _1276_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1608 = _1599;\n    }\n    bool _1615;\n    if (!_1608)\n    {\n        _1615 = _1571.z > 1.0f;\n    }\n    else\n    {\n        _1615 = _1608;\n    }\n    if (_1615)\n    {\n        return -1.0f;\n    }\n    float _1624;\n    if (_1276_fa_shadow_bias.x > 0.0f)\n    {\n        _1624 = _1276_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1624 = 1.5f * _1276_fa_shadow_info[ci].x;\n    }\n    float2 param = _1571.xy;\n    float4 param_1 = _1276_fa_shadow_rect[ci];\n    float param_2 = _1571.z - ((_1624 * (1.0f + (0.5f * _1541))) / _1523);\n    float param_3 = _1276_fa_shadow_info[ci].x;\n    float param_4 = _1523;\n    float param_5 = _1523 * 0.25f;\n    float param_6 = ((_1276_fa_shadow_info[ci].x * min(_1541, 3.0f)) * 0.5f) / _1523;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_1276_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _1276_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_536_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2051 = int(_1276_fa_shadow_cfg.x + 0.5f);\n    if (_2051 < 1)\n    {\n        return 1.0f;\n    }\n    float _2066 = dot(world - _1276_fa_shadow_eye.xyz, _1276_fa_shadow_fwd.xyz);\n    int param = _2051 - 1;\n    if (_2066 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2078 = _2051 > 1;\n    bool _2085;\n    if (_2078)\n    {\n        _2085 = _2066 > _1276_fa_shadow_split.x;\n    }\n    else\n    {\n        _2085 = _2078;\n    }\n    if (_2085)\n    {\n        ci = 1;\n    }\n    bool _2089 = _2051 > 2;\n    bool _2096;\n    if (_2089)\n    {\n        _2096 = _2066 > _1276_fa_shadow_split.y;\n    }\n    else\n    {\n        _2096 = _2089;\n    }\n    if (_2096)\n    {\n        ci = 2;\n    }\n    bool _2100 = _2051 > 3;\n    bool _2107;\n    if (_2100)\n    {\n        _2107 = _2066 > _1276_fa_shadow_split.z;\n    }\n    else\n    {\n        _2107 = _2100;\n    }\n    if (_2107)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2051)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2133 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2133;\n        if (_2133 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1276_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2158;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2158 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2158 = _1276_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2177 = _1276_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2158, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2188 = clamp((_2066 - (fa_shadow_split_at(param_7) - _2177)) / _2177, 0.0f, 1.0f);\n        if (_2188 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2051)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2209 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2209;\n                if (_2209 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2188);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1682 = _536_fa_pbr.z < 0.5f;\n    bool _1690;\n    if (!_1682)\n    {\n        _1690 = _1276_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1690 = _1682;\n    }\n    if (_1690)\n    {\n        return 1.0f;\n    }\n    int param = (int(_1276_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1703 = fa_light_texel(param);\n    float _1704 = _1703.x;\n    if (_1704 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1713 = int(_1704 + 0.5f);\n    int param_1 = _1713;\n    float4 _1717 = fa_light_texel(param_1);\n    int param_2 = _1713 + 1;\n    float4 _1722 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1725 = _1717.y;\n    if (_1725 > 0.0f)\n    {\n        float _1742 = 1.0f - smoothstep(0.75f * _1725, _1725, length(world - _1276_fa_shadow_eye.xyz));\n        fade = _1742;\n        if (_1742 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1717.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1761 = world - fa_light_texel(param_3).xyz;\n        float3 _1764 = abs(_1761);\n        float _1766 = _1764.x;\n        float _1768 = _1764.y;\n        bool _1769 = _1766 >= _1768;\n        bool _1777;\n        if (_1769)\n        {\n            _1777 = _1766 >= _1764.z;\n        }\n        else\n        {\n            _1777 = _1769;\n        }\n        int _1778;\n        if (_1777)\n        {\n            _1778 = (_1761.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1791;\n            if (_1768 >= _1764.z)\n            {\n                _1791 = (_1761.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1791 = (_1761.z > 0.0f) ? 4 : 5;\n            }\n            _1778 = _1791;\n        }\n        face = _1778;\n    }\n    int _1810 = (_1713 + 2) + (face * 6);\n    int param_4 = _1810;\n    int param_5 = _1810 + 1;\n    int param_6 = _1810 + 3;\n    float4 _1824 = fa_light_texel(param_6);\n    int param_7 = _1810 + 4;\n    float4 _1829 = fa_light_texel(param_7);\n    int param_8 = _1810 + 5;\n    float4 _1834 = fa_light_texel(param_8);\n    float _1846 = _1834.x * max(dot(_1824, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1851 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1874 = clamp(dot(n, _1824.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1897 = min(sqrt(1.0f - (_1874 * _1874)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1824, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1900 = _1722.y;\n    float _1902;\n    if (_1900 > 0.0f)\n    {\n        _1902 = _1900;\n    }\n    else\n    {\n        _1902 = 1.5f * _1846;\n    }\n    float4 _1922 = float4(world + (n * (_1902 * sqrt(1.0f - (_1851 * _1851)))), 1.0f);\n    float _1926 = dot(_1824, _1922);\n    float _1929 = _1834.y;\n    if (_1926 < _1929)\n    {\n        return 1.0f;\n    }\n    float2 _1944 = float2(dot(fa_light_texel(param_4), _1922), dot(fa_light_texel(param_5), _1922)) / _1926.xx;\n    float _1946 = _1944.x;\n    bool _1949 = _1946 < _1829.x;\n    bool _1958;\n    if (!_1949)\n    {\n        _1958 = _1946 > _1829.z;\n    }\n    else\n    {\n        _1958 = _1949;\n    }\n    bool _1967;\n    if (!_1958)\n    {\n        _1967 = _1944.y < _1829.y;\n    }\n    else\n    {\n        _1967 = _1958;\n    }\n    bool _1976;\n    if (!_1967)\n    {\n        _1976 = _1944.y > _1829.w;\n    }\n    else\n    {\n        _1976 = _1967;\n    }\n    if (_1976)\n    {\n        return 1.0f;\n    }\n    float _1982 = _1722.x;\n    float _1984;\n    if (_1982 > 0.0f)\n    {\n        _1984 = _1982;\n    }\n    else\n    {\n        _1984 = 1.5f * _1846;\n    }\n    float2 param_10 = _1944;\n    float4 param_11 = _1829;\n    float param_12 = _1926 - (_1984 * (1.0f + (0.5f * _1897)));\n    float param_13 = _1846;\n    float param_14 = 1.0f;\n    float param_15 = _1834.z * 0.25f;\n    float param_16 = (_1846 * min(_1897, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1929, _1834.z);\n    int param_18 = int(_1717.z + 0.5f);\n    float param_19 = _1717.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3424 = fa_lm.z > 0.5f;\n    bool _3430;\n    if (_3424)\n    {\n        int param = li;\n        _3430 = fa_light_baked(param);\n    }\n    else\n    {\n        _3430 = _3424;\n    }\n    if (_3430)\n    {\n        int param_1 = li;\n        LightSample _4736 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4736;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _3452 = fa_light_sample(param_2, param_3);\n    float3 _4743 = _3452.direction;\n    float3 _4738 = _3452.color;\n    float _4745 = _3452.attenuation;\n    float _4740 = _3452.shadow;\n    int _4748 = _3452.type;\n    if ((_4748 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _4743;\n        float _3466 = fa_shadow_factor(param_4, param_5);\n        _4740 = _3466;\n        _4738 *= _3466;\n    }\n    else\n    {\n        bool _3477 = _4748 != 0;\n        bool _3483;\n        if (_3477)\n        {\n            _3483 = _4745 > 0.0f;\n        }\n        else\n        {\n            _3483 = _3477;\n        }\n        if (_3483)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _4743;\n            float _3495 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4740 = _3495;\n            _4738 *= _3495;\n        }\n    }\n    LightSample _4755 = { _4743, _4738, _4745, _4740, _3452._distance, _4748 };\n    return _4755;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3041 = tdh / at;\n    float _3045 = bdh / ab;\n    float _3057 = ((_3041 * _3041) + (_3045 * _3045)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _3057) * _3057);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _3138 = 1.0f / alpha;\n    return ((2.0f + _3138) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _3138)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _3170 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3249 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _3249) * _3249);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _3170);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _3170));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _3322 = max(dot(L.nc, l), 0.0f);\n        float _3328 = max(dot(L.nc, h), 0.0f);\n        float _3337 = ((_3328 * _3328) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _3337) * _3337)) * (0.5f / max(lerp((2.0f * _3322) * L.coat_ndv, _3322 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _3322)) * _3322).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _2439 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _2442 = _2439.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_2442 * _2442, exp2((-9.27999973297119140625f) * ndv)) * _2442) + _2439.y)) + _2439.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_536_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _536_fa_env_horizon.w).xyz;\n    }\n    float _2345 = rough * rough;\n    float _2375 = 0.60000002384185791015625f * _2345;\n    return lerp(lerp(_536_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_536_fa_env_horizon.xyz, _536_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _2345)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _2375, 0.0500000007450580596923828125f + _2375, d.y).xxx), ((_536_fa_env_sky.xyz + _536_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_2345 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2924;\n        if (L.aniso >= 0.0f)\n        {\n            _2924 = L.b;\n        }\n        else\n        {\n            _2924 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2924, v), _2924), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2957 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2957.x) + (L.f90.xxx * _2957.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3012 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3012.x) + _3012.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2481 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2481.x) + _2481.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1276_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2233 = int(_1276_fa_shadow_cfg.x + 0.5f);\n    float _2243 = dot(world - _1276_fa_shadow_eye.xyz, _1276_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2248 = _2233 > 0;\n    bool _2257;\n    if (_2248)\n    {\n        int param = _2233 - 1;\n        _2257 = _2243 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2257 = _2248;\n    }\n    if (_2257)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _2264 = _2233 > 1;\n        bool _2271;\n        if (_2264)\n        {\n            _2271 = _2243 > _1276_fa_shadow_split.x;\n        }\n        else\n        {\n            _2271 = _2264;\n        }\n        if (_2271)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _2277 = _2233 > 2;\n        bool _2284;\n        if (_2277)\n        {\n            _2284 = _2243 > _1276_fa_shadow_split.y;\n        }\n        else\n        {\n            _2284 = _2277;\n        }\n        if (_2284)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _2290 = _2233 > 3;\n        bool _2297;\n        if (_2290)\n        {\n            _2297 = _2243 > _1276_fa_shadow_split.z;\n        }\n        else\n        {\n            _2297 = _2290;\n        }\n        if (_2297)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4460 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4460 = -_4460;\n    }\n    float3 _3885 = normalize(_536_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4473 = { fa_world_pos, _4460, fa_world_tangent, fa_uv, fa_vertex_color, _3885, gl_FrontFacing };\n    SurfaceInput param_1 = _4473;\n    Surface _3893 = fa_standard_surface(param_1);\n    float3 _4491 = _3893.albedo;\n    float _4492 = _3893.alpha;\n    float3 _4493 = _3893.normal;\n    float _4494 = _3893.metallic;\n    float _4495 = _3893.roughness;\n    float _4496 = _3893.occlusion;\n    float3 _4497 = _3893.emission;\n    float _4498 = _3893.clearcoat;\n    float _4499 = _3893.clearcoat_roughness;\n    float3 _4500 = _3893.sheen_color;\n    float _4501 = _3893.sheen_roughness;\n    float _4502 = _3893.anisotropy;\n    float _4503 = _3893.anisotropy_rotation;\n    float _4504 = _3893.specular;\n    float _4505 = _3893.ior;\n    float3 _4506 = _3893.specular_color;\n    SurfaceInput _4481 = { fa_world_pos, _4460, fa_world_tangent, fa_uv, fa_vertex_color, _3885, gl_FrontFacing };\n    SurfaceInput param_2 = _4481;\n    Surface param_3 = _3893;\n    surface(param_2, param_3);\n    _4491 = param_3.albedo;\n    _4492 = param_3.alpha;\n    _4493 = param_3.normal;\n    _4494 = param_3.metallic;\n    _4495 = param_3.roughness;\n    _4496 = param_3.occlusion;\n    _4497 = param_3.emission;\n    _4498 = param_3.clearcoat;\n    _4499 = param_3.clearcoat_roughness;\n    _4500 = param_3.sheen_color;\n    _4501 = param_3.sheen_roughness;\n    _4502 = param_3.anisotropy;\n    _4503 = param_3.anisotropy_rotation;\n    _4504 = param_3.specular;\n    _4505 = param_3.ior;\n    _4506 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4460;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4491 = param_6;\n    _4493 = param_7;\n    float3 result;\n    if (_536_fa_emissive.w > 0.5f)\n    {\n        result = _4491;\n    }\n    else\n    {\n        float3 _3932 = normalize(_4493);\n        float _3939 = clamp(_4494, 0.0f, 1.0f);\n        float _3943 = clamp(_4495, 0.0500000007450580596923828125f, 1.0f);\n        float _3947 = _3943 * _3943;\n        float _3951 = _3947 * _3947;\n        float _3956 = max(dot(_3932, _3885), 9.9999997473787516355514526367188e-05f);\n        float3 _3962 = _4491 * (1.0f - _3939);\n        float3 _3969 = lerp(0.039999999105930328369140625f.xxx, _4491, _3939.xxx);\n        float3 f0 = _3969;\n        SurfaceInput _4489 = { fa_world_pos, _4460, fa_world_tangent, fa_uv, fa_vertex_color, _3885, gl_FrontFacing };\n        SurfaceInput param_8 = _4489;\n        Surface _4572 = { _4491, _4492, _4493, _4494, _4495, _4496, _4497, _4498, _4499, _4500, _4501, _4502, _4503, _4504, _4505, _4506 };\n        Surface param_9 = _4572;\n        float3 param_10 = _3932;\n        float3 param_11 = _3885;\n        float param_12 = _3939;\n        float param_13 = _3943;\n        float3 param_14 = _3969;\n        FaLayers _3985 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        float3 param_15 = _3932;\n        float3 lit = (fa_indirect_diffuse(param_15) * _3962) * _4496;\n        if (_3985.on)\n        {\n            lit *= _3985.base_scale;\n        }\n        int _4007 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4007; ln++)\n        {\n            int param_16 = ln;\n            int _4020 = fa_cl_light(param_16);\n            bool _4023 = fa_lm.z > 0.5f;\n            bool _4029;\n            if (_4023)\n            {\n                int param_17 = _4020;\n                _4029 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _4029 = _4023;\n            }\n            if (_4029)\n            {\n                continue;\n            }\n            int param_18 = _4020;\n            float3 param_19 = fa_world_pos;\n            float3 param_20 = _4460;\n            LightSample _4041 = fa_light_shadowed(param_18, param_19, param_20);\n            float3 _4665 = _4041.direction;\n            float _4049 = max(dot(_3932, _4665), 0.0f);\n            float _4055 = _4041.attenuation * _4041.shadow;\n            float3 _4060 = normalize(_4665 + _3885);\n            float _4065 = max(dot(_3932, _4060), 0.0f);\n            float _4070 = max(dot(_3885, _4060), 0.0f);\n            if (_3985.on)\n            {\n                FaLayers param_21 = _3985;\n                float3 param_22 = _3962;\n                float3 param_23 = f0;\n                float3 param_24 = _3932;\n                float3 param_25 = _3885;\n                float3 param_26 = _4665;\n                float3 param_27 = _4060;\n                float param_28 = _4049;\n                float param_29 = _3956;\n                float param_30 = _4065;\n                float param_31 = _4070;\n                float param_32 = _3947;\n                float param_33 = _3951;\n                int param_34 = _4020;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34) * _4055));\n            }\n            else\n            {\n                float _4118 = ((_4065 * _4065) * (_3951 - 1.0f)) + 1.0f;\n                int param_35 = _4020;\n                lit += (((_3962 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _4070, 5.0f))) * (((_3951 / ((3.1415927410125732421875f * _4118) * _4118)) * (0.5f / max(lerp((2.0f * _4049) * _3956, _4049 + _3956, _3947), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4049))) * fa_light_rgb(param_35)) * (_4049 * _4055));\n            }\n        }\n        if (_3985.on)\n        {\n            FaLayers param_36 = _3985;\n            float3 param_37 = _3932;\n            float3 param_38 = _3885;\n            float3 param_39 = f0;\n            float param_40 = _3943;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40) * _4496);\n        }\n        else\n        {\n            float3 param_41 = _3932;\n            float3 param_42 = _3885;\n            float3 param_43 = f0;\n            float param_44 = _3943;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44) * _4496);\n        }\n        result = lit;\n    }\n    float3 _4211 = result;\n    float3 _4212 = _4211 + _4497;\n    result = _4212;\n    float3 param_45 = _4212;\n    float3 param_46 = fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46);\n    bool _4221 = _536_fa_fog.w > 0.0f;\n    bool _4228;\n    if (!_4221)\n    {\n        _4228 = _536_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4228 = _4221;\n    }\n    if (_4228)\n    {\n        float3 _4237 = fa_world_pos - _536_fa_camera_pos.xyz;\n        float _4243 = dot(_4237, _536_fa_fog_c.xyz);\n        bool _4247 = _536_fa_fog_c.w > 0.5f;\n        float _4248;\n        if (_4247)\n        {\n            _4248 = _4243;\n        }\n        else\n        {\n            _4248 = length(_4237);\n        }\n        float _4260 = _4248 - _536_fa_fog_b.x;\n        if (_4260 > 0.0f)\n        {\n            float _4269 = _536_fa_fog.w * _4260;\n            float tau = _4269 * _4269;\n            if (_536_fa_fog_b.y > 0.0f)\n            {\n                float _4285;\n                if (_4247)\n                {\n                    _4285 = fa_world_pos.y - (_536_fa_fog_c.y * _4243);\n                }\n                else\n                {\n                    _4285 = _536_fa_camera_pos.y;\n                }\n                float _4306 = lerp(_4285, fa_world_pos.y, clamp(_536_fa_fog_b.x / _4248, 0.0f, 1.0f));\n                float _4310 = fa_world_pos.y - _4306;\n                float _4315 = _4306 - _536_fa_fog_b.z;\n                float _4320 = fa_world_pos.y - _536_fa_fog_b.z;\n                bool _4323 = _4315 <= 0.0f;\n                bool _4324 = !_4323;\n                bool _4330;\n                if (_4324)\n                {\n                    _4330 = _536_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4330 = _4323;\n                }\n                float _4331;\n                if (_4330)\n                {\n                    _4331 = _536_fa_fog_b.y;\n                }\n                else\n                {\n                    _4331 = _536_fa_fog_b.y * exp(-min(_536_fa_fog_b.w * _4315, 80.0f));\n                }\n                bool _4358;\n                if (_4324)\n                {\n                    _4358 = _536_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4358 = _4323;\n                }\n                float _4359;\n                if (_4358)\n                {\n                    _4359 = _536_fa_fog_b.y * _4315;\n                }\n                else\n                {\n                    _4359 = (_536_fa_fog_b.y * (1.0f - exp(-min(_536_fa_fog_b.w * _4315, 80.0f)))) / _536_fa_fog_b.w;\n                }\n                bool _4384 = _4320 <= 0.0f;\n                bool _4391;\n                if (!_4384)\n                {\n                    _4391 = _536_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4391 = _4384;\n                }\n                float _4392;\n                if (_4391)\n                {\n                    _4392 = _536_fa_fog_b.y * _4320;\n                }\n                else\n                {\n                    _4392 = (_536_fa_fog_b.y * (1.0f - exp(-min(_536_fa_fog_b.w * _4320, 80.0f)))) / _536_fa_fog_b.w;\n                }\n                float _4419;\n                if (abs(_4310) < 0.001000000047497451305389404296875f)\n                {\n                    _4419 = _4331;\n                }\n                else\n                {\n                    _4419 = (_4392 - _4359) / _4310;\n                }\n                tau += (_4260 * max(_4419, 0.0f));\n            }\n            result = lerp(result, _536_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4492);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 11,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 11
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 12
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_149",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_195",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_536",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1276",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 9
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _144_fa_view_proj : packoffset(c0);\n    row_major float4x4 _144_fa_light_vp : packoffset(c4);\n    float4 _144_fa_uv_scale : packoffset(c8);\n    float4 _144_fa_time : packoffset(c9);\n    float4 _144_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float2 fa_attr_uv1 : TEXCOORD9;\n    float4 fa_attr_color1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _312 = { mul(float4(position, 1.0f), model).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _144_fa_uv_scale.xy, color, position };\n    return _312;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _187 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_187, _144_fa_light_vp).z;\n    fa_pre_r0 = float3(_144_fa_light_vp[0].x, _144_fa_light_vp[1].x, _144_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_144_fa_light_vp[0].y, _144_fa_light_vp[1].y, _144_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_144_fa_light_vp[0].z, _144_fa_light_vp[1].z, _144_fa_light_vp[2].z);\n    gl_Position = mul(_187, _144_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _226_fa_camera_pos : packoffset(c0);\n    float4 _226_fa_ambient : packoffset(c1);\n    float4 _226_fa_base_color : packoffset(c2);\n    float4 _226_fa_emissive : packoffset(c3);\n    float4 _226_fa_model_emissive : packoffset(c4);\n    float4 _226_fa_pbr : packoffset(c5);\n    float4 _226_fa_maps : packoffset(c6);\n    float4 _226_fa_fog : packoffset(c7);\n    float4 _226_fa_fog_b : packoffset(c8);\n    float4 _226_fa_fog_c : packoffset(c9);\n    float4 _226_fa_counts : packoffset(c10);\n    float4 _226_fa_env_sky : packoffset(c11);\n    float4 _226_fa_env_horizon : packoffset(c12);\n    float4 _226_fa_time : packoffset(c13);\n    float4 _226_fa_cl_vpx : packoffset(c14);\n    float4 _226_fa_cl_vpy : packoffset(c15);\n    float4 _226_fa_cl_vpw : packoffset(c16);\n    float4 _226_fa_cl_fwd : packoffset(c17);\n    float4 _226_fa_cl_grid : packoffset(c18);\n    float4 _226_fa_cl_info : packoffset(c19);\n    float4 _226_fa_layers_a : packoffset(c20);\n    float4 _226_fa_layers_b : packoffset(c21);\n    float4 _226_fa_layers_c : packoffset(c22);\n    float4 _226_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _226_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _238 = fa_tex_fix(param_2, param_3);\n    float4 _745 = base_t;\n    _745.x = _238.x;\n    _745.y = _238.y;\n    _745.z = _238.z;\n    base_t = _745;\n    float4 _253 = (_745 * _226_fa_base_color) * i.vertex_color;\n    float3 _708 = i.world_normal;\n    if (_226_fa_maps.z > 0.5f)\n    {\n        float param_4 = _226_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _226_fa_maps.x;\n        float3 _753 = _290;\n        _753.x = _295.x;\n        _753.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _753;\n        _708 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _226_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _756 = mrt;\n    _756.x = _324.x;\n    _756.y = _324.y;\n    _756.z = _324.z;\n    mrt = _756;\n    float4 _354 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _226_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _713 = _226_fa_layers_a.x;\n    float _714 = _226_fa_layers_a.y;\n    float _717 = _226_fa_layers_a.z;\n    float _716 = _226_fa_layers_b.w;\n    float _719 = _226_fa_layers_c.x;\n    if (_226_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_226_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _713 *= _366.y;\n            _714 *= _366.z;\n            _716 *= _354.w;\n        }\n        if (_226_fa_layers_c.z > 1.5f)\n        {\n            _717 *= mrt.x;\n            _719 *= mrt.w;\n        }\n    }\n    Surface _738 = { _253.xyz, _253.w, _708, clamp(_226_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_226_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_226_fa_maps.y * (_366.x - 1.0f)), _226_fa_emissive.xyz + (_226_fa_model_emissive.xyz * _396), _713, _714, _226_fa_layers_b.xyz, _716, _717, _226_fa_layers_a.w, _719, _226_fa_layers_c.y, _226_fa_layers_d.xyz };\n    return _738;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0f));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _619 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _619 = -_619;\n    }\n    float3 _530 = normalize(_226_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _632 = { fa_world_pos, _619, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param = _632;\n    SurfaceInput _640 = { fa_world_pos, _619, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param_1 = _640;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _545 = normalize(param_2.normal);\n    float3 _560 = normalize(float3(dot(fa_pre_r0, _545), dot(fa_pre_r1, _545), dot(fa_pre_r2, _545)));\n    float _572 = _560.z;\n    float2 e = _560.xy / ((abs(_560.x) + abs(_560.y)) + abs(_572)).xx;\n    if (_572 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec2",
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
            "inst_name": "_144",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_226",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _149_fa_view_proj : packoffset(c0);\n    row_major float4x4 _149_fa_light_vp : packoffset(c4);\n    float4 _149_fa_uv_scale : packoffset(c8);\n    float4 _149_fa_time : packoffset(c9);\n    float4 _149_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _195_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float2 fa_attr_uv1 : TEXCOORD11;\n    float4 fa_attr_color1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _186 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_195_fa_joint_rows[_186] * weights[i]);\n        r1 += (_195_fa_joint_rows[_186 + 1] * weights[i]);\n        r2 += (_195_fa_joint_rows[_186 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _433 = { mul(float4(position, 1.0f), model).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _149_fa_uv_scale.xy, color, position };\n    return _433;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _300 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_300, _149_fa_light_vp).z;\n    fa_pre_r0 = float3(_149_fa_light_vp[0].x, _149_fa_light_vp[1].x, _149_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_149_fa_light_vp[0].y, _149_fa_light_vp[1].y, _149_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_149_fa_light_vp[0].z, _149_fa_light_vp[1].z, _149_fa_light_vp[2].z);\n    gl_Position = mul(_300, _149_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _226_fa_camera_pos : packoffset(c0);\n    float4 _226_fa_ambient : packoffset(c1);\n    float4 _226_fa_base_color : packoffset(c2);\n    float4 _226_fa_emissive : packoffset(c3);\n    float4 _226_fa_model_emissive : packoffset(c4);\n    float4 _226_fa_pbr : packoffset(c5);\n    float4 _226_fa_maps : packoffset(c6);\n    float4 _226_fa_fog : packoffset(c7);\n    float4 _226_fa_fog_b : packoffset(c8);\n    float4 _226_fa_fog_c : packoffset(c9);\n    float4 _226_fa_counts : packoffset(c10);\n    float4 _226_fa_env_sky : packoffset(c11);\n    float4 _226_fa_env_horizon : packoffset(c12);\n    float4 _226_fa_time : packoffset(c13);\n    float4 _226_fa_cl_vpx : packoffset(c14);\n    float4 _226_fa_cl_vpy : packoffset(c15);\n    float4 _226_fa_cl_vpw : packoffset(c16);\n    float4 _226_fa_cl_fwd : packoffset(c17);\n    float4 _226_fa_cl_grid : packoffset(c18);\n    float4 _226_fa_cl_info : packoffset(c19);\n    float4 _226_fa_layers_a : packoffset(c20);\n    float4 _226_fa_layers_b : packoffset(c21);\n    float4 _226_fa_layers_c : packoffset(c22);\n    float4 _226_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _226_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _238 = fa_tex_fix(param_2, param_3);\n    float4 _745 = base_t;\n    _745.x = _238.x;\n    _745.y = _238.y;\n    _745.z = _238.z;\n    base_t = _745;\n    float4 _253 = (_745 * _226_fa_base_color) * i.vertex_color;\n    float3 _708 = i.world_normal;\n    if (_226_fa_maps.z > 0.5f)\n    {\n        float param_4 = _226_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _226_fa_maps.x;\n        float3 _753 = _290;\n        _753.x = _295.x;\n        _753.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _753;\n        _708 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _226_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _756 = mrt;\n    _756.x = _324.x;\n    _756.y = _324.y;\n    _756.z = _324.z;\n    mrt = _756;\n    float4 _354 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _226_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _226_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _713 = _226_fa_layers_a.x;\n    float _714 = _226_fa_layers_a.y;\n    float _717 = _226_fa_layers_a.z;\n    float _716 = _226_fa_layers_b.w;\n    float _719 = _226_fa_layers_c.x;\n    if (_226_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_226_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _713 *= _366.y;\n            _714 *= _366.z;\n            _716 *= _354.w;\n        }\n        if (_226_fa_layers_c.z > 1.5f)\n        {\n            _717 *= mrt.x;\n            _719 *= mrt.w;\n        }\n    }\n    Surface _738 = { _253.xyz, _253.w, _708, clamp(_226_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_226_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_226_fa_maps.y * (_366.x - 1.0f)), _226_fa_emissive.xyz + (_226_fa_model_emissive.xyz * _396), _713, _714, _226_fa_layers_b.xyz, _716, _717, _226_fa_layers_a.w, _719, _226_fa_layers_c.y, _226_fa_layers_d.xyz };\n    return _738;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0f));\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _619 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _619 = -_619;\n    }\n    float3 _530 = normalize(_226_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _632 = { fa_world_pos, _619, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param = _632;\n    SurfaceInput _640 = { fa_world_pos, _619, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param_1 = _640;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _545 = normalize(param_2.normal);\n    float3 _560 = normalize(float3(dot(fa_pre_r0, _545), dot(fa_pre_r1, _545), dot(fa_pre_r2, _545)));\n    float _572 = _560.z;\n    float2 e = _560.xy / ((abs(_560.x) + abs(_560.y)) + abs(_572)).xx;\n    if (_572 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 11,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 11
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 12
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_149",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_195",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_226",
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
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _135_fa_view_proj : packoffset(c0);\n    row_major float4x4 _135_fa_light_vp : packoffset(c4);\n    float4 _135_fa_uv_scale : packoffset(c8);\n    float4 _135_fa_time : packoffset(c9);\n    float4 _135_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n    float2 fa_attr_uv1 : TEXCOORD9;\n    float4 fa_attr_color1 : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _264 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _135_fa_uv_scale.xy, color, position };\n    return _264;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _135_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
      "fs": "static float4 gl_FragCoord;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid frag_main()\n{\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 9,
            "type": "vec2",
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
            "inst_name": "_135",
            "hlsl_register_b_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _140_fa_view_proj : packoffset(c0);\n    row_major float4x4 _140_fa_light_vp : packoffset(c4);\n    float4 _140_fa_uv_scale : packoffset(c8);\n    float4 _140_fa_time : packoffset(c9);\n    float4 _140_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _186_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float2 fa_attr_uv1;\nstatic float4 fa_attr_color1;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n    float2 fa_attr_uv1 : TEXCOORD11;\n    float4 fa_attr_color1 : TEXCOORD12;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 vertex_color1;\nstatic float2 vertex_uv1;\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _177 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_186_fa_joint_rows[_177] * weights[i]);\n        r1 += (_186_fa_joint_rows[_177 + 1] * weights[i]);\n        r2 += (_186_fa_joint_rows[_177 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _79 = cross(model[1].xyz, model[2].xyz);\n    float _85 = (dot(model[0].xyz, _79) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _385 = { mul(float4(position, 1.0f), model).xyz, (((_79 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _85, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _85), texcoord0 * _140_fa_uv_scale.xy, color, position };\n    return _385;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _140_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_attr_uv1 = stage_input.fa_attr_uv1;\n    fa_attr_color1 = stage_input.fa_attr_color1;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
      "fs": "static float4 gl_FragCoord;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid frag_main()\n{\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 11,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 11
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 12
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_140",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_186",
            "hlsl_register_b_n": 3
          }
        ]
      }
    }
  }
}
