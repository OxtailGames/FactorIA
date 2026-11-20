{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "194db57da3c2e45b061059a5d5aaa1ec99bea4d520978217d5e137fe8b76e503",
  "slang": "hlsl5",
  "params": [
    "offset"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _45_offset : packoffset(c0);\n    float _45_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _145_fa_view_proj : packoffset(c0);\n    row_major float4x4 _145_fa_light_vp : packoffset(c4);\n    float4 _145_fa_uv_scale : packoffset(c8);\n    float4 _145_fa_time : packoffset(c9);\n    float4 _145_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _278 = { mul(float4(position, 1.0f), model).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _145_fa_uv_scale.xy, color, position };\n    return _278;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _45_offset;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _145_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1616[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _486_fa_camera_pos : packoffset(c0);\n    float4 _486_fa_ambient : packoffset(c1);\n    float4 _486_fa_base_color : packoffset(c2);\n    float4 _486_fa_emissive : packoffset(c3);\n    float4 _486_fa_model_emissive : packoffset(c4);\n    float4 _486_fa_pbr : packoffset(c5);\n    float4 _486_fa_maps : packoffset(c6);\n    float4 _486_fa_fog : packoffset(c7);\n    float4 _486_fa_fog_b : packoffset(c8);\n    float4 _486_fa_fog_c : packoffset(c9);\n    float4 _486_fa_counts : packoffset(c10);\n    float4 _486_fa_env_sky : packoffset(c11);\n    float4 _486_fa_env_horizon : packoffset(c12);\n    float4 _486_fa_time : packoffset(c13);\n    float4 _486_fa_cl_vpx : packoffset(c14);\n    float4 _486_fa_cl_vpy : packoffset(c15);\n    float4 _486_fa_cl_vpw : packoffset(c16);\n    float4 _486_fa_cl_fwd : packoffset(c17);\n    float4 _486_fa_cl_grid : packoffset(c18);\n    float4 _486_fa_cl_info : packoffset(c19);\n    float4 _486_fa_layers_a : packoffset(c20);\n    float4 _486_fa_layers_b : packoffset(c21);\n    float4 _486_fa_layers_c : packoffset(c22);\n    float4 _486_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _722_fa_shadow_mat[4] : packoffset(c0);\n    float4 _722_fa_shadow_rect[4] : packoffset(c16);\n    float4 _722_fa_shadow_info[4] : packoffset(c20);\n    float4 _722_fa_shadow_split : packoffset(c24);\n    float4 _722_fa_shadow_cfg : packoffset(c25);\n    float4 _722_fa_shadow_bias : packoffset(c26);\n    float4 _722_fa_shadow_eye : packoffset(c27);\n    float4 _722_fa_shadow_fwd : packoffset(c28);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _491 = _486_fa_cl_info.x < 0.0f;\n    bool _498;\n    if (!_491)\n    {\n        _498 = _486_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _498 = _491;\n    }\n    bool _506;\n    if (!_498)\n    {\n        _506 = _486_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _506 = _498;\n    }\n    bool _513;\n    if (!_506)\n    {\n        _513 = _486_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _513 = _506;\n    }\n    bool _520;\n    if (!_513)\n    {\n        _520 = _486_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _520 = _513;\n    }\n    if (_520)\n    {\n        return int2(0, 0);\n    }\n    float4 _530 = float4(world_pos, 1.0f);\n    float _537 = dot(_486_fa_cl_vpw, _530);\n    if (!(_537 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _559 = float2(dot(_486_fa_cl_vpx, _530), dot(_486_fa_cl_vpy, _530)) / _537.xx;\n    int _563 = int(_486_fa_cl_grid.x);\n    int _567 = int(_486_fa_cl_grid.y);\n    int param = (int(_486_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_486_fa_cl_fwd.xyz, world_pos) + _486_fa_cl_fwd.w, _486_fa_cl_grid.w) / _486_fa_cl_grid.w) * _486_fa_cl_grid.z)), 0, int(_486_fa_cl_info.y) - 1) * _567) + clamp(int(floor(((_559.y * 0.5f) + 0.5f) * _486_fa_cl_grid.y)), 0, _567 - 1)) * _563)) + clamp(int(floor(((_559.x * 0.5f) + 0.5f) * _486_fa_cl_grid.x)), 0, _563 - 1);\n    float4 _638 = fa_light_texel(param);\n    return int2(int(_638.x), int(_638.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_486_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2435 = fa_cluster_lookup(param);\n    fa_cl_slot = _2435.x;\n    fa_cl_local = _2435.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2562 = fa_linear_to_srgb(param);\n        c = _2562;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2570 = fa_srgb_to_linear(param_1);\n            c = _2570;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _241;\n    if (i.front_facing)\n    {\n        _241 = i.world_normal;\n    }\n    else\n    {\n        _241 = -i.world_normal;\n    }\n    float3 _265 = normalize(i.world_tangent.xyz - (_241 * dot(_241, i.world_tangent.xyz)));\n    float3 _293 = normalize(((_265 * m.x) + ((cross(_241, _265) * i.world_tangent.w) * m.y)) + (_241 * m.z));\n    float3 _296;\n    if (i.front_facing)\n    {\n        _296 = _293;\n    }\n    else\n    {\n        _296 = -_293;\n    }\n    return _296;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _486_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2601 = fa_tex_fix(param_2, param_3);\n    float4 _3819 = base_t;\n    _3819.x = _2601.x;\n    _3819.y = _2601.y;\n    _3819.z = _2601.z;\n    base_t = _3819;\n    float4 _2615 = (_3819 * _486_fa_base_color) * i.vertex_color;\n    float3 _3753 = i.world_normal;\n    if (_486_fa_maps.z > 0.5f)\n    {\n        float param_4 = _486_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2647 = fa_tex_fix(param_6, param_7);\n        float3 _2650 = (_2647 * 2.0f) - 1.0f.xxx;\n        float2 _2655 = _2650.xy * _486_fa_maps.x;\n        float3 _3827 = _2650;\n        _3827.x = _2655.x;\n        _3827.y = _2655.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3827;\n        _3753 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _486_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2684 = fa_tex_fix(param_12, param_13);\n    float4 _3830 = mrt;\n    _3830.x = _2684.x;\n    _3830.y = _2684.y;\n    _3830.z = _2684.z;\n    mrt = _3830;\n    float4 _2712 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _486_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2712.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2724 = fa_tex_fix(param_16, param_17);\n    float param_18 = _486_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2754 = fa_tex_fix(param_20, param_21);\n    float _3758 = _486_fa_layers_a.x;\n    float _3759 = _486_fa_layers_a.y;\n    float _3762 = _486_fa_layers_a.z;\n    float _3761 = _486_fa_layers_b.w;\n    float _3764 = _486_fa_layers_c.x;\n    if (_486_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_486_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3758 *= _2724.y;\n            _3759 *= _2724.z;\n            _3761 *= _2712.w;\n        }\n        if (_486_fa_layers_c.z > 1.5f)\n        {\n            _3762 *= mrt.x;\n            _3764 *= mrt.w;\n        }\n    }\n    Surface _3783 = { _2615.xyz, _2615.w, _3753, clamp(_486_fa_pbr.x * _2684.z, 0.0f, 1.0f), clamp(_486_fa_pbr.y * _2684.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_486_fa_maps.y * (_2724.x - 1.0f)), _486_fa_emissive.xyz + (_486_fa_model_emissive.xyz * _2754), _3758, _3759, _486_fa_layers_b.xyz, _3761, _3762, _486_fa_layers_a.w, _3764, _486_fa_layers_c.y, _486_fa_layers_d.xyz };\n    return _3783;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1541 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1549 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1552 = int(_1541);\n    int _1555 = int(_1549);\n    float _1565 = _1549 - float(_1555);\n    int _1621 = (_1552 * 9) + _1555;\n    int _1641 = ((_1552 + 1) * 9) + _1555;\n    return lerp(lerp(_1616[_1621], _1616[_1621 + 1], _1565), lerp(_1616[_1641], _1616[_1641 + 1], _1565), _1541 - float(_1552));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3676 = false;\n    float _3677 = 1.0f;\n    float _3678 = 1.0f;\n    float _3679 = 1.0f;\n    float _3680 = 0.0f;\n    float _3681 = 0.0f;\n    float _3682 = 0.0f;\n    float _3683 = 0.0f;\n    float _3685 = 1.0f;\n    bool _3686 = false;\n    float3 _3687 = 0.0f.xxx;\n    float _3688 = 1.0f;\n    float _3689 = 1.0f;\n    float _3690 = 1.0f;\n    float _3691 = 0.0f;\n    float _3692 = 0.0f;\n    float3 _3693 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3694 = float3(0.0f, 0.0f, 1.0f);\n    float _3695 = 1.0f;\n    float _3696 = 1.0f;\n    float _1696 = clamp(s.specular, 0.0f, 1.0f);\n    float _1700 = clamp(s.ior, 1.0f, 3.0f);\n    bool _1705 = (_1696 != 1.0f) || (_1700 != 1.5f);\n    bool _1715;\n    if (!_1705)\n    {\n        _1715 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _1715 = _1705;\n    }\n    if (_1715)\n    {\n        float _1723 = (_1700 - 1.0f) / (_1700 + 1.0f);\n        f0 = lerp(min((_1723 * _1723).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _1696, s.albedo, metallic.xxx);\n        _3677 = lerp(_1696, 1.0f, metallic);\n        _3676 = true;\n    }\n    float _1751 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_1751 > 0.0f)\n    {\n        float _1759 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3680 = _1751;\n        _3681 = _1759;\n        float _1766 = _1759 * _1759;\n        _3682 = _1766;\n        _3683 = _1766 * _1766;\n        float _1778 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3685 = _1778;\n        _3678 = 1.0f - (_1751 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _1778, 0.0f, 1.0f), 5.0f))));\n        _3676 = true;\n    }\n    float3 _1798 = max(s.sheen_color, 0.0f.xxx);\n    float _1807 = max(_1798.x, max(_1798.y, _1798.z));\n    if (_1807 > 0.0f)\n    {\n        float _1815 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3686 = true;\n        _3687 = _1798;\n        _3688 = _1815;\n        _3689 = _1815 * _1815;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _1815;\n        float _1832 = fa_sheen_albedo(param, param_1);\n        _3691 = _1832;\n        _3690 = 1.0f - min(_1807 * _1832, 1.0f);\n        _3676 = true;\n    }\n    _3679 = _3678 * _3690;\n    float _1851 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1851 != 0.0f)\n    {\n        float3 _1866 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1866;\n        if (dot(_1866, _1866) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1880 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1880.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1880.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1880.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1884 = t;\n        float3 _1885 = normalize(_1884);\n        t = _1885;\n        float3 _1910 = normalize((_1885 * cos(s.anisotropy_rotation)) + ((cross(n, _1885) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3693 = _1910;\n        _3694 = cross(n, _1910);\n        float _1920 = roughness * roughness;\n        float _1926 = lerp(_1920, 1.0f, _1851 * _1851);\n        bool _1928 = _1851 > 0.0f;\n        _3695 = _1928 ? _1926 : _1920;\n        _3696 = _1928 ? _1920 : _1926;\n        _3692 = _1851;\n        _3676 = true;\n    }\n    FaLayers _3718 = { _3676, _3677, _3678, _3679, _3680, _3681, _3682, _3683, i.world_normal, _3685, _3686, _3687, _3688, _3689, _3690, _3691, _3692, _3693, _3694, _3695, _3696 };\n    return _3718;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_486_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _486_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_486_fa_cl_info.x) + int(_486_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _360 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _366 = fa_light_texel(param_1);\n    float _369 = _366.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _375 = _369 < 0.5f;\n    float3 l;\n    if (_375)\n    {\n        l = normalize(_360.xyz);\n    }\n    else\n    {\n        float3 _387 = _360.xyz - world_pos;\n        float _389 = length(_387);\n        dist = _389;\n        l = _387 / max(_389, 9.9999997473787516355514526367188e-05f).xxx;\n        float _404 = _389 / max(_360.w, 0.001000000047497451305389404296875f);\n        float _410 = clamp(1.0f - (_404 * _404), 0.0f, 1.0f);\n        atten = _410 * _410;\n        if (_369 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _424 = fa_light_texel(param_2);\n            float _434 = _424.w;\n            int param_3 = (li * 4) + 3;\n            float4 _440 = fa_light_texel(param_3);\n            float _441 = _440.x;\n            float cos_inner = _441;\n            if (_441 > 1.5f)\n            {\n                cos_inner = lerp(_434, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_434, cos_inner, dot(-l, normalize(_424.xyz)));\n        }\n    }\n    int _472;\n    if (_375)\n    {\n        _472 = 0;\n    }\n    else\n    {\n        _472 = (_369 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3675 = { l, _366.xyz * atten, atten, 1.0f, dist, _472 };\n    return _3675;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _712;\n    if (i == 0)\n    {\n        _712 = _722_fa_shadow_split.x;\n    }\n    else\n    {\n        float _728;\n        if (i == 1)\n        {\n            _728 = _722_fa_shadow_split.y;\n        }\n        else\n        {\n            float _736;\n            if (i == 2)\n            {\n                _736 = _722_fa_shadow_split.z;\n            }\n            else\n            {\n                _736 = _722_fa_shadow_split.w;\n            }\n            _728 = _736;\n        }\n        _712 = _728;\n    }\n    return _712;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _700 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_700), sin(_700)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _774 = max(_722_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _779 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _785 = sqrt(1.0f - (_779 * _779));\n    float _793 = min(_785 / max(_779, 0.20000000298023223876953125f), 4.0f);\n    float _798;\n    if (_722_fa_shadow_bias.y > 0.0f)\n    {\n        _798 = _722_fa_shadow_bias.y;\n    }\n    else\n    {\n        _798 = 1.5f * _722_fa_shadow_info[ci].x;\n    }\n    float4 _823 = mul(float4(world + (n * (_798 * _785)), 1.0f), _722_fa_shadow_mat[ci]);\n    float _830 = _823.x;\n    bool _833 = _830 < _722_fa_shadow_rect[ci].x;\n    bool _842;\n    if (!_833)\n    {\n        _842 = _830 > _722_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _842 = _833;\n    }\n    bool _851;\n    if (!_842)\n    {\n        _851 = _823.y < _722_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _851 = _842;\n    }\n    bool _860;\n    if (!_851)\n    {\n        _860 = _823.y > _722_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _860 = _851;\n    }\n    bool _867;\n    if (!_860)\n    {\n        _867 = _823.z > 1.0f;\n    }\n    else\n    {\n        _867 = _860;\n    }\n    if (_867)\n    {\n        return -1.0f;\n    }\n    float _876;\n    if (_722_fa_shadow_bias.x > 0.0f)\n    {\n        _876 = _722_fa_shadow_bias.x;\n    }\n    else\n    {\n        _876 = 1.5f * _722_fa_shadow_info[ci].x;\n    }\n    float _895 = _823.z - ((_876 * (1.0f + (0.5f * _793))) / _774);\n    float _904 = ((_722_fa_shadow_info[ci].x * min(_793, 3.0f)) * 0.5f) / _774;\n    int _913 = int(_722_fa_shadow_cfg.z + 0.5f);\n    if (_913 == 1)\n    {\n        float2 param = _823.xy;\n        float4 param_1 = _722_fa_shadow_rect[ci];\n        float _924 = fa_shadow_depth(param, param_1);\n        return float(_895 <= _924);\n    }\n    float _931 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _934 = _913 == 2;\n    if (_934)\n    {\n        float _948 = clamp(((_722_fa_shadow_cfg.w * _774) * 0.25f) / _722_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _931;\n            float2 _967 = fa_shadow_vogel(param_2, param_3, param_4) * _948;\n            float2 param_5 = _823.xy + (_967 * _722_fa_shadow_bias.zw);\n            float4 param_6 = _722_fa_shadow_rect[ci];\n            float _978 = fa_shadow_depth(param_5, param_6);\n            if (_978 < (_895 - (length(_967) * _904)))\n            {\n                sum += _978;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_895 - (sum / cnt), 0.0f) * _774) * _722_fa_shadow_cfg.w) / _722_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1022 = _934 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1022; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1022;\n        float param_9 = _931;\n        float2 _1041 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _823.xy + (_1041 * _722_fa_shadow_bias.zw);\n        float4 param_11 = _722_fa_shadow_rect[ci];\n        float _1052 = fa_shadow_depth(param_10, param_11);\n        lit += float((_895 - (length(_1041) * _904)) <= _1052);\n    }\n    return lit / float(_1022);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_486_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1082 = int(_722_fa_shadow_cfg.x + 0.5f);\n    if (_1082 < 1)\n    {\n        return 1.0f;\n    }\n    float _1098 = dot(world - _722_fa_shadow_eye.xyz, _722_fa_shadow_fwd.xyz);\n    int param = _1082 - 1;\n    if (_1098 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1110 = _1082 > 1;\n    bool _1117;\n    if (_1110)\n    {\n        _1117 = _1098 > _722_fa_shadow_split.x;\n    }\n    else\n    {\n        _1117 = _1110;\n    }\n    if (_1117)\n    {\n        ci = 1;\n    }\n    bool _1121 = _1082 > 2;\n    bool _1128;\n    if (_1121)\n    {\n        _1128 = _1098 > _722_fa_shadow_split.y;\n    }\n    else\n    {\n        _1128 = _1121;\n    }\n    if (_1128)\n    {\n        ci = 2;\n    }\n    bool _1132 = _1082 > 3;\n    bool _1139;\n    if (_1132)\n    {\n        _1139 = _1098 > _722_fa_shadow_split.z;\n    }\n    else\n    {\n        _1139 = _1132;\n    }\n    if (_1139)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1082)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1165 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1165;\n        if (_1165 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_722_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1190;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1190 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1190 = _722_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1209 = _722_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1190, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1220 = clamp((_1098 - (fa_shadow_split_at(param_7) - _1209)) / _1209, 0.0f, 1.0f);\n        if (_1220 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1082)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1241 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1241;\n                if (_1241 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1220);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2462 = fa_lm.z > 0.5f;\n    bool _2468;\n    if (_2462)\n    {\n        int param = li;\n        _2468 = fa_light_baked(param);\n    }\n    else\n    {\n        _2468 = _2462;\n    }\n    if (_2468)\n    {\n        int param_1 = li;\n        LightSample _3731 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _3731;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2490 = fa_light_sample(param_2, param_3);\n    float3 _3738 = _2490.direction;\n    float3 _3733 = _2490.color;\n    float _3735 = _2490.shadow;\n    int _3743 = _2490.type;\n    if ((_3743 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3738;\n        float _2504 = fa_shadow_factor(param_4, param_5);\n        _3735 = _2504;\n        _3733 *= _2504;\n    }\n    LightSample _3750 = { _3738, _3733, _2490.attenuation, _3735, _2490._distance, _3743 };\n    return _3750;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2078 = tdh / at;\n    float _2082 = bdh / ab;\n    float _2094 = ((_2078 * _2078) + (_2082 * _2082)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _2094) * _2094);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2175 = 1.0f / alpha;\n    return ((2.0f + _2175) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _2175)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2208 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2287 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _2287) * _2287);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _2208);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _2208));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _2360 = max(dot(L.nc, l), 0.0f);\n        float _2366 = max(dot(L.nc, h), 0.0f);\n        float _2375 = ((_2366 * _2366) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _2375) * _2375)) * (0.5f / max(lerp((2.0f * _2360) * L.coat_ndv, _2360 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2360)) * _2360).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1473 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1476 = _1473.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1476 * _1476, exp2((-9.27999973297119140625f) * ndv)) * _1476) + _1473.y)) + _1473.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_486_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _486_fa_env_horizon.w).xyz;\n    }\n    float _1378 = rough * rough;\n    float _1408 = 0.60000002384185791015625f * _1378;\n    return lerp(lerp(_486_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_486_fa_env_horizon.xyz, _486_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1378)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1408, 0.0500000007450580596923828125f + _1408, d.y).xxx), ((_486_fa_env_sky.xyz + _486_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1378 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1961;\n        if (L.aniso >= 0.0f)\n        {\n            _1961 = L.b;\n        }\n        else\n        {\n            _1961 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1961, v), _1961), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1994 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1994.x) + (L.f90.xxx * _1994.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2049 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2049.x) + _2049.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1515 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1515.x) + _1515.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_722_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1265 = int(_722_fa_shadow_cfg.x + 0.5f);\n    float _1275 = dot(world - _722_fa_shadow_eye.xyz, _722_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1280 = _1265 > 0;\n    bool _1289;\n    if (_1280)\n    {\n        int param = _1265 - 1;\n        _1289 = _1275 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1289 = _1280;\n    }\n    if (_1289)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1296 = _1265 > 1;\n        bool _1303;\n        if (_1296)\n        {\n            _1303 = _1275 > _722_fa_shadow_split.x;\n        }\n        else\n        {\n            _1303 = _1296;\n        }\n        if (_1303)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1309 = _1265 > 2;\n        bool _1316;\n        if (_1309)\n        {\n            _1316 = _1275 > _722_fa_shadow_split.y;\n        }\n        else\n        {\n            _1316 = _1309;\n        }\n        if (_1316)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1322 = _1265 > 3;\n        bool _1329;\n        if (_1322)\n        {\n            _1329 = _1275 > _722_fa_shadow_split.z;\n        }\n        else\n        {\n            _1329 = _1322;\n        }\n        if (_1329)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3455 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3455 = -_3455;\n    }\n    float3 _2894 = normalize(_486_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3468 = { fa_world_pos, _3455, fa_world_tangent, fa_uv, fa_vertex_color, _2894, gl_FrontFacing };\n    SurfaceInput param_1 = _3468;\n    Surface _2902 = fa_standard_surface(param_1);\n    float3 _3486 = _2902.albedo;\n    float _3487 = _2902.alpha;\n    float3 _3488 = _2902.normal;\n    float _3489 = _2902.metallic;\n    float _3490 = _2902.roughness;\n    float _3491 = _2902.occlusion;\n    float3 _3492 = _2902.emission;\n    float _3493 = _2902.clearcoat;\n    float _3494 = _2902.clearcoat_roughness;\n    float3 _3495 = _2902.sheen_color;\n    float _3496 = _2902.sheen_roughness;\n    float _3497 = _2902.anisotropy;\n    float _3498 = _2902.anisotropy_rotation;\n    float _3499 = _2902.specular;\n    float _3500 = _2902.ior;\n    float3 _3501 = _2902.specular_color;\n    SurfaceInput _3476 = { fa_world_pos, _3455, fa_world_tangent, fa_uv, fa_vertex_color, _2894, gl_FrontFacing };\n    SurfaceInput param_2 = _3476;\n    Surface param_3 = _2902;\n    surface(param_2, param_3);\n    _3486 = param_3.albedo;\n    _3487 = param_3.alpha;\n    _3488 = param_3.normal;\n    _3489 = param_3.metallic;\n    _3490 = param_3.roughness;\n    _3491 = param_3.occlusion;\n    _3492 = param_3.emission;\n    _3493 = param_3.clearcoat;\n    _3494 = param_3.clearcoat_roughness;\n    _3495 = param_3.sheen_color;\n    _3496 = param_3.sheen_roughness;\n    _3497 = param_3.anisotropy;\n    _3498 = param_3.anisotropy_rotation;\n    _3499 = param_3.specular;\n    _3500 = param_3.ior;\n    _3501 = param_3.specular_color;\n    float3 result;\n    if (_486_fa_emissive.w > 0.5f)\n    {\n        result = _3486;\n    }\n    else\n    {\n        float3 _2924 = normalize(_3488);\n        float _2931 = clamp(_3489, 0.0f, 1.0f);\n        float _2935 = clamp(_3490, 0.0500000007450580596923828125f, 1.0f);\n        float _2939 = _2935 * _2935;\n        float _2943 = _2939 * _2939;\n        float _2948 = max(dot(_2924, _2894), 9.9999997473787516355514526367188e-05f);\n        float3 _2954 = _3486 * (1.0f - _2931);\n        float3 _2961 = lerp(0.039999999105930328369140625f.xxx, _3486, _2931.xxx);\n        float3 f0 = _2961;\n        SurfaceInput _3484 = { fa_world_pos, _3455, fa_world_tangent, fa_uv, fa_vertex_color, _2894, gl_FrontFacing };\n        SurfaceInput param_4 = _3484;\n        Surface _3567 = { _3486, _3487, _3488, _3489, _3490, _3491, _3492, _3493, _3494, _3495, _3496, _3497, _3498, _3499, _3500, _3501 };\n        Surface param_5 = _3567;\n        float3 param_6 = _2924;\n        float3 param_7 = _2894;\n        float param_8 = _2931;\n        float param_9 = _2935;\n        float3 param_10 = _2961;\n        FaLayers _2977 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _2924;\n        float3 lit = (fa_indirect_diffuse(param_11) * _2954) * _3491;\n        if (_2977.on)\n        {\n            lit *= _2977.base_scale;\n        }\n        int _2999 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2999; ln++)\n        {\n            int param_12 = ln;\n            int _3012 = fa_cl_light(param_12);\n            bool _3015 = fa_lm.z > 0.5f;\n            bool _3021;\n            if (_3015)\n            {\n                int param_13 = _3012;\n                _3021 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3021 = _3015;\n            }\n            if (_3021)\n            {\n                continue;\n            }\n            int param_14 = _3012;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _3455;\n            LightSample _3033 = fa_light_shadowed(param_14, param_15, param_16);\n            float3 _3660 = _3033.direction;\n            float _3041 = max(dot(_2924, _3660), 0.0f);\n            float _3047 = _3033.attenuation * _3033.shadow;\n            float3 _3052 = normalize(_3660 + _2894);\n            float _3057 = max(dot(_2924, _3052), 0.0f);\n            float _3062 = max(dot(_2894, _3052), 0.0f);\n            if (_2977.on)\n            {\n                FaLayers param_17 = _2977;\n                float3 param_18 = _2954;\n                float3 param_19 = f0;\n                float3 param_20 = _2924;\n                float3 param_21 = _2894;\n                float3 param_22 = _3660;\n                float3 param_23 = _3052;\n                float param_24 = _3041;\n                float param_25 = _2948;\n                float param_26 = _3057;\n                float param_27 = _3062;\n                float param_28 = _2939;\n                float param_29 = _2943;\n                int param_30 = _3012;\n                lit += (fa_layers_light(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29) * (fa_light_rgb(param_30) * _3047));\n            }\n            else\n            {\n                float _3110 = ((_3057 * _3057) * (_2943 - 1.0f)) + 1.0f;\n                int param_31 = _3012;\n                lit += (((_2954 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _3062, 5.0f))) * (((_2943 / ((3.1415927410125732421875f * _3110) * _3110)) * (0.5f / max(lerp((2.0f * _3041) * _2948, _3041 + _2948, _2939), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _3041))) * fa_light_rgb(param_31)) * (_3041 * _3047));\n            }\n        }\n        if (_2977.on)\n        {\n            FaLayers param_32 = _2977;\n            float3 param_33 = _2924;\n            float3 param_34 = _2894;\n            float3 param_35 = f0;\n            float param_36 = _2935;\n            lit += (fa_layers_ibl(param_32, param_33, param_34, param_35, param_36) * _3491);\n        }\n        else\n        {\n            float3 param_37 = _2924;\n            float3 param_38 = _2894;\n            float3 param_39 = f0;\n            float param_40 = _2935;\n            lit += (fa_sky_reflection(param_37, param_38, param_39, param_40) * _3491);\n        }\n        result = lit;\n    }\n    float3 _3203 = result;\n    float3 _3204 = _3203 + _3492;\n    result = _3204;\n    float3 param_41 = _3204;\n    float3 param_42 = fa_world_pos;\n    result = fa_shadow_debug(param_41, param_42);\n    bool _3213 = _486_fa_fog.w > 0.0f;\n    bool _3220;\n    if (!_3213)\n    {\n        _3220 = _486_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3220 = _3213;\n    }\n    if (_3220)\n    {\n        float3 _3229 = fa_world_pos - _486_fa_camera_pos.xyz;\n        float _3235 = dot(_3229, _486_fa_fog_c.xyz);\n        bool _3239 = _486_fa_fog_c.w > 0.5f;\n        float _3240;\n        if (_3239)\n        {\n            _3240 = _3235;\n        }\n        else\n        {\n            _3240 = length(_3229);\n        }\n        float _3252 = _3240 - _486_fa_fog_b.x;\n        if (_3252 > 0.0f)\n        {\n            float _3261 = _486_fa_fog.w * _3252;\n            float tau = _3261 * _3261;\n            if (_486_fa_fog_b.y > 0.0f)\n            {\n                float _3277;\n                if (_3239)\n                {\n                    _3277 = fa_world_pos.y - (_486_fa_fog_c.y * _3235);\n                }\n                else\n                {\n                    _3277 = _486_fa_camera_pos.y;\n                }\n                float _3298 = lerp(_3277, fa_world_pos.y, clamp(_486_fa_fog_b.x / _3240, 0.0f, 1.0f));\n                float _3302 = fa_world_pos.y - _3298;\n                float _3307 = _3298 - _486_fa_fog_b.z;\n                float _3312 = fa_world_pos.y - _486_fa_fog_b.z;\n                bool _3315 = _3307 <= 0.0f;\n                bool _3316 = !_3315;\n                bool _3322;\n                if (_3316)\n                {\n                    _3322 = _486_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3322 = _3315;\n                }\n                float _3323;\n                if (_3322)\n                {\n                    _3323 = _486_fa_fog_b.y;\n                }\n                else\n                {\n                    _3323 = _486_fa_fog_b.y * exp(-min(_486_fa_fog_b.w * _3307, 80.0f));\n                }\n                bool _3350;\n                if (_3316)\n                {\n                    _3350 = _486_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3350 = _3315;\n                }\n                float _3351;\n                if (_3350)\n                {\n                    _3351 = _486_fa_fog_b.y * _3307;\n                }\n                else\n                {\n                    _3351 = (_486_fa_fog_b.y * (1.0f - exp(-min(_486_fa_fog_b.w * _3307, 80.0f)))) / _486_fa_fog_b.w;\n                }\n                bool _3376 = _3312 <= 0.0f;\n                bool _3383;\n                if (!_3376)\n                {\n                    _3383 = _486_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3383 = _3376;\n                }\n                float _3384;\n                if (_3383)\n                {\n                    _3384 = _486_fa_fog_b.y * _3312;\n                }\n                else\n                {\n                    _3384 = (_486_fa_fog_b.y * (1.0f - exp(-min(_486_fa_fog_b.w * _3312, 80.0f)))) / _486_fa_fog_b.w;\n                }\n                float _3411;\n                if (abs(_3302) < 0.001000000047497451305389404296875f)\n                {\n                    _3411 = _3323;\n                }\n                else\n                {\n                    _3411 = (_3384 - _3351) / _3302;\n                }\n                tau += (_3252 * max(_3411, 0.0f));\n            }\n            result = lerp(result, _486_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3487);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_45",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_145",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_486",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_722",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 9,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _50_offset : packoffset(c0);\n    float _50_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _150_fa_view_proj : packoffset(c0);\n    row_major float4x4 _150_fa_light_vp : packoffset(c4);\n    float4 _150_fa_uv_scale : packoffset(c8);\n    float4 _150_fa_time : packoffset(c9);\n    float4 _150_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _197_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _188 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_197_fa_joint_rows[_188] * weights[i]);\n        r1 += (_197_fa_joint_rows[_188 + 1] * weights[i]);\n        r2 += (_197_fa_joint_rows[_188 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _399 = { mul(float4(position, 1.0f), model).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _150_fa_uv_scale.xy, color, position };\n    return _399;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _50_offset;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _150_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1616[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _486_fa_camera_pos : packoffset(c0);\n    float4 _486_fa_ambient : packoffset(c1);\n    float4 _486_fa_base_color : packoffset(c2);\n    float4 _486_fa_emissive : packoffset(c3);\n    float4 _486_fa_model_emissive : packoffset(c4);\n    float4 _486_fa_pbr : packoffset(c5);\n    float4 _486_fa_maps : packoffset(c6);\n    float4 _486_fa_fog : packoffset(c7);\n    float4 _486_fa_fog_b : packoffset(c8);\n    float4 _486_fa_fog_c : packoffset(c9);\n    float4 _486_fa_counts : packoffset(c10);\n    float4 _486_fa_env_sky : packoffset(c11);\n    float4 _486_fa_env_horizon : packoffset(c12);\n    float4 _486_fa_time : packoffset(c13);\n    float4 _486_fa_cl_vpx : packoffset(c14);\n    float4 _486_fa_cl_vpy : packoffset(c15);\n    float4 _486_fa_cl_vpw : packoffset(c16);\n    float4 _486_fa_cl_fwd : packoffset(c17);\n    float4 _486_fa_cl_grid : packoffset(c18);\n    float4 _486_fa_cl_info : packoffset(c19);\n    float4 _486_fa_layers_a : packoffset(c20);\n    float4 _486_fa_layers_b : packoffset(c21);\n    float4 _486_fa_layers_c : packoffset(c22);\n    float4 _486_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _722_fa_shadow_mat[4] : packoffset(c0);\n    float4 _722_fa_shadow_rect[4] : packoffset(c16);\n    float4 _722_fa_shadow_info[4] : packoffset(c20);\n    float4 _722_fa_shadow_split : packoffset(c24);\n    float4 _722_fa_shadow_cfg : packoffset(c25);\n    float4 _722_fa_shadow_bias : packoffset(c26);\n    float4 _722_fa_shadow_eye : packoffset(c27);\n    float4 _722_fa_shadow_fwd : packoffset(c28);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _491 = _486_fa_cl_info.x < 0.0f;\n    bool _498;\n    if (!_491)\n    {\n        _498 = _486_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _498 = _491;\n    }\n    bool _506;\n    if (!_498)\n    {\n        _506 = _486_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _506 = _498;\n    }\n    bool _513;\n    if (!_506)\n    {\n        _513 = _486_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _513 = _506;\n    }\n    bool _520;\n    if (!_513)\n    {\n        _520 = _486_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _520 = _513;\n    }\n    if (_520)\n    {\n        return int2(0, 0);\n    }\n    float4 _530 = float4(world_pos, 1.0f);\n    float _537 = dot(_486_fa_cl_vpw, _530);\n    if (!(_537 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _559 = float2(dot(_486_fa_cl_vpx, _530), dot(_486_fa_cl_vpy, _530)) / _537.xx;\n    int _563 = int(_486_fa_cl_grid.x);\n    int _567 = int(_486_fa_cl_grid.y);\n    int param = (int(_486_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_486_fa_cl_fwd.xyz, world_pos) + _486_fa_cl_fwd.w, _486_fa_cl_grid.w) / _486_fa_cl_grid.w) * _486_fa_cl_grid.z)), 0, int(_486_fa_cl_info.y) - 1) * _567) + clamp(int(floor(((_559.y * 0.5f) + 0.5f) * _486_fa_cl_grid.y)), 0, _567 - 1)) * _563)) + clamp(int(floor(((_559.x * 0.5f) + 0.5f) * _486_fa_cl_grid.x)), 0, _563 - 1);\n    float4 _638 = fa_light_texel(param);\n    return int2(int(_638.x), int(_638.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_486_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2435 = fa_cluster_lookup(param);\n    fa_cl_slot = _2435.x;\n    fa_cl_local = _2435.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2562 = fa_linear_to_srgb(param);\n        c = _2562;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2570 = fa_srgb_to_linear(param_1);\n            c = _2570;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _241;\n    if (i.front_facing)\n    {\n        _241 = i.world_normal;\n    }\n    else\n    {\n        _241 = -i.world_normal;\n    }\n    float3 _265 = normalize(i.world_tangent.xyz - (_241 * dot(_241, i.world_tangent.xyz)));\n    float3 _293 = normalize(((_265 * m.x) + ((cross(_241, _265) * i.world_tangent.w) * m.y)) + (_241 * m.z));\n    float3 _296;\n    if (i.front_facing)\n    {\n        _296 = _293;\n    }\n    else\n    {\n        _296 = -_293;\n    }\n    return _296;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _486_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2601 = fa_tex_fix(param_2, param_3);\n    float4 _3819 = base_t;\n    _3819.x = _2601.x;\n    _3819.y = _2601.y;\n    _3819.z = _2601.z;\n    base_t = _3819;\n    float4 _2615 = (_3819 * _486_fa_base_color) * i.vertex_color;\n    float3 _3753 = i.world_normal;\n    if (_486_fa_maps.z > 0.5f)\n    {\n        float param_4 = _486_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2647 = fa_tex_fix(param_6, param_7);\n        float3 _2650 = (_2647 * 2.0f) - 1.0f.xxx;\n        float2 _2655 = _2650.xy * _486_fa_maps.x;\n        float3 _3827 = _2650;\n        _3827.x = _2655.x;\n        _3827.y = _2655.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3827;\n        _3753 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _486_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2684 = fa_tex_fix(param_12, param_13);\n    float4 _3830 = mrt;\n    _3830.x = _2684.x;\n    _3830.y = _2684.y;\n    _3830.z = _2684.z;\n    mrt = _3830;\n    float4 _2712 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _486_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2712.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2724 = fa_tex_fix(param_16, param_17);\n    float param_18 = _486_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2754 = fa_tex_fix(param_20, param_21);\n    float _3758 = _486_fa_layers_a.x;\n    float _3759 = _486_fa_layers_a.y;\n    float _3762 = _486_fa_layers_a.z;\n    float _3761 = _486_fa_layers_b.w;\n    float _3764 = _486_fa_layers_c.x;\n    if (_486_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_486_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3758 *= _2724.y;\n            _3759 *= _2724.z;\n            _3761 *= _2712.w;\n        }\n        if (_486_fa_layers_c.z > 1.5f)\n        {\n            _3762 *= mrt.x;\n            _3764 *= mrt.w;\n        }\n    }\n    Surface _3783 = { _2615.xyz, _2615.w, _3753, clamp(_486_fa_pbr.x * _2684.z, 0.0f, 1.0f), clamp(_486_fa_pbr.y * _2684.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_486_fa_maps.y * (_2724.x - 1.0f)), _486_fa_emissive.xyz + (_486_fa_model_emissive.xyz * _2754), _3758, _3759, _486_fa_layers_b.xyz, _3761, _3762, _486_fa_layers_a.w, _3764, _486_fa_layers_c.y, _486_fa_layers_d.xyz };\n    return _3783;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1541 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1549 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1552 = int(_1541);\n    int _1555 = int(_1549);\n    float _1565 = _1549 - float(_1555);\n    int _1621 = (_1552 * 9) + _1555;\n    int _1641 = ((_1552 + 1) * 9) + _1555;\n    return lerp(lerp(_1616[_1621], _1616[_1621 + 1], _1565), lerp(_1616[_1641], _1616[_1641 + 1], _1565), _1541 - float(_1552));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3676 = false;\n    float _3677 = 1.0f;\n    float _3678 = 1.0f;\n    float _3679 = 1.0f;\n    float _3680 = 0.0f;\n    float _3681 = 0.0f;\n    float _3682 = 0.0f;\n    float _3683 = 0.0f;\n    float _3685 = 1.0f;\n    bool _3686 = false;\n    float3 _3687 = 0.0f.xxx;\n    float _3688 = 1.0f;\n    float _3689 = 1.0f;\n    float _3690 = 1.0f;\n    float _3691 = 0.0f;\n    float _3692 = 0.0f;\n    float3 _3693 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3694 = float3(0.0f, 0.0f, 1.0f);\n    float _3695 = 1.0f;\n    float _3696 = 1.0f;\n    float _1696 = clamp(s.specular, 0.0f, 1.0f);\n    float _1700 = clamp(s.ior, 1.0f, 3.0f);\n    bool _1705 = (_1696 != 1.0f) || (_1700 != 1.5f);\n    bool _1715;\n    if (!_1705)\n    {\n        _1715 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _1715 = _1705;\n    }\n    if (_1715)\n    {\n        float _1723 = (_1700 - 1.0f) / (_1700 + 1.0f);\n        f0 = lerp(min((_1723 * _1723).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _1696, s.albedo, metallic.xxx);\n        _3677 = lerp(_1696, 1.0f, metallic);\n        _3676 = true;\n    }\n    float _1751 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_1751 > 0.0f)\n    {\n        float _1759 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3680 = _1751;\n        _3681 = _1759;\n        float _1766 = _1759 * _1759;\n        _3682 = _1766;\n        _3683 = _1766 * _1766;\n        float _1778 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3685 = _1778;\n        _3678 = 1.0f - (_1751 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _1778, 0.0f, 1.0f), 5.0f))));\n        _3676 = true;\n    }\n    float3 _1798 = max(s.sheen_color, 0.0f.xxx);\n    float _1807 = max(_1798.x, max(_1798.y, _1798.z));\n    if (_1807 > 0.0f)\n    {\n        float _1815 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3686 = true;\n        _3687 = _1798;\n        _3688 = _1815;\n        _3689 = _1815 * _1815;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _1815;\n        float _1832 = fa_sheen_albedo(param, param_1);\n        _3691 = _1832;\n        _3690 = 1.0f - min(_1807 * _1832, 1.0f);\n        _3676 = true;\n    }\n    _3679 = _3678 * _3690;\n    float _1851 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_1851 != 0.0f)\n    {\n        float3 _1866 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1866;\n        if (dot(_1866, _1866) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _1880 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_1880.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _1880.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _1880.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _1884 = t;\n        float3 _1885 = normalize(_1884);\n        t = _1885;\n        float3 _1910 = normalize((_1885 * cos(s.anisotropy_rotation)) + ((cross(n, _1885) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3693 = _1910;\n        _3694 = cross(n, _1910);\n        float _1920 = roughness * roughness;\n        float _1926 = lerp(_1920, 1.0f, _1851 * _1851);\n        bool _1928 = _1851 > 0.0f;\n        _3695 = _1928 ? _1926 : _1920;\n        _3696 = _1928 ? _1920 : _1926;\n        _3692 = _1851;\n        _3676 = true;\n    }\n    FaLayers _3718 = { _3676, _3677, _3678, _3679, _3680, _3681, _3682, _3683, i.world_normal, _3685, _3686, _3687, _3688, _3689, _3690, _3691, _3692, _3693, _3694, _3695, _3696 };\n    return _3718;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_486_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _486_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_486_fa_cl_info.x) + int(_486_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _360 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _366 = fa_light_texel(param_1);\n    float _369 = _366.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _375 = _369 < 0.5f;\n    float3 l;\n    if (_375)\n    {\n        l = normalize(_360.xyz);\n    }\n    else\n    {\n        float3 _387 = _360.xyz - world_pos;\n        float _389 = length(_387);\n        dist = _389;\n        l = _387 / max(_389, 9.9999997473787516355514526367188e-05f).xxx;\n        float _404 = _389 / max(_360.w, 0.001000000047497451305389404296875f);\n        float _410 = clamp(1.0f - (_404 * _404), 0.0f, 1.0f);\n        atten = _410 * _410;\n        if (_369 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _424 = fa_light_texel(param_2);\n            float _434 = _424.w;\n            int param_3 = (li * 4) + 3;\n            float4 _440 = fa_light_texel(param_3);\n            float _441 = _440.x;\n            float cos_inner = _441;\n            if (_441 > 1.5f)\n            {\n                cos_inner = lerp(_434, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_434, cos_inner, dot(-l, normalize(_424.xyz)));\n        }\n    }\n    int _472;\n    if (_375)\n    {\n        _472 = 0;\n    }\n    else\n    {\n        _472 = (_369 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3675 = { l, _366.xyz * atten, atten, 1.0f, dist, _472 };\n    return _3675;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _712;\n    if (i == 0)\n    {\n        _712 = _722_fa_shadow_split.x;\n    }\n    else\n    {\n        float _728;\n        if (i == 1)\n        {\n            _728 = _722_fa_shadow_split.y;\n        }\n        else\n        {\n            float _736;\n            if (i == 2)\n            {\n                _736 = _722_fa_shadow_split.z;\n            }\n            else\n            {\n                _736 = _722_fa_shadow_split.w;\n            }\n            _728 = _736;\n        }\n        _712 = _728;\n    }\n    return _712;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _700 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_700), sin(_700)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _774 = max(_722_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _779 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _785 = sqrt(1.0f - (_779 * _779));\n    float _793 = min(_785 / max(_779, 0.20000000298023223876953125f), 4.0f);\n    float _798;\n    if (_722_fa_shadow_bias.y > 0.0f)\n    {\n        _798 = _722_fa_shadow_bias.y;\n    }\n    else\n    {\n        _798 = 1.5f * _722_fa_shadow_info[ci].x;\n    }\n    float4 _823 = mul(float4(world + (n * (_798 * _785)), 1.0f), _722_fa_shadow_mat[ci]);\n    float _830 = _823.x;\n    bool _833 = _830 < _722_fa_shadow_rect[ci].x;\n    bool _842;\n    if (!_833)\n    {\n        _842 = _830 > _722_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _842 = _833;\n    }\n    bool _851;\n    if (!_842)\n    {\n        _851 = _823.y < _722_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _851 = _842;\n    }\n    bool _860;\n    if (!_851)\n    {\n        _860 = _823.y > _722_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _860 = _851;\n    }\n    bool _867;\n    if (!_860)\n    {\n        _867 = _823.z > 1.0f;\n    }\n    else\n    {\n        _867 = _860;\n    }\n    if (_867)\n    {\n        return -1.0f;\n    }\n    float _876;\n    if (_722_fa_shadow_bias.x > 0.0f)\n    {\n        _876 = _722_fa_shadow_bias.x;\n    }\n    else\n    {\n        _876 = 1.5f * _722_fa_shadow_info[ci].x;\n    }\n    float _895 = _823.z - ((_876 * (1.0f + (0.5f * _793))) / _774);\n    float _904 = ((_722_fa_shadow_info[ci].x * min(_793, 3.0f)) * 0.5f) / _774;\n    int _913 = int(_722_fa_shadow_cfg.z + 0.5f);\n    if (_913 == 1)\n    {\n        float2 param = _823.xy;\n        float4 param_1 = _722_fa_shadow_rect[ci];\n        float _924 = fa_shadow_depth(param, param_1);\n        return float(_895 <= _924);\n    }\n    float _931 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _934 = _913 == 2;\n    if (_934)\n    {\n        float _948 = clamp(((_722_fa_shadow_cfg.w * _774) * 0.25f) / _722_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _931;\n            float2 _967 = fa_shadow_vogel(param_2, param_3, param_4) * _948;\n            float2 param_5 = _823.xy + (_967 * _722_fa_shadow_bias.zw);\n            float4 param_6 = _722_fa_shadow_rect[ci];\n            float _978 = fa_shadow_depth(param_5, param_6);\n            if (_978 < (_895 - (length(_967) * _904)))\n            {\n                sum += _978;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_895 - (sum / cnt), 0.0f) * _774) * _722_fa_shadow_cfg.w) / _722_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1022 = _934 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1022; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1022;\n        float param_9 = _931;\n        float2 _1041 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _823.xy + (_1041 * _722_fa_shadow_bias.zw);\n        float4 param_11 = _722_fa_shadow_rect[ci];\n        float _1052 = fa_shadow_depth(param_10, param_11);\n        lit += float((_895 - (length(_1041) * _904)) <= _1052);\n    }\n    return lit / float(_1022);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_486_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1082 = int(_722_fa_shadow_cfg.x + 0.5f);\n    if (_1082 < 1)\n    {\n        return 1.0f;\n    }\n    float _1098 = dot(world - _722_fa_shadow_eye.xyz, _722_fa_shadow_fwd.xyz);\n    int param = _1082 - 1;\n    if (_1098 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1110 = _1082 > 1;\n    bool _1117;\n    if (_1110)\n    {\n        _1117 = _1098 > _722_fa_shadow_split.x;\n    }\n    else\n    {\n        _1117 = _1110;\n    }\n    if (_1117)\n    {\n        ci = 1;\n    }\n    bool _1121 = _1082 > 2;\n    bool _1128;\n    if (_1121)\n    {\n        _1128 = _1098 > _722_fa_shadow_split.y;\n    }\n    else\n    {\n        _1128 = _1121;\n    }\n    if (_1128)\n    {\n        ci = 2;\n    }\n    bool _1132 = _1082 > 3;\n    bool _1139;\n    if (_1132)\n    {\n        _1139 = _1098 > _722_fa_shadow_split.z;\n    }\n    else\n    {\n        _1139 = _1132;\n    }\n    if (_1139)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1082)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1165 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1165;\n        if (_1165 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_722_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1190;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1190 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1190 = _722_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1209 = _722_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1190, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1220 = clamp((_1098 - (fa_shadow_split_at(param_7) - _1209)) / _1209, 0.0f, 1.0f);\n        if (_1220 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1082)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1241 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1241;\n                if (_1241 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1220);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2462 = fa_lm.z > 0.5f;\n    bool _2468;\n    if (_2462)\n    {\n        int param = li;\n        _2468 = fa_light_baked(param);\n    }\n    else\n    {\n        _2468 = _2462;\n    }\n    if (_2468)\n    {\n        int param_1 = li;\n        LightSample _3731 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _3731;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2490 = fa_light_sample(param_2, param_3);\n    float3 _3738 = _2490.direction;\n    float3 _3733 = _2490.color;\n    float _3735 = _2490.shadow;\n    int _3743 = _2490.type;\n    if ((_3743 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3738;\n        float _2504 = fa_shadow_factor(param_4, param_5);\n        _3735 = _2504;\n        _3733 *= _2504;\n    }\n    LightSample _3750 = { _3738, _3733, _2490.attenuation, _3735, _2490._distance, _3743 };\n    return _3750;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2078 = tdh / at;\n    float _2082 = bdh / ab;\n    float _2094 = ((_2078 * _2078) + (_2082 * _2082)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _2094) * _2094);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2175 = 1.0f / alpha;\n    return ((2.0f + _2175) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _2175)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2208 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2287 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _2287) * _2287);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _2208);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _2208));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _2360 = max(dot(L.nc, l), 0.0f);\n        float _2366 = max(dot(L.nc, h), 0.0f);\n        float _2375 = ((_2366 * _2366) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _2375) * _2375)) * (0.5f / max(lerp((2.0f * _2360) * L.coat_ndv, _2360 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2360)) * _2360).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1473 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1476 = _1473.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1476 * _1476, exp2((-9.27999973297119140625f) * ndv)) * _1476) + _1473.y)) + _1473.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_486_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _486_fa_env_horizon.w).xyz;\n    }\n    float _1378 = rough * rough;\n    float _1408 = 0.60000002384185791015625f * _1378;\n    return lerp(lerp(_486_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_486_fa_env_horizon.xyz, _486_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1378)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1408, 0.0500000007450580596923828125f + _1408, d.y).xxx), ((_486_fa_env_sky.xyz + _486_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1378 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _1961;\n        if (L.aniso >= 0.0f)\n        {\n            _1961 = L.b;\n        }\n        else\n        {\n            _1961 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_1961, v), _1961), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1994 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _1994.x) + (L.f90.xxx * _1994.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2049 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2049.x) + _2049.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1515 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1515.x) + _1515.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_722_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1265 = int(_722_fa_shadow_cfg.x + 0.5f);\n    float _1275 = dot(world - _722_fa_shadow_eye.xyz, _722_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1280 = _1265 > 0;\n    bool _1289;\n    if (_1280)\n    {\n        int param = _1265 - 1;\n        _1289 = _1275 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1289 = _1280;\n    }\n    if (_1289)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1296 = _1265 > 1;\n        bool _1303;\n        if (_1296)\n        {\n            _1303 = _1275 > _722_fa_shadow_split.x;\n        }\n        else\n        {\n            _1303 = _1296;\n        }\n        if (_1303)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1309 = _1265 > 2;\n        bool _1316;\n        if (_1309)\n        {\n            _1316 = _1275 > _722_fa_shadow_split.y;\n        }\n        else\n        {\n            _1316 = _1309;\n        }\n        if (_1316)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1322 = _1265 > 3;\n        bool _1329;\n        if (_1322)\n        {\n            _1329 = _1275 > _722_fa_shadow_split.z;\n        }\n        else\n        {\n            _1329 = _1322;\n        }\n        if (_1329)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3455 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3455 = -_3455;\n    }\n    float3 _2894 = normalize(_486_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3468 = { fa_world_pos, _3455, fa_world_tangent, fa_uv, fa_vertex_color, _2894, gl_FrontFacing };\n    SurfaceInput param_1 = _3468;\n    Surface _2902 = fa_standard_surface(param_1);\n    float3 _3486 = _2902.albedo;\n    float _3487 = _2902.alpha;\n    float3 _3488 = _2902.normal;\n    float _3489 = _2902.metallic;\n    float _3490 = _2902.roughness;\n    float _3491 = _2902.occlusion;\n    float3 _3492 = _2902.emission;\n    float _3493 = _2902.clearcoat;\n    float _3494 = _2902.clearcoat_roughness;\n    float3 _3495 = _2902.sheen_color;\n    float _3496 = _2902.sheen_roughness;\n    float _3497 = _2902.anisotropy;\n    float _3498 = _2902.anisotropy_rotation;\n    float _3499 = _2902.specular;\n    float _3500 = _2902.ior;\n    float3 _3501 = _2902.specular_color;\n    SurfaceInput _3476 = { fa_world_pos, _3455, fa_world_tangent, fa_uv, fa_vertex_color, _2894, gl_FrontFacing };\n    SurfaceInput param_2 = _3476;\n    Surface param_3 = _2902;\n    surface(param_2, param_3);\n    _3486 = param_3.albedo;\n    _3487 = param_3.alpha;\n    _3488 = param_3.normal;\n    _3489 = param_3.metallic;\n    _3490 = param_3.roughness;\n    _3491 = param_3.occlusion;\n    _3492 = param_3.emission;\n    _3493 = param_3.clearcoat;\n    _3494 = param_3.clearcoat_roughness;\n    _3495 = param_3.sheen_color;\n    _3496 = param_3.sheen_roughness;\n    _3497 = param_3.anisotropy;\n    _3498 = param_3.anisotropy_rotation;\n    _3499 = param_3.specular;\n    _3500 = param_3.ior;\n    _3501 = param_3.specular_color;\n    float3 result;\n    if (_486_fa_emissive.w > 0.5f)\n    {\n        result = _3486;\n    }\n    else\n    {\n        float3 _2924 = normalize(_3488);\n        float _2931 = clamp(_3489, 0.0f, 1.0f);\n        float _2935 = clamp(_3490, 0.0500000007450580596923828125f, 1.0f);\n        float _2939 = _2935 * _2935;\n        float _2943 = _2939 * _2939;\n        float _2948 = max(dot(_2924, _2894), 9.9999997473787516355514526367188e-05f);\n        float3 _2954 = _3486 * (1.0f - _2931);\n        float3 _2961 = lerp(0.039999999105930328369140625f.xxx, _3486, _2931.xxx);\n        float3 f0 = _2961;\n        SurfaceInput _3484 = { fa_world_pos, _3455, fa_world_tangent, fa_uv, fa_vertex_color, _2894, gl_FrontFacing };\n        SurfaceInput param_4 = _3484;\n        Surface _3567 = { _3486, _3487, _3488, _3489, _3490, _3491, _3492, _3493, _3494, _3495, _3496, _3497, _3498, _3499, _3500, _3501 };\n        Surface param_5 = _3567;\n        float3 param_6 = _2924;\n        float3 param_7 = _2894;\n        float param_8 = _2931;\n        float param_9 = _2935;\n        float3 param_10 = _2961;\n        FaLayers _2977 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _2924;\n        float3 lit = (fa_indirect_diffuse(param_11) * _2954) * _3491;\n        if (_2977.on)\n        {\n            lit *= _2977.base_scale;\n        }\n        int _2999 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2999; ln++)\n        {\n            int param_12 = ln;\n            int _3012 = fa_cl_light(param_12);\n            bool _3015 = fa_lm.z > 0.5f;\n            bool _3021;\n            if (_3015)\n            {\n                int param_13 = _3012;\n                _3021 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3021 = _3015;\n            }\n            if (_3021)\n            {\n                continue;\n            }\n            int param_14 = _3012;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _3455;\n            LightSample _3033 = fa_light_shadowed(param_14, param_15, param_16);\n            float3 _3660 = _3033.direction;\n            float _3041 = max(dot(_2924, _3660), 0.0f);\n            float _3047 = _3033.attenuation * _3033.shadow;\n            float3 _3052 = normalize(_3660 + _2894);\n            float _3057 = max(dot(_2924, _3052), 0.0f);\n            float _3062 = max(dot(_2894, _3052), 0.0f);\n            if (_2977.on)\n            {\n                FaLayers param_17 = _2977;\n                float3 param_18 = _2954;\n                float3 param_19 = f0;\n                float3 param_20 = _2924;\n                float3 param_21 = _2894;\n                float3 param_22 = _3660;\n                float3 param_23 = _3052;\n                float param_24 = _3041;\n                float param_25 = _2948;\n                float param_26 = _3057;\n                float param_27 = _3062;\n                float param_28 = _2939;\n                float param_29 = _2943;\n                int param_30 = _3012;\n                lit += (fa_layers_light(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29) * (fa_light_rgb(param_30) * _3047));\n            }\n            else\n            {\n                float _3110 = ((_3057 * _3057) * (_2943 - 1.0f)) + 1.0f;\n                int param_31 = _3012;\n                lit += (((_2954 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _3062, 5.0f))) * (((_2943 / ((3.1415927410125732421875f * _3110) * _3110)) * (0.5f / max(lerp((2.0f * _3041) * _2948, _3041 + _2948, _2939), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _3041))) * fa_light_rgb(param_31)) * (_3041 * _3047));\n            }\n        }\n        if (_2977.on)\n        {\n            FaLayers param_32 = _2977;\n            float3 param_33 = _2924;\n            float3 param_34 = _2894;\n            float3 param_35 = f0;\n            float param_36 = _2935;\n            lit += (fa_layers_ibl(param_32, param_33, param_34, param_35, param_36) * _3491);\n        }\n        else\n        {\n            float3 param_37 = _2924;\n            float3 param_38 = _2894;\n            float3 param_39 = f0;\n            float param_40 = _2935;\n            lit += (fa_sky_reflection(param_37, param_38, param_39, param_40) * _3491);\n        }\n        result = lit;\n    }\n    float3 _3203 = result;\n    float3 _3204 = _3203 + _3492;\n    result = _3204;\n    float3 param_41 = _3204;\n    float3 param_42 = fa_world_pos;\n    result = fa_shadow_debug(param_41, param_42);\n    bool _3213 = _486_fa_fog.w > 0.0f;\n    bool _3220;\n    if (!_3213)\n    {\n        _3220 = _486_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3220 = _3213;\n    }\n    if (_3220)\n    {\n        float3 _3229 = fa_world_pos - _486_fa_camera_pos.xyz;\n        float _3235 = dot(_3229, _486_fa_fog_c.xyz);\n        bool _3239 = _486_fa_fog_c.w > 0.5f;\n        float _3240;\n        if (_3239)\n        {\n            _3240 = _3235;\n        }\n        else\n        {\n            _3240 = length(_3229);\n        }\n        float _3252 = _3240 - _486_fa_fog_b.x;\n        if (_3252 > 0.0f)\n        {\n            float _3261 = _486_fa_fog.w * _3252;\n            float tau = _3261 * _3261;\n            if (_486_fa_fog_b.y > 0.0f)\n            {\n                float _3277;\n                if (_3239)\n                {\n                    _3277 = fa_world_pos.y - (_486_fa_fog_c.y * _3235);\n                }\n                else\n                {\n                    _3277 = _486_fa_camera_pos.y;\n                }\n                float _3298 = lerp(_3277, fa_world_pos.y, clamp(_486_fa_fog_b.x / _3240, 0.0f, 1.0f));\n                float _3302 = fa_world_pos.y - _3298;\n                float _3307 = _3298 - _486_fa_fog_b.z;\n                float _3312 = fa_world_pos.y - _486_fa_fog_b.z;\n                bool _3315 = _3307 <= 0.0f;\n                bool _3316 = !_3315;\n                bool _3322;\n                if (_3316)\n                {\n                    _3322 = _486_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3322 = _3315;\n                }\n                float _3323;\n                if (_3322)\n                {\n                    _3323 = _486_fa_fog_b.y;\n                }\n                else\n                {\n                    _3323 = _486_fa_fog_b.y * exp(-min(_486_fa_fog_b.w * _3307, 80.0f));\n                }\n                bool _3350;\n                if (_3316)\n                {\n                    _3350 = _486_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3350 = _3315;\n                }\n                float _3351;\n                if (_3350)\n                {\n                    _3351 = _486_fa_fog_b.y * _3307;\n                }\n                else\n                {\n                    _3351 = (_486_fa_fog_b.y * (1.0f - exp(-min(_486_fa_fog_b.w * _3307, 80.0f)))) / _486_fa_fog_b.w;\n                }\n                bool _3376 = _3312 <= 0.0f;\n                bool _3383;\n                if (!_3376)\n                {\n                    _3383 = _486_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3383 = _3376;\n                }\n                float _3384;\n                if (_3383)\n                {\n                    _3384 = _486_fa_fog_b.y * _3312;\n                }\n                else\n                {\n                    _3384 = (_486_fa_fog_b.y * (1.0f - exp(-min(_486_fa_fog_b.w * _3312, 80.0f)))) / _486_fa_fog_b.w;\n                }\n                float _3411;\n                if (abs(_3302) < 0.001000000047497451305389404296875f)\n                {\n                    _3411 = _3323;\n                }\n                else\n                {\n                    _3411 = (_3384 - _3351) / _3302;\n                }\n                tau += (_3252 * max(_3411, 0.0f));\n            }\n            result = lerp(result, _486_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3487);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_50",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_150",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_197",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_486",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_722",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 9,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _45_offset : packoffset(c0);\n    float _45_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _145_fa_view_proj : packoffset(c0);\n    row_major float4x4 _145_fa_light_vp : packoffset(c4);\n    float4 _145_fa_uv_scale : packoffset(c8);\n    float4 _145_fa_time : packoffset(c9);\n    float4 _145_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _310 = { mul(float4(position, 1.0f), model).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * _145_fa_uv_scale.xy, color, position };\n    return _310;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _45_offset;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _189 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_189, _145_fa_light_vp).z;\n    fa_pre_r0 = float3(_145_fa_light_vp[0].x, _145_fa_light_vp[1].x, _145_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_145_fa_light_vp[0].y, _145_fa_light_vp[1].y, _145_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_145_fa_light_vp[0].z, _145_fa_light_vp[1].z, _145_fa_light_vp[2].z);\n    gl_Position = mul(_189, _145_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _736 = base_t;\n    _736.x = _225.x;\n    _736.y = _225.y;\n    _736.z = _225.z;\n    base_t = _736;\n    float4 _241 = (_736 * _213_fa_base_color) * i.vertex_color;\n    float3 _699 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _744 = _279;\n        _744.x = _284.x;\n        _744.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _744;\n        _699 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _747 = mrt;\n    _747.x = _313.x;\n    _747.y = _313.y;\n    _747.z = _313.z;\n    mrt = _747;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _704 = _213_fa_layers_a.x;\n    float _705 = _213_fa_layers_a.y;\n    float _708 = _213_fa_layers_a.z;\n    float _707 = _213_fa_layers_b.w;\n    float _710 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _704 *= _355.y;\n            _705 *= _355.z;\n            _707 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _708 *= mrt.x;\n            _710 *= mrt.w;\n        }\n    }\n    Surface _729 = { _241.xyz, _241.w, _699, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _704, _705, _213_fa_layers_b.xyz, _707, _708, _213_fa_layers_a.w, _710, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _729;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _610 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _610 = -_610;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _623 = { fa_world_pos, _610, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _623;\n    SurfaceInput _631 = { fa_world_pos, _610, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _631;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_45",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_145",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _50_offset : packoffset(c0);\n    float _50_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _150_fa_view_proj : packoffset(c0);\n    row_major float4x4 _150_fa_light_vp : packoffset(c4);\n    float4 _150_fa_uv_scale : packoffset(c8);\n    float4 _150_fa_time : packoffset(c9);\n    float4 _150_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _197_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _188 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_197_fa_joint_rows[_188] * weights[i]);\n        r1 += (_197_fa_joint_rows[_188 + 1] * weights[i]);\n        r2 += (_197_fa_joint_rows[_188 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _431 = { mul(float4(position, 1.0f), model).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * _150_fa_uv_scale.xy, color, position };\n    return _431;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _50_offset;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _302 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_302, _150_fa_light_vp).z;\n    fa_pre_r0 = float3(_150_fa_light_vp[0].x, _150_fa_light_vp[1].x, _150_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_150_fa_light_vp[0].y, _150_fa_light_vp[1].y, _150_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_150_fa_light_vp[0].z, _150_fa_light_vp[1].z, _150_fa_light_vp[2].z);\n    gl_Position = mul(_302, _150_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _736 = base_t;\n    _736.x = _225.x;\n    _736.y = _225.y;\n    _736.z = _225.z;\n    base_t = _736;\n    float4 _241 = (_736 * _213_fa_base_color) * i.vertex_color;\n    float3 _699 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _744 = _279;\n        _744.x = _284.x;\n        _744.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _744;\n        _699 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _747 = mrt;\n    _747.x = _313.x;\n    _747.y = _313.y;\n    _747.z = _313.z;\n    mrt = _747;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _704 = _213_fa_layers_a.x;\n    float _705 = _213_fa_layers_a.y;\n    float _708 = _213_fa_layers_a.z;\n    float _707 = _213_fa_layers_b.w;\n    float _710 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _704 *= _355.y;\n            _705 *= _355.z;\n            _707 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _708 *= mrt.x;\n            _710 *= mrt.w;\n        }\n    }\n    Surface _729 = { _241.xyz, _241.w, _699, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _704, _705, _213_fa_layers_b.xyz, _707, _708, _213_fa_layers_a.w, _710, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _729;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _610 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _610 = -_610;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _623 = { fa_world_pos, _610, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _623;\n    SurfaceInput _631 = { fa_world_pos, _610, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _631;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_50",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_150",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_197",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
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
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _36_offset : packoffset(c0);\n    float _36_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _262 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _262;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _36_offset;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _136_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_36",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "hlsl_register_b_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float3 _41_offset : packoffset(c0);\n    float _41_fa_pad0 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _141_fa_view_proj : packoffset(c0);\n    row_major float4x4 _141_fa_light_vp : packoffset(c4);\n    float4 _141_fa_uv_scale : packoffset(c8);\n    float4 _141_fa_time : packoffset(c9);\n    float4 _141_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _188_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _179 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_188_fa_joint_rows[_179] * weights[i]);\n        r1 += (_188_fa_joint_rows[_179 + 1] * weights[i]);\n        r2 += (_188_fa_joint_rows[_179 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _79 = cross(model[1].xyz, model[2].xyz);\n    float _85 = (dot(model[0].xyz, _79) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _383 = { mul(float4(position, 1.0f), model).xyz, (((_79 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _85, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _85), texcoord0 * _141_fa_uv_scale.xy, color, position };\n    return _383;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += _41_offset;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _141_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_41",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_141",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_188",
            "hlsl_register_b_n": 3
          }
        ]
      }
    }
  }
}
