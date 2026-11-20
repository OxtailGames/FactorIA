{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "df130aaeb5c0790af276010723d2798f8fdace693dbde21948e5a037edff24ef",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1996[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _3888 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _467_fa_camera_pos : packoffset(c0);\n    float4 _467_fa_ambient : packoffset(c1);\n    float4 _467_fa_base_color : packoffset(c2);\n    float4 _467_fa_emissive : packoffset(c3);\n    float4 _467_fa_model_emissive : packoffset(c4);\n    float4 _467_fa_pbr : packoffset(c5);\n    float4 _467_fa_maps : packoffset(c6);\n    float4 _467_fa_fog : packoffset(c7);\n    float4 _467_fa_fog_b : packoffset(c8);\n    float4 _467_fa_fog_c : packoffset(c9);\n    float4 _467_fa_counts : packoffset(c10);\n    float4 _467_fa_env_sky : packoffset(c11);\n    float4 _467_fa_env_horizon : packoffset(c12);\n    float4 _467_fa_time : packoffset(c13);\n    float4 _467_fa_cl_vpx : packoffset(c14);\n    float4 _467_fa_cl_vpy : packoffset(c15);\n    float4 _467_fa_cl_vpw : packoffset(c16);\n    float4 _467_fa_cl_fwd : packoffset(c17);\n    float4 _467_fa_cl_grid : packoffset(c18);\n    float4 _467_fa_cl_info : packoffset(c19);\n    float4 _467_fa_layers_a : packoffset(c20);\n    float4 _467_fa_layers_b : packoffset(c21);\n    float4 _467_fa_layers_c : packoffset(c22);\n    float4 _467_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _703_fa_shadow_mat[4] : packoffset(c0);\n    float4 _703_fa_shadow_rect[4] : packoffset(c16);\n    float4 _703_fa_shadow_info[4] : packoffset(c20);\n    float4 _703_fa_shadow_split : packoffset(c24);\n    float4 _703_fa_shadow_cfg : packoffset(c25);\n    float4 _703_fa_shadow_bias : packoffset(c26);\n    float4 _703_fa_shadow_eye : packoffset(c27);\n    float4 _703_fa_shadow_fwd : packoffset(c28);\n    float4 _703_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2790_dark : packoffset(c0);\n    float _2790_fa_pad0 : packoffset(c0.y);\n    float _2790_fa_pad1 : packoffset(c0.z);\n    float _2790_fa_pad2 : packoffset(c0.w);\n    float _2790_skyAmount : packoffset(c1);\n    float _2790_fa_pad3 : packoffset(c1.y);\n    float _2790_fa_pad4 : packoffset(c1.z);\n    float _2790_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _472 = _467_fa_cl_info.x < 0.0f;\n    bool _479;\n    if (!_472)\n    {\n        _479 = _467_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _479 = _472;\n    }\n    bool _487;\n    if (!_479)\n    {\n        _487 = _467_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _487 = _479;\n    }\n    bool _494;\n    if (!_487)\n    {\n        _494 = _467_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _494 = _487;\n    }\n    bool _501;\n    if (!_494)\n    {\n        _501 = _467_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _501 = _494;\n    }\n    if (_501)\n    {\n        return int2(0, 0);\n    }\n    float4 _511 = float4(world_pos, 1.0f);\n    float _518 = dot(_467_fa_cl_vpw, _511);\n    if (!(_518 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _540 = float2(dot(_467_fa_cl_vpx, _511), dot(_467_fa_cl_vpy, _511)) / _518.xx;\n    int _544 = int(_467_fa_cl_grid.x);\n    int _548 = int(_467_fa_cl_grid.y);\n    int param = (int(_467_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_467_fa_cl_fwd.xyz, world_pos) + _467_fa_cl_fwd.w, _467_fa_cl_grid.w) / _467_fa_cl_grid.w) * _467_fa_cl_grid.z)), 0, int(_467_fa_cl_info.y) - 1) * _548) + clamp(int(floor(((_540.y * 0.5f) + 0.5f) * _467_fa_cl_grid.y)), 0, _548 - 1)) * _544)) + clamp(int(floor(((_540.x * 0.5f) + 0.5f) * _467_fa_cl_grid.x)), 0, _544 - 1);\n    float4 _619 = fa_light_texel(param);\n    return int2(int(_619.x), int(_619.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_467_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2544 = fa_cluster_lookup(param);\n    fa_cl_slot = _2544.x;\n    fa_cl_local = _2544.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2862 = fa_linear_to_srgb(param);\n        c = _2862;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2870 = fa_srgb_to_linear(param_1);\n            c = _2870;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _230;\n    if (i.front_facing)\n    {\n        _230 = i.world_normal;\n    }\n    else\n    {\n        _230 = -i.world_normal;\n    }\n    float3 _254 = normalize(i.world_tangent.xyz - (_230 * dot(_230, i.world_tangent.xyz)));\n    float3 _282 = normalize(((_254 * m.x) + ((cross(_230, _254) * i.world_tangent.w) * m.y)) + (_230 * m.z));\n    float3 _285;\n    if (i.front_facing)\n    {\n        _285 = _282;\n    }\n    else\n    {\n        _285 = -_282;\n    }\n    return _285;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _467_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2901 = fa_tex_fix(param_2, param_3);\n    float4 _3860 = base_t;\n    _3860.x = _2901.x;\n    _3860.y = _2901.y;\n    _3860.z = _2901.z;\n    base_t = _3860;\n    float4 _2915 = (_3860 * _467_fa_base_color) * i.vertex_color;\n    float3 _3762 = i.world_normal;\n    if (_467_fa_maps.z > 0.5f)\n    {\n        float param_4 = _467_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2947 = fa_tex_fix(param_6, param_7);\n        float3 _2951 = (_2947 * 2.0f) - 1.0f.xxx;\n        float2 _2956 = _2951.xy * _467_fa_maps.x;\n        float3 _3868 = _2951;\n        _3868.x = _2956.x;\n        _3868.y = _2956.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3868;\n        _3762 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _467_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2985 = fa_tex_fix(param_12, param_13);\n    float4 _3871 = mrt;\n    _3871.x = _2985.x;\n    _3871.y = _2985.y;\n    _3871.z = _2985.z;\n    mrt = _3871;\n    float4 _3013 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _467_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3013.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3025 = fa_tex_fix(param_16, param_17);\n    float param_18 = _467_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3055 = fa_tex_fix(param_20, param_21);\n    float _3767 = _467_fa_layers_a.x;\n    float _3768 = _467_fa_layers_a.y;\n    float _3771 = _467_fa_layers_a.z;\n    float _3770 = _467_fa_layers_b.w;\n    float _3773 = _467_fa_layers_c.x;\n    if (_467_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_467_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3767 *= _3025.y;\n            _3768 *= _3025.z;\n            _3770 *= _3013.w;\n        }\n        if (_467_fa_layers_c.z > 1.5f)\n        {\n            _3771 *= mrt.x;\n            _3773 *= mrt.w;\n        }\n    }\n    Surface _3792 = { _2915.xyz, _2915.w, _3762, clamp(_467_fa_pbr.x * _2985.z, 0.0f, 1.0f), clamp(_467_fa_pbr.y * _2985.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_467_fa_maps.y * (_3025.x - 1.0f)), _467_fa_emissive.xyz + (_467_fa_model_emissive.xyz * _3055), _3767, _3768, _467_fa_layers_b.xyz, _3770, _3771, _467_fa_layers_a.w, _3773, _467_fa_layers_c.y, _467_fa_layers_d.xyz };\n    return _3792;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _3888;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_467_fa_cl_info.x) + int(_467_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _341 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _347 = fa_light_texel(param_1);\n    float _350 = _347.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _356 = _350 < 0.5f;\n    float3 l;\n    if (_356)\n    {\n        l = normalize(_341.xyz);\n    }\n    else\n    {\n        float3 _368 = _341.xyz - world_pos;\n        float _370 = length(_368);\n        dist = _370;\n        l = _368 / max(_370, 9.9999997473787516355514526367188e-05f).xxx;\n        float _385 = _370 / max(_341.w, 0.001000000047497451305389404296875f);\n        float _391 = clamp(1.0f - (_385 * _385), 0.0f, 1.0f);\n        atten = _391 * _391;\n        if (_350 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _405 = fa_light_texel(param_2);\n            float _415 = _405.w;\n            int param_3 = (li * 4) + 3;\n            float4 _421 = fa_light_texel(param_3);\n            float _422 = _421.x;\n            float cos_inner = _422;\n            if (_422 > 1.5f)\n            {\n                cos_inner = lerp(_415, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_415, cos_inner, dot(-l, normalize(_405.xyz)));\n        }\n    }\n    int _453;\n    if (_356)\n    {\n        _453 = 0;\n    }\n    else\n    {\n        _453 = (_350 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3598 = { l, _347.xyz * atten, atten, 1.0f, dist, _453 };\n    return _3598;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2685 = n < 0;\n    bool _2692;\n    if (!_2685)\n    {\n        _2692 = n >= fa_light_count();\n    }\n    else\n    {\n        _2692 = _2685;\n    }\n    if (_2692)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _2700 = fa_cl_light(param);\n    bool _2703 = fa_lm.z > 0.5f;\n    bool _2709;\n    if (_2703)\n    {\n        int param_1 = _2700;\n        _2709 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _2709 = _2703;\n    }\n    if (_2709)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _2700;\n    float3 param_3 = i.world_pos;\n    return fa_light_sample(param_2, param_3);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _693;\n    if (i == 0)\n    {\n        _693 = _703_fa_shadow_split.x;\n    }\n    else\n    {\n        float _709;\n        if (i == 1)\n        {\n            _709 = _703_fa_shadow_split.y;\n        }\n        else\n        {\n            float _717;\n            if (i == 2)\n            {\n                _717 = _703_fa_shadow_split.z;\n            }\n            else\n            {\n                _717 = _703_fa_shadow_split.w;\n            }\n            _709 = _717;\n        }\n        _693 = _709;\n    }\n    return _693;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _750 = fa_shadow_depth(param, param_1);\n    float _754;\n    if (conv.x < 0.5f)\n    {\n        _754 = _750;\n    }\n    else\n    {\n        _754 = (conv.y * conv.z) / (conv.z - (_750 * (conv.z - conv.y)));\n    }\n    return _754;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _681 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_681), sin(_681)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _800 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _814 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _800;\n            float2 _833 = fa_shadow_vogel(param_3, param_4, param_5) * _814;\n            float2 param_6 = uv + (_833 * _703_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _845 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_845 < (zr - (length(_833) * plane)))\n            {\n                sum += _845;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _889 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _889; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _889;\n        float param_11 = _800;\n        float2 _908 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_908 * _703_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_908) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_889);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _950 = max(_703_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _955 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _961 = sqrt(1.0f - (_955 * _955));\n    float _969 = min(_961 / max(_955, 0.20000000298023223876953125f), 4.0f);\n    float _974;\n    if (_703_fa_shadow_bias.y > 0.0f)\n    {\n        _974 = _703_fa_shadow_bias.y;\n    }\n    else\n    {\n        _974 = 1.5f * _703_fa_shadow_info[ci].x;\n    }\n    float4 _999 = mul(float4(world + (n * (_974 * _961)), 1.0f), _703_fa_shadow_mat[ci]);\n    float _1006 = _999.x;\n    bool _1009 = _1006 < _703_fa_shadow_rect[ci].x;\n    bool _1018;\n    if (!_1009)\n    {\n        _1018 = _1006 > _703_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1018 = _1009;\n    }\n    bool _1027;\n    if (!_1018)\n    {\n        _1027 = _999.y < _703_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1027 = _1018;\n    }\n    bool _1036;\n    if (!_1027)\n    {\n        _1036 = _999.y > _703_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1036 = _1027;\n    }\n    bool _1043;\n    if (!_1036)\n    {\n        _1043 = _999.z > 1.0f;\n    }\n    else\n    {\n        _1043 = _1036;\n    }\n    if (_1043)\n    {\n        return -1.0f;\n    }\n    float _1052;\n    if (_703_fa_shadow_bias.x > 0.0f)\n    {\n        _1052 = _703_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1052 = 1.5f * _703_fa_shadow_info[ci].x;\n    }\n    float2 param = _999.xy;\n    float4 param_1 = _703_fa_shadow_rect[ci];\n    float param_2 = _999.z - ((_1052 * (1.0f + (0.5f * _969))) / _950);\n    float param_3 = _703_fa_shadow_info[ci].x;\n    float param_4 = _950;\n    float param_5 = _950 * 0.25f;\n    float param_6 = ((_703_fa_shadow_info[ci].x * min(_969, 3.0f)) * 0.5f) / _950;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_703_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _703_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_467_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1480 = int(_703_fa_shadow_cfg.x + 0.5f);\n    if (_1480 < 1)\n    {\n        return 1.0f;\n    }\n    float _1496 = dot(world - _703_fa_shadow_eye.xyz, _703_fa_shadow_fwd.xyz);\n    int param = _1480 - 1;\n    if (_1496 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1508 = _1480 > 1;\n    bool _1515;\n    if (_1508)\n    {\n        _1515 = _1496 > _703_fa_shadow_split.x;\n    }\n    else\n    {\n        _1515 = _1508;\n    }\n    if (_1515)\n    {\n        ci = 1;\n    }\n    bool _1519 = _1480 > 2;\n    bool _1526;\n    if (_1519)\n    {\n        _1526 = _1496 > _703_fa_shadow_split.y;\n    }\n    else\n    {\n        _1526 = _1519;\n    }\n    if (_1526)\n    {\n        ci = 2;\n    }\n    bool _1530 = _1480 > 3;\n    bool _1537;\n    if (_1530)\n    {\n        _1537 = _1496 > _703_fa_shadow_split.z;\n    }\n    else\n    {\n        _1537 = _1530;\n    }\n    if (_1537)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1480)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1563 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1563;\n        if (_1563 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_703_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1588;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1588 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1588 = _703_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1607 = _703_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1588, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1618 = clamp((_1496 - (fa_shadow_split_at(param_7) - _1607)) / _1607, 0.0f, 1.0f);\n        if (_1618 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1480)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1639 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1639;\n                if (_1639 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1618);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1111 = _467_fa_pbr.z < 0.5f;\n    bool _1119;\n    if (!_1111)\n    {\n        _1119 = _703_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1119 = _1111;\n    }\n    if (_1119)\n    {\n        return 1.0f;\n    }\n    int param = (int(_703_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1132 = fa_light_texel(param);\n    float _1133 = _1132.x;\n    if (_1133 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1142 = int(_1133 + 0.5f);\n    int param_1 = _1142;\n    float4 _1146 = fa_light_texel(param_1);\n    int param_2 = _1142 + 1;\n    float4 _1151 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1154 = _1146.y;\n    if (_1154 > 0.0f)\n    {\n        float _1171 = 1.0f - smoothstep(0.75f * _1154, _1154, length(world - _703_fa_shadow_eye.xyz));\n        fade = _1171;\n        if (_1171 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1146.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1190 = world - fa_light_texel(param_3).xyz;\n        float3 _1193 = abs(_1190);\n        float _1195 = _1193.x;\n        float _1197 = _1193.y;\n        bool _1198 = _1195 >= _1197;\n        bool _1206;\n        if (_1198)\n        {\n            _1206 = _1195 >= _1193.z;\n        }\n        else\n        {\n            _1206 = _1198;\n        }\n        int _1207;\n        if (_1206)\n        {\n            _1207 = (_1190.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1220;\n            if (_1197 >= _1193.z)\n            {\n                _1220 = (_1190.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1220 = (_1190.z > 0.0f) ? 4 : 5;\n            }\n            _1207 = _1220;\n        }\n        face = _1207;\n    }\n    int _1239 = (_1142 + 2) + (face * 6);\n    int param_4 = _1239;\n    int param_5 = _1239 + 1;\n    int param_6 = _1239 + 3;\n    float4 _1253 = fa_light_texel(param_6);\n    int param_7 = _1239 + 4;\n    float4 _1258 = fa_light_texel(param_7);\n    int param_8 = _1239 + 5;\n    float4 _1263 = fa_light_texel(param_8);\n    float _1275 = _1263.x * max(dot(_1253, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1280 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1303 = clamp(dot(n, _1253.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1326 = min(sqrt(1.0f - (_1303 * _1303)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1253, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1329 = _1151.y;\n    float _1331;\n    if (_1329 > 0.0f)\n    {\n        _1331 = _1329;\n    }\n    else\n    {\n        _1331 = 1.5f * _1275;\n    }\n    float4 _1351 = float4(world + (n * (_1331 * sqrt(1.0f - (_1280 * _1280)))), 1.0f);\n    float _1355 = dot(_1253, _1351);\n    float _1358 = _1263.y;\n    if (_1355 < _1358)\n    {\n        return 1.0f;\n    }\n    float2 _1373 = float2(dot(fa_light_texel(param_4), _1351), dot(fa_light_texel(param_5), _1351)) / _1355.xx;\n    float _1375 = _1373.x;\n    bool _1378 = _1375 < _1258.x;\n    bool _1387;\n    if (!_1378)\n    {\n        _1387 = _1375 > _1258.z;\n    }\n    else\n    {\n        _1387 = _1378;\n    }\n    bool _1396;\n    if (!_1387)\n    {\n        _1396 = _1373.y < _1258.y;\n    }\n    else\n    {\n        _1396 = _1387;\n    }\n    bool _1405;\n    if (!_1396)\n    {\n        _1405 = _1373.y > _1258.w;\n    }\n    else\n    {\n        _1405 = _1396;\n    }\n    if (_1405)\n    {\n        return 1.0f;\n    }\n    float _1411 = _1151.x;\n    float _1413;\n    if (_1411 > 0.0f)\n    {\n        _1413 = _1411;\n    }\n    else\n    {\n        _1413 = 1.5f * _1275;\n    }\n    float2 param_10 = _1373;\n    float4 param_11 = _1258;\n    float param_12 = _1355 - (_1413 * (1.0f + (0.5f * _1326)));\n    float param_13 = _1275;\n    float param_14 = 1.0f;\n    float param_15 = _1263.z * 0.25f;\n    float param_16 = (_1275 * min(_1326, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1358, _1263.z);\n    int param_18 = int(_1146.z + 0.5f);\n    float param_19 = _1146.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2571 = fa_lm.z > 0.5f;\n    bool _2577;\n    if (_2571)\n    {\n        int param = li;\n        _2577 = fa_light_baked(param);\n    }\n    else\n    {\n        _2577 = _2571;\n    }\n    if (_2577)\n    {\n        int param_1 = li;\n        LightSample _3731 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _3731;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2599 = fa_light_sample(param_2, param_3);\n    float3 _3738 = _2599.direction;\n    float3 _3733 = _2599.color;\n    float _3740 = _2599.attenuation;\n    float _3735 = _2599.shadow;\n    int _3743 = _2599.type;\n    if ((_3743 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3738;\n        float _2613 = fa_shadow_factor(param_4, param_5);\n        _3735 = _2613;\n        _3733 *= _2613;\n    }\n    else\n    {\n        bool _2624 = _3743 != 0;\n        bool _2630;\n        if (_2624)\n        {\n            _2630 = _3740 > 0.0f;\n        }\n        else\n        {\n            _2630 = _2624;\n        }\n        if (_2630)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3738;\n            float _2642 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3735 = _2642;\n            _3733 *= _2642;\n        }\n    }\n    LightSample _3750 = { _3738, _3733, _3740, _3735, _2599._distance, _3743 };\n    return _3750;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2659 = n < 0;\n    bool _2666;\n    if (!_2659)\n    {\n        _2666 = n >= fa_light_count();\n    }\n    else\n    {\n        _2666 = _2659;\n    }\n    if (_2666)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1921 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1929 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1932 = int(_1921);\n    int _1935 = int(_1929);\n    float _1945 = _1929 - float(_1935);\n    int _2001 = (_1932 * 9) + _1935;\n    int _2021 = ((_1932 + 1) * 9) + _1935;\n    return lerp(lerp(_1996[_2001], _1996[_2001 + 1], _1945), lerp(_1996[_2021], _1996[_2021 + 1], _1945), _1921 - float(_1932));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3599 = false;\n    float _3600 = 1.0f;\n    float _3601 = 1.0f;\n    float _3602 = 1.0f;\n    float _3603 = 0.0f;\n    float _3604 = 0.0f;\n    float _3605 = 0.0f;\n    float _3606 = 0.0f;\n    float _3608 = 1.0f;\n    bool _3609 = false;\n    float3 _3610 = 0.0f.xxx;\n    float _3611 = 1.0f;\n    float _3612 = 1.0f;\n    float _3613 = 1.0f;\n    float _3614 = 0.0f;\n    float _3615 = 0.0f;\n    float3 _3616 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3617 = float3(0.0f, 0.0f, 1.0f);\n    float _3618 = 1.0f;\n    float _3619 = 1.0f;\n    float _2074 = clamp(s.specular, 0.0f, 1.0f);\n    float _2078 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2083 = (_2074 != 1.0f) || (_2078 != 1.5f);\n    bool _2093;\n    if (!_2083)\n    {\n        _2093 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2093 = _2083;\n    }\n    if (_2093)\n    {\n        float _2101 = (_2078 - 1.0f) / (_2078 + 1.0f);\n        f0 = lerp(min((_2101 * _2101).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2074, s.albedo, metallic.xxx);\n        _3600 = lerp(_2074, 1.0f, metallic);\n        _3599 = true;\n    }\n    float _2129 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2129 > 0.0f)\n    {\n        float _2137 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3603 = _2129;\n        _3604 = _2137;\n        float _2144 = _2137 * _2137;\n        _3605 = _2144;\n        _3606 = _2144 * _2144;\n        float _2156 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3608 = _2156;\n        _3601 = 1.0f - (_2129 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2156, 0.0f, 1.0f), 5.0f))));\n        _3599 = true;\n    }\n    float3 _2176 = max(s.sheen_color, 0.0f.xxx);\n    float _2185 = max(_2176.x, max(_2176.y, _2176.z));\n    if (_2185 > 0.0f)\n    {\n        float _2193 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3609 = true;\n        _3610 = _2176;\n        _3611 = _2193;\n        _3612 = _2193 * _2193;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2193;\n        float _2210 = fa_sheen_albedo(param, param_1);\n        _3614 = _2210;\n        _3613 = 1.0f - min(_2185 * _2210, 1.0f);\n        _3599 = true;\n    }\n    _3602 = _3601 * _3613;\n    float _2229 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2229 != 0.0f)\n    {\n        float3 _2244 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2244;\n        if (dot(_2244, _2244) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2258 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2258.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2258.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2258.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2262 = t;\n        float3 _2263 = normalize(_2262);\n        t = _2263;\n        float3 _2288 = normalize((_2263 * cos(s.anisotropy_rotation)) + ((cross(n, _2263) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3616 = _2288;\n        _3617 = cross(n, _2288);\n        float _2298 = roughness * roughness;\n        float _2304 = lerp(_2298, 1.0f, _2229 * _2229);\n        bool _2306 = _2229 > 0.0f;\n        _3618 = _2306 ? _2304 : _2298;\n        _3619 = _2306 ? _2298 : _2304;\n        _3615 = _2229;\n        _3599 = true;\n    }\n    FaLayers _3641 = { _3599, _3600, _3601, _3602, _3603, _3604, _3605, _3606, i.world_normal, _3608, _3609, _3610, _3611, _3612, _3613, _3614, _3615, _3616, _3617, _3618, _3619 };\n    return _3641;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1853 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1856 = _1853.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1856 * _1856, exp2((-9.27999973297119140625f) * ndv)) * _1856) + _1853.y)) + _1853.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_467_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _467_fa_env_horizon.w).xyz;\n    }\n    float _1776 = rough * rough;\n    float _1806 = 0.60000002384185791015625f * _1776;\n    return lerp(lerp(_467_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_467_fa_env_horizon.xyz, _467_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1776)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1806, 0.0500000007450580596923828125f + _1806, d.y).xxx), ((_467_fa_env_sky.xyz + _467_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1776 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2339;\n        if (L.aniso >= 0.0f)\n        {\n            _2339 = L.b;\n        }\n        else\n        {\n            _2339 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2339, v), _2339), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2372 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2372.x) + (L.f90.xxx * _2372.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2427 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2427.x) + _2427.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1895 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1895.x) + _1895.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2466 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2470 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2477 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2466.xxx);\n    float3 f0 = _2477;\n    float3 _2481 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2481;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2466;\n    float param_5 = _2470;\n    float3 param_6 = _2477;\n    FaLayers _2498 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2498.on)\n    {\n        FaLayers param_7 = _2498;\n        float3 param_8 = _2481;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2470;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2481;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2470;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2747 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_2747 > bestPower)\n        {\n            bestPower = _2747;\n            best = n;\n        }\n    }\n    float3 lit = (_467_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2776 = fa_light(param_2, param_3);\n        float _2784;\n        if (dot(s.normal, _2776.direction) > 0.5f)\n        {\n            _2784 = 1.0f;\n        }\n        else\n        {\n            _2784 = _2790_dark;\n        }\n        lit += ((s.albedo * _2776.color) * _2784);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _2790_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_703_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1663 = int(_703_fa_shadow_cfg.x + 0.5f);\n    float _1673 = dot(world - _703_fa_shadow_eye.xyz, _703_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1678 = _1663 > 0;\n    bool _1687;\n    if (_1678)\n    {\n        int param = _1663 - 1;\n        _1687 = _1673 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1687 = _1678;\n    }\n    if (_1687)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1694 = _1663 > 1;\n        bool _1701;\n        if (_1694)\n        {\n            _1701 = _1673 > _703_fa_shadow_split.x;\n        }\n        else\n        {\n            _1701 = _1694;\n        }\n        if (_1701)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1707 = _1663 > 2;\n        bool _1714;\n        if (_1707)\n        {\n            _1714 = _1673 > _703_fa_shadow_split.y;\n        }\n        else\n        {\n            _1714 = _1707;\n        }\n        if (_1714)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1720 = _1663 > 3;\n        bool _1727;\n        if (_1720)\n        {\n            _1727 = _1673 > _703_fa_shadow_split.z;\n        }\n        else\n        {\n            _1727 = _1720;\n        }\n        if (_1727)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3473 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3473 = -_3473;\n    }\n    float3 _3176 = normalize(_467_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3486 = { fa_world_pos, _3473, fa_world_tangent, fa_uv, fa_vertex_color, _3176, gl_FrontFacing };\n    SurfaceInput param_1 = _3486;\n    Surface _3184 = fa_standard_surface(param_1);\n    float3 _3504 = _3184.albedo;\n    float _3505 = _3184.alpha;\n    float3 _3506 = _3184.normal;\n    float _3507 = _3184.metallic;\n    float _3508 = _3184.roughness;\n    float _3509 = _3184.occlusion;\n    float3 _3510 = _3184.emission;\n    float _3511 = _3184.clearcoat;\n    float _3512 = _3184.clearcoat_roughness;\n    float3 _3513 = _3184.sheen_color;\n    float _3514 = _3184.sheen_roughness;\n    float _3515 = _3184.anisotropy;\n    float _3516 = _3184.anisotropy_rotation;\n    float _3517 = _3184.specular;\n    float _3518 = _3184.ior;\n    float3 _3519 = _3184.specular_color;\n    SurfaceInput _3494 = { fa_world_pos, _3473, fa_world_tangent, fa_uv, fa_vertex_color, _3176, gl_FrontFacing };\n    SurfaceInput param_2 = _3494;\n    Surface param_3 = _3184;\n    surface(param_2, param_3);\n    _3504 = param_3.albedo;\n    _3505 = param_3.alpha;\n    _3506 = param_3.normal;\n    _3507 = param_3.metallic;\n    _3508 = param_3.roughness;\n    _3509 = param_3.occlusion;\n    _3510 = param_3.emission;\n    _3511 = param_3.clearcoat;\n    _3512 = param_3.clearcoat_roughness;\n    _3513 = param_3.sheen_color;\n    _3514 = param_3.sheen_roughness;\n    _3515 = param_3.anisotropy;\n    _3516 = param_3.anisotropy_rotation;\n    _3517 = param_3.specular;\n    _3518 = param_3.ior;\n    _3519 = param_3.specular_color;\n    float3 result;\n    if (_467_fa_emissive.w > 0.5f)\n    {\n        result = _3504;\n    }\n    else\n    {\n        float3 _3205 = _3506;\n        float3 _3206 = normalize(_3205);\n        _3506 = _3206;\n        SurfaceInput _3502 = { fa_world_pos, _3473, fa_world_tangent, fa_uv, fa_vertex_color, _3176, gl_FrontFacing };\n        SurfaceInput param_4 = _3502;\n        Surface _3585 = { _3504, _3505, _3206, _3507, _3508, _3509, _3510, _3511, _3512, _3513, _3514, _3515, _3516, _3517, _3518, _3519 };\n        Surface param_5 = _3585;\n        result = lighting(param_4, param_5);\n    }\n    float3 _3221 = result;\n    float3 _3222 = _3221 + _3510;\n    result = _3222;\n    float3 param_6 = _3222;\n    float3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _3231 = _467_fa_fog.w > 0.0f;\n    bool _3238;\n    if (!_3231)\n    {\n        _3238 = _467_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3238 = _3231;\n    }\n    if (_3238)\n    {\n        float3 _3247 = fa_world_pos - _467_fa_camera_pos.xyz;\n        float _3253 = dot(_3247, _467_fa_fog_c.xyz);\n        bool _3257 = _467_fa_fog_c.w > 0.5f;\n        float _3258;\n        if (_3257)\n        {\n            _3258 = _3253;\n        }\n        else\n        {\n            _3258 = length(_3247);\n        }\n        float _3270 = _3258 - _467_fa_fog_b.x;\n        if (_3270 > 0.0f)\n        {\n            float _3279 = _467_fa_fog.w * _3270;\n            float tau = _3279 * _3279;\n            if (_467_fa_fog_b.y > 0.0f)\n            {\n                float _3295;\n                if (_3257)\n                {\n                    _3295 = fa_world_pos.y - (_467_fa_fog_c.y * _3253);\n                }\n                else\n                {\n                    _3295 = _467_fa_camera_pos.y;\n                }\n                float _3316 = lerp(_3295, fa_world_pos.y, clamp(_467_fa_fog_b.x / _3258, 0.0f, 1.0f));\n                float _3320 = fa_world_pos.y - _3316;\n                float _3325 = _3316 - _467_fa_fog_b.z;\n                float _3330 = fa_world_pos.y - _467_fa_fog_b.z;\n                bool _3333 = _3325 <= 0.0f;\n                bool _3334 = !_3333;\n                bool _3340;\n                if (_3334)\n                {\n                    _3340 = _467_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3340 = _3333;\n                }\n                float _3341;\n                if (_3340)\n                {\n                    _3341 = _467_fa_fog_b.y;\n                }\n                else\n                {\n                    _3341 = _467_fa_fog_b.y * exp(-min(_467_fa_fog_b.w * _3325, 80.0f));\n                }\n                bool _3368;\n                if (_3334)\n                {\n                    _3368 = _467_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3368 = _3333;\n                }\n                float _3369;\n                if (_3368)\n                {\n                    _3369 = _467_fa_fog_b.y * _3325;\n                }\n                else\n                {\n                    _3369 = (_467_fa_fog_b.y * (1.0f - exp(-min(_467_fa_fog_b.w * _3325, 80.0f)))) / _467_fa_fog_b.w;\n                }\n                bool _3394 = _3330 <= 0.0f;\n                bool _3401;\n                if (!_3394)\n                {\n                    _3401 = _467_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3401 = _3394;\n                }\n                float _3402;\n                if (_3401)\n                {\n                    _3402 = _467_fa_fog_b.y * _3330;\n                }\n                else\n                {\n                    _3402 = (_467_fa_fog_b.y * (1.0f - exp(-min(_467_fa_fog_b.w * _3330, 80.0f)))) / _467_fa_fog_b.w;\n                }\n                float _3429;\n                if (abs(_3320) < 0.001000000047497451305389404296875f)\n                {\n                    _3429 = _3341;\n                }\n                else\n                {\n                    _3429 = (_3402 - _3369) / _3320;\n                }\n                tau += (_3270 * max(_3429, 0.0f));\n            }\n            result = lerp(result, _467_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3505);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_467",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_703",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2790",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _384 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _384;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_391, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1996[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _3888 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _467_fa_camera_pos : packoffset(c0);\n    float4 _467_fa_ambient : packoffset(c1);\n    float4 _467_fa_base_color : packoffset(c2);\n    float4 _467_fa_emissive : packoffset(c3);\n    float4 _467_fa_model_emissive : packoffset(c4);\n    float4 _467_fa_pbr : packoffset(c5);\n    float4 _467_fa_maps : packoffset(c6);\n    float4 _467_fa_fog : packoffset(c7);\n    float4 _467_fa_fog_b : packoffset(c8);\n    float4 _467_fa_fog_c : packoffset(c9);\n    float4 _467_fa_counts : packoffset(c10);\n    float4 _467_fa_env_sky : packoffset(c11);\n    float4 _467_fa_env_horizon : packoffset(c12);\n    float4 _467_fa_time : packoffset(c13);\n    float4 _467_fa_cl_vpx : packoffset(c14);\n    float4 _467_fa_cl_vpy : packoffset(c15);\n    float4 _467_fa_cl_vpw : packoffset(c16);\n    float4 _467_fa_cl_fwd : packoffset(c17);\n    float4 _467_fa_cl_grid : packoffset(c18);\n    float4 _467_fa_cl_info : packoffset(c19);\n    float4 _467_fa_layers_a : packoffset(c20);\n    float4 _467_fa_layers_b : packoffset(c21);\n    float4 _467_fa_layers_c : packoffset(c22);\n    float4 _467_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _703_fa_shadow_mat[4] : packoffset(c0);\n    float4 _703_fa_shadow_rect[4] : packoffset(c16);\n    float4 _703_fa_shadow_info[4] : packoffset(c20);\n    float4 _703_fa_shadow_split : packoffset(c24);\n    float4 _703_fa_shadow_cfg : packoffset(c25);\n    float4 _703_fa_shadow_bias : packoffset(c26);\n    float4 _703_fa_shadow_eye : packoffset(c27);\n    float4 _703_fa_shadow_fwd : packoffset(c28);\n    float4 _703_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _2790_dark : packoffset(c0);\n    float _2790_fa_pad0 : packoffset(c0.y);\n    float _2790_fa_pad1 : packoffset(c0.z);\n    float _2790_fa_pad2 : packoffset(c0.w);\n    float _2790_skyAmount : packoffset(c1);\n    float _2790_fa_pad3 : packoffset(c1.y);\n    float _2790_fa_pad4 : packoffset(c1.z);\n    float _2790_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _472 = _467_fa_cl_info.x < 0.0f;\n    bool _479;\n    if (!_472)\n    {\n        _479 = _467_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _479 = _472;\n    }\n    bool _487;\n    if (!_479)\n    {\n        _487 = _467_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _487 = _479;\n    }\n    bool _494;\n    if (!_487)\n    {\n        _494 = _467_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _494 = _487;\n    }\n    bool _501;\n    if (!_494)\n    {\n        _501 = _467_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _501 = _494;\n    }\n    if (_501)\n    {\n        return int2(0, 0);\n    }\n    float4 _511 = float4(world_pos, 1.0f);\n    float _518 = dot(_467_fa_cl_vpw, _511);\n    if (!(_518 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _540 = float2(dot(_467_fa_cl_vpx, _511), dot(_467_fa_cl_vpy, _511)) / _518.xx;\n    int _544 = int(_467_fa_cl_grid.x);\n    int _548 = int(_467_fa_cl_grid.y);\n    int param = (int(_467_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_467_fa_cl_fwd.xyz, world_pos) + _467_fa_cl_fwd.w, _467_fa_cl_grid.w) / _467_fa_cl_grid.w) * _467_fa_cl_grid.z)), 0, int(_467_fa_cl_info.y) - 1) * _548) + clamp(int(floor(((_540.y * 0.5f) + 0.5f) * _467_fa_cl_grid.y)), 0, _548 - 1)) * _544)) + clamp(int(floor(((_540.x * 0.5f) + 0.5f) * _467_fa_cl_grid.x)), 0, _544 - 1);\n    float4 _619 = fa_light_texel(param);\n    return int2(int(_619.x), int(_619.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_467_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2544 = fa_cluster_lookup(param);\n    fa_cl_slot = _2544.x;\n    fa_cl_local = _2544.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2862 = fa_linear_to_srgb(param);\n        c = _2862;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2870 = fa_srgb_to_linear(param_1);\n            c = _2870;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _230;\n    if (i.front_facing)\n    {\n        _230 = i.world_normal;\n    }\n    else\n    {\n        _230 = -i.world_normal;\n    }\n    float3 _254 = normalize(i.world_tangent.xyz - (_230 * dot(_230, i.world_tangent.xyz)));\n    float3 _282 = normalize(((_254 * m.x) + ((cross(_230, _254) * i.world_tangent.w) * m.y)) + (_230 * m.z));\n    float3 _285;\n    if (i.front_facing)\n    {\n        _285 = _282;\n    }\n    else\n    {\n        _285 = -_282;\n    }\n    return _285;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _467_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2901 = fa_tex_fix(param_2, param_3);\n    float4 _3860 = base_t;\n    _3860.x = _2901.x;\n    _3860.y = _2901.y;\n    _3860.z = _2901.z;\n    base_t = _3860;\n    float4 _2915 = (_3860 * _467_fa_base_color) * i.vertex_color;\n    float3 _3762 = i.world_normal;\n    if (_467_fa_maps.z > 0.5f)\n    {\n        float param_4 = _467_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2947 = fa_tex_fix(param_6, param_7);\n        float3 _2951 = (_2947 * 2.0f) - 1.0f.xxx;\n        float2 _2956 = _2951.xy * _467_fa_maps.x;\n        float3 _3868 = _2951;\n        _3868.x = _2956.x;\n        _3868.y = _2956.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3868;\n        _3762 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _467_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2985 = fa_tex_fix(param_12, param_13);\n    float4 _3871 = mrt;\n    _3871.x = _2985.x;\n    _3871.y = _2985.y;\n    _3871.z = _2985.z;\n    mrt = _3871;\n    float4 _3013 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _467_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3013.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3025 = fa_tex_fix(param_16, param_17);\n    float param_18 = _467_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3055 = fa_tex_fix(param_20, param_21);\n    float _3767 = _467_fa_layers_a.x;\n    float _3768 = _467_fa_layers_a.y;\n    float _3771 = _467_fa_layers_a.z;\n    float _3770 = _467_fa_layers_b.w;\n    float _3773 = _467_fa_layers_c.x;\n    if (_467_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_467_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3767 *= _3025.y;\n            _3768 *= _3025.z;\n            _3770 *= _3013.w;\n        }\n        if (_467_fa_layers_c.z > 1.5f)\n        {\n            _3771 *= mrt.x;\n            _3773 *= mrt.w;\n        }\n    }\n    Surface _3792 = { _2915.xyz, _2915.w, _3762, clamp(_467_fa_pbr.x * _2985.z, 0.0f, 1.0f), clamp(_467_fa_pbr.y * _2985.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_467_fa_maps.y * (_3025.x - 1.0f)), _467_fa_emissive.xyz + (_467_fa_model_emissive.xyz * _3055), _3767, _3768, _467_fa_layers_b.xyz, _3770, _3771, _467_fa_layers_a.w, _3773, _467_fa_layers_c.y, _467_fa_layers_d.xyz };\n    return _3792;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _3888;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_467_fa_cl_info.x) + int(_467_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _341 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _347 = fa_light_texel(param_1);\n    float _350 = _347.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _356 = _350 < 0.5f;\n    float3 l;\n    if (_356)\n    {\n        l = normalize(_341.xyz);\n    }\n    else\n    {\n        float3 _368 = _341.xyz - world_pos;\n        float _370 = length(_368);\n        dist = _370;\n        l = _368 / max(_370, 9.9999997473787516355514526367188e-05f).xxx;\n        float _385 = _370 / max(_341.w, 0.001000000047497451305389404296875f);\n        float _391 = clamp(1.0f - (_385 * _385), 0.0f, 1.0f);\n        atten = _391 * _391;\n        if (_350 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _405 = fa_light_texel(param_2);\n            float _415 = _405.w;\n            int param_3 = (li * 4) + 3;\n            float4 _421 = fa_light_texel(param_3);\n            float _422 = _421.x;\n            float cos_inner = _422;\n            if (_422 > 1.5f)\n            {\n                cos_inner = lerp(_415, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_415, cos_inner, dot(-l, normalize(_405.xyz)));\n        }\n    }\n    int _453;\n    if (_356)\n    {\n        _453 = 0;\n    }\n    else\n    {\n        _453 = (_350 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3598 = { l, _347.xyz * atten, atten, 1.0f, dist, _453 };\n    return _3598;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2685 = n < 0;\n    bool _2692;\n    if (!_2685)\n    {\n        _2692 = n >= fa_light_count();\n    }\n    else\n    {\n        _2692 = _2685;\n    }\n    if (_2692)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _2700 = fa_cl_light(param);\n    bool _2703 = fa_lm.z > 0.5f;\n    bool _2709;\n    if (_2703)\n    {\n        int param_1 = _2700;\n        _2709 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _2709 = _2703;\n    }\n    if (_2709)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _2700;\n    float3 param_3 = i.world_pos;\n    return fa_light_sample(param_2, param_3);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _693;\n    if (i == 0)\n    {\n        _693 = _703_fa_shadow_split.x;\n    }\n    else\n    {\n        float _709;\n        if (i == 1)\n        {\n            _709 = _703_fa_shadow_split.y;\n        }\n        else\n        {\n            float _717;\n            if (i == 2)\n            {\n                _717 = _703_fa_shadow_split.z;\n            }\n            else\n            {\n                _717 = _703_fa_shadow_split.w;\n            }\n            _709 = _717;\n        }\n        _693 = _709;\n    }\n    return _693;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _750 = fa_shadow_depth(param, param_1);\n    float _754;\n    if (conv.x < 0.5f)\n    {\n        _754 = _750;\n    }\n    else\n    {\n        _754 = (conv.y * conv.z) / (conv.z - (_750 * (conv.z - conv.y)));\n    }\n    return _754;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _681 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_681), sin(_681)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _800 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _814 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _800;\n            float2 _833 = fa_shadow_vogel(param_3, param_4, param_5) * _814;\n            float2 param_6 = uv + (_833 * _703_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _845 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_845 < (zr - (length(_833) * plane)))\n            {\n                sum += _845;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _889 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _889; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _889;\n        float param_11 = _800;\n        float2 _908 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_908 * _703_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_908) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_889);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _950 = max(_703_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _955 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _961 = sqrt(1.0f - (_955 * _955));\n    float _969 = min(_961 / max(_955, 0.20000000298023223876953125f), 4.0f);\n    float _974;\n    if (_703_fa_shadow_bias.y > 0.0f)\n    {\n        _974 = _703_fa_shadow_bias.y;\n    }\n    else\n    {\n        _974 = 1.5f * _703_fa_shadow_info[ci].x;\n    }\n    float4 _999 = mul(float4(world + (n * (_974 * _961)), 1.0f), _703_fa_shadow_mat[ci]);\n    float _1006 = _999.x;\n    bool _1009 = _1006 < _703_fa_shadow_rect[ci].x;\n    bool _1018;\n    if (!_1009)\n    {\n        _1018 = _1006 > _703_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1018 = _1009;\n    }\n    bool _1027;\n    if (!_1018)\n    {\n        _1027 = _999.y < _703_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1027 = _1018;\n    }\n    bool _1036;\n    if (!_1027)\n    {\n        _1036 = _999.y > _703_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1036 = _1027;\n    }\n    bool _1043;\n    if (!_1036)\n    {\n        _1043 = _999.z > 1.0f;\n    }\n    else\n    {\n        _1043 = _1036;\n    }\n    if (_1043)\n    {\n        return -1.0f;\n    }\n    float _1052;\n    if (_703_fa_shadow_bias.x > 0.0f)\n    {\n        _1052 = _703_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1052 = 1.5f * _703_fa_shadow_info[ci].x;\n    }\n    float2 param = _999.xy;\n    float4 param_1 = _703_fa_shadow_rect[ci];\n    float param_2 = _999.z - ((_1052 * (1.0f + (0.5f * _969))) / _950);\n    float param_3 = _703_fa_shadow_info[ci].x;\n    float param_4 = _950;\n    float param_5 = _950 * 0.25f;\n    float param_6 = ((_703_fa_shadow_info[ci].x * min(_969, 3.0f)) * 0.5f) / _950;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_703_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _703_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_467_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1480 = int(_703_fa_shadow_cfg.x + 0.5f);\n    if (_1480 < 1)\n    {\n        return 1.0f;\n    }\n    float _1496 = dot(world - _703_fa_shadow_eye.xyz, _703_fa_shadow_fwd.xyz);\n    int param = _1480 - 1;\n    if (_1496 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1508 = _1480 > 1;\n    bool _1515;\n    if (_1508)\n    {\n        _1515 = _1496 > _703_fa_shadow_split.x;\n    }\n    else\n    {\n        _1515 = _1508;\n    }\n    if (_1515)\n    {\n        ci = 1;\n    }\n    bool _1519 = _1480 > 2;\n    bool _1526;\n    if (_1519)\n    {\n        _1526 = _1496 > _703_fa_shadow_split.y;\n    }\n    else\n    {\n        _1526 = _1519;\n    }\n    if (_1526)\n    {\n        ci = 2;\n    }\n    bool _1530 = _1480 > 3;\n    bool _1537;\n    if (_1530)\n    {\n        _1537 = _1496 > _703_fa_shadow_split.z;\n    }\n    else\n    {\n        _1537 = _1530;\n    }\n    if (_1537)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1480)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1563 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1563;\n        if (_1563 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_703_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1588;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1588 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1588 = _703_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1607 = _703_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1588, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1618 = clamp((_1496 - (fa_shadow_split_at(param_7) - _1607)) / _1607, 0.0f, 1.0f);\n        if (_1618 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1480)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1639 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1639;\n                if (_1639 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1618);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1111 = _467_fa_pbr.z < 0.5f;\n    bool _1119;\n    if (!_1111)\n    {\n        _1119 = _703_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1119 = _1111;\n    }\n    if (_1119)\n    {\n        return 1.0f;\n    }\n    int param = (int(_703_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1132 = fa_light_texel(param);\n    float _1133 = _1132.x;\n    if (_1133 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1142 = int(_1133 + 0.5f);\n    int param_1 = _1142;\n    float4 _1146 = fa_light_texel(param_1);\n    int param_2 = _1142 + 1;\n    float4 _1151 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1154 = _1146.y;\n    if (_1154 > 0.0f)\n    {\n        float _1171 = 1.0f - smoothstep(0.75f * _1154, _1154, length(world - _703_fa_shadow_eye.xyz));\n        fade = _1171;\n        if (_1171 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1146.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1190 = world - fa_light_texel(param_3).xyz;\n        float3 _1193 = abs(_1190);\n        float _1195 = _1193.x;\n        float _1197 = _1193.y;\n        bool _1198 = _1195 >= _1197;\n        bool _1206;\n        if (_1198)\n        {\n            _1206 = _1195 >= _1193.z;\n        }\n        else\n        {\n            _1206 = _1198;\n        }\n        int _1207;\n        if (_1206)\n        {\n            _1207 = (_1190.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1220;\n            if (_1197 >= _1193.z)\n            {\n                _1220 = (_1190.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1220 = (_1190.z > 0.0f) ? 4 : 5;\n            }\n            _1207 = _1220;\n        }\n        face = _1207;\n    }\n    int _1239 = (_1142 + 2) + (face * 6);\n    int param_4 = _1239;\n    int param_5 = _1239 + 1;\n    int param_6 = _1239 + 3;\n    float4 _1253 = fa_light_texel(param_6);\n    int param_7 = _1239 + 4;\n    float4 _1258 = fa_light_texel(param_7);\n    int param_8 = _1239 + 5;\n    float4 _1263 = fa_light_texel(param_8);\n    float _1275 = _1263.x * max(dot(_1253, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1280 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1303 = clamp(dot(n, _1253.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1326 = min(sqrt(1.0f - (_1303 * _1303)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1253, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1329 = _1151.y;\n    float _1331;\n    if (_1329 > 0.0f)\n    {\n        _1331 = _1329;\n    }\n    else\n    {\n        _1331 = 1.5f * _1275;\n    }\n    float4 _1351 = float4(world + (n * (_1331 * sqrt(1.0f - (_1280 * _1280)))), 1.0f);\n    float _1355 = dot(_1253, _1351);\n    float _1358 = _1263.y;\n    if (_1355 < _1358)\n    {\n        return 1.0f;\n    }\n    float2 _1373 = float2(dot(fa_light_texel(param_4), _1351), dot(fa_light_texel(param_5), _1351)) / _1355.xx;\n    float _1375 = _1373.x;\n    bool _1378 = _1375 < _1258.x;\n    bool _1387;\n    if (!_1378)\n    {\n        _1387 = _1375 > _1258.z;\n    }\n    else\n    {\n        _1387 = _1378;\n    }\n    bool _1396;\n    if (!_1387)\n    {\n        _1396 = _1373.y < _1258.y;\n    }\n    else\n    {\n        _1396 = _1387;\n    }\n    bool _1405;\n    if (!_1396)\n    {\n        _1405 = _1373.y > _1258.w;\n    }\n    else\n    {\n        _1405 = _1396;\n    }\n    if (_1405)\n    {\n        return 1.0f;\n    }\n    float _1411 = _1151.x;\n    float _1413;\n    if (_1411 > 0.0f)\n    {\n        _1413 = _1411;\n    }\n    else\n    {\n        _1413 = 1.5f * _1275;\n    }\n    float2 param_10 = _1373;\n    float4 param_11 = _1258;\n    float param_12 = _1355 - (_1413 * (1.0f + (0.5f * _1326)));\n    float param_13 = _1275;\n    float param_14 = 1.0f;\n    float param_15 = _1263.z * 0.25f;\n    float param_16 = (_1275 * min(_1326, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1358, _1263.z);\n    int param_18 = int(_1146.z + 0.5f);\n    float param_19 = _1146.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2571 = fa_lm.z > 0.5f;\n    bool _2577;\n    if (_2571)\n    {\n        int param = li;\n        _2577 = fa_light_baked(param);\n    }\n    else\n    {\n        _2577 = _2571;\n    }\n    if (_2577)\n    {\n        int param_1 = li;\n        LightSample _3731 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _3731;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2599 = fa_light_sample(param_2, param_3);\n    float3 _3738 = _2599.direction;\n    float3 _3733 = _2599.color;\n    float _3740 = _2599.attenuation;\n    float _3735 = _2599.shadow;\n    int _3743 = _2599.type;\n    if ((_3743 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3738;\n        float _2613 = fa_shadow_factor(param_4, param_5);\n        _3735 = _2613;\n        _3733 *= _2613;\n    }\n    else\n    {\n        bool _2624 = _3743 != 0;\n        bool _2630;\n        if (_2624)\n        {\n            _2630 = _3740 > 0.0f;\n        }\n        else\n        {\n            _2630 = _2624;\n        }\n        if (_2630)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3738;\n            float _2642 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3735 = _2642;\n            _3733 *= _2642;\n        }\n    }\n    LightSample _3750 = { _3738, _3733, _3740, _3735, _2599._distance, _3743 };\n    return _3750;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2659 = n < 0;\n    bool _2666;\n    if (!_2659)\n    {\n        _2666 = n >= fa_light_count();\n    }\n    else\n    {\n        _2666 = _2659;\n    }\n    if (_2666)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1921 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1929 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1932 = int(_1921);\n    int _1935 = int(_1929);\n    float _1945 = _1929 - float(_1935);\n    int _2001 = (_1932 * 9) + _1935;\n    int _2021 = ((_1932 + 1) * 9) + _1935;\n    return lerp(lerp(_1996[_2001], _1996[_2001 + 1], _1945), lerp(_1996[_2021], _1996[_2021 + 1], _1945), _1921 - float(_1932));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3599 = false;\n    float _3600 = 1.0f;\n    float _3601 = 1.0f;\n    float _3602 = 1.0f;\n    float _3603 = 0.0f;\n    float _3604 = 0.0f;\n    float _3605 = 0.0f;\n    float _3606 = 0.0f;\n    float _3608 = 1.0f;\n    bool _3609 = false;\n    float3 _3610 = 0.0f.xxx;\n    float _3611 = 1.0f;\n    float _3612 = 1.0f;\n    float _3613 = 1.0f;\n    float _3614 = 0.0f;\n    float _3615 = 0.0f;\n    float3 _3616 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3617 = float3(0.0f, 0.0f, 1.0f);\n    float _3618 = 1.0f;\n    float _3619 = 1.0f;\n    float _2074 = clamp(s.specular, 0.0f, 1.0f);\n    float _2078 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2083 = (_2074 != 1.0f) || (_2078 != 1.5f);\n    bool _2093;\n    if (!_2083)\n    {\n        _2093 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2093 = _2083;\n    }\n    if (_2093)\n    {\n        float _2101 = (_2078 - 1.0f) / (_2078 + 1.0f);\n        f0 = lerp(min((_2101 * _2101).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2074, s.albedo, metallic.xxx);\n        _3600 = lerp(_2074, 1.0f, metallic);\n        _3599 = true;\n    }\n    float _2129 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2129 > 0.0f)\n    {\n        float _2137 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3603 = _2129;\n        _3604 = _2137;\n        float _2144 = _2137 * _2137;\n        _3605 = _2144;\n        _3606 = _2144 * _2144;\n        float _2156 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3608 = _2156;\n        _3601 = 1.0f - (_2129 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2156, 0.0f, 1.0f), 5.0f))));\n        _3599 = true;\n    }\n    float3 _2176 = max(s.sheen_color, 0.0f.xxx);\n    float _2185 = max(_2176.x, max(_2176.y, _2176.z));\n    if (_2185 > 0.0f)\n    {\n        float _2193 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3609 = true;\n        _3610 = _2176;\n        _3611 = _2193;\n        _3612 = _2193 * _2193;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2193;\n        float _2210 = fa_sheen_albedo(param, param_1);\n        _3614 = _2210;\n        _3613 = 1.0f - min(_2185 * _2210, 1.0f);\n        _3599 = true;\n    }\n    _3602 = _3601 * _3613;\n    float _2229 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2229 != 0.0f)\n    {\n        float3 _2244 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2244;\n        if (dot(_2244, _2244) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2258 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2258.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2258.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2258.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2262 = t;\n        float3 _2263 = normalize(_2262);\n        t = _2263;\n        float3 _2288 = normalize((_2263 * cos(s.anisotropy_rotation)) + ((cross(n, _2263) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3616 = _2288;\n        _3617 = cross(n, _2288);\n        float _2298 = roughness * roughness;\n        float _2304 = lerp(_2298, 1.0f, _2229 * _2229);\n        bool _2306 = _2229 > 0.0f;\n        _3618 = _2306 ? _2304 : _2298;\n        _3619 = _2306 ? _2298 : _2304;\n        _3615 = _2229;\n        _3599 = true;\n    }\n    FaLayers _3641 = { _3599, _3600, _3601, _3602, _3603, _3604, _3605, _3606, i.world_normal, _3608, _3609, _3610, _3611, _3612, _3613, _3614, _3615, _3616, _3617, _3618, _3619 };\n    return _3641;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1853 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1856 = _1853.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1856 * _1856, exp2((-9.27999973297119140625f) * ndv)) * _1856) + _1853.y)) + _1853.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_467_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _467_fa_env_horizon.w).xyz;\n    }\n    float _1776 = rough * rough;\n    float _1806 = 0.60000002384185791015625f * _1776;\n    return lerp(lerp(_467_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_467_fa_env_horizon.xyz, _467_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1776)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1806, 0.0500000007450580596923828125f + _1806, d.y).xxx), ((_467_fa_env_sky.xyz + _467_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1776 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2339;\n        if (L.aniso >= 0.0f)\n        {\n            _2339 = L.b;\n        }\n        else\n        {\n            _2339 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2339, v), _2339), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2372 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2372.x) + (L.f90.xxx * _2372.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2427 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2427.x) + _2427.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1895 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1895.x) + _1895.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2466 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2470 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2477 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2466.xxx);\n    float3 f0 = _2477;\n    float3 _2481 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2481;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2466;\n    float param_5 = _2470;\n    float3 param_6 = _2477;\n    FaLayers _2498 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2498.on)\n    {\n        FaLayers param_7 = _2498;\n        float3 param_8 = _2481;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2470;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2481;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2470;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2747 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_2747 > bestPower)\n        {\n            bestPower = _2747;\n            best = n;\n        }\n    }\n    float3 lit = (_467_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2776 = fa_light(param_2, param_3);\n        float _2784;\n        if (dot(s.normal, _2776.direction) > 0.5f)\n        {\n            _2784 = 1.0f;\n        }\n        else\n        {\n            _2784 = _2790_dark;\n        }\n        lit += ((s.albedo * _2776.color) * _2784);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _2790_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_703_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1663 = int(_703_fa_shadow_cfg.x + 0.5f);\n    float _1673 = dot(world - _703_fa_shadow_eye.xyz, _703_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1678 = _1663 > 0;\n    bool _1687;\n    if (_1678)\n    {\n        int param = _1663 - 1;\n        _1687 = _1673 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1687 = _1678;\n    }\n    if (_1687)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1694 = _1663 > 1;\n        bool _1701;\n        if (_1694)\n        {\n            _1701 = _1673 > _703_fa_shadow_split.x;\n        }\n        else\n        {\n            _1701 = _1694;\n        }\n        if (_1701)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1707 = _1663 > 2;\n        bool _1714;\n        if (_1707)\n        {\n            _1714 = _1673 > _703_fa_shadow_split.y;\n        }\n        else\n        {\n            _1714 = _1707;\n        }\n        if (_1714)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1720 = _1663 > 3;\n        bool _1727;\n        if (_1720)\n        {\n            _1727 = _1673 > _703_fa_shadow_split.z;\n        }\n        else\n        {\n            _1727 = _1720;\n        }\n        if (_1727)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3473 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3473 = -_3473;\n    }\n    float3 _3176 = normalize(_467_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3486 = { fa_world_pos, _3473, fa_world_tangent, fa_uv, fa_vertex_color, _3176, gl_FrontFacing };\n    SurfaceInput param_1 = _3486;\n    Surface _3184 = fa_standard_surface(param_1);\n    float3 _3504 = _3184.albedo;\n    float _3505 = _3184.alpha;\n    float3 _3506 = _3184.normal;\n    float _3507 = _3184.metallic;\n    float _3508 = _3184.roughness;\n    float _3509 = _3184.occlusion;\n    float3 _3510 = _3184.emission;\n    float _3511 = _3184.clearcoat;\n    float _3512 = _3184.clearcoat_roughness;\n    float3 _3513 = _3184.sheen_color;\n    float _3514 = _3184.sheen_roughness;\n    float _3515 = _3184.anisotropy;\n    float _3516 = _3184.anisotropy_rotation;\n    float _3517 = _3184.specular;\n    float _3518 = _3184.ior;\n    float3 _3519 = _3184.specular_color;\n    SurfaceInput _3494 = { fa_world_pos, _3473, fa_world_tangent, fa_uv, fa_vertex_color, _3176, gl_FrontFacing };\n    SurfaceInput param_2 = _3494;\n    Surface param_3 = _3184;\n    surface(param_2, param_3);\n    _3504 = param_3.albedo;\n    _3505 = param_3.alpha;\n    _3506 = param_3.normal;\n    _3507 = param_3.metallic;\n    _3508 = param_3.roughness;\n    _3509 = param_3.occlusion;\n    _3510 = param_3.emission;\n    _3511 = param_3.clearcoat;\n    _3512 = param_3.clearcoat_roughness;\n    _3513 = param_3.sheen_color;\n    _3514 = param_3.sheen_roughness;\n    _3515 = param_3.anisotropy;\n    _3516 = param_3.anisotropy_rotation;\n    _3517 = param_3.specular;\n    _3518 = param_3.ior;\n    _3519 = param_3.specular_color;\n    float3 result;\n    if (_467_fa_emissive.w > 0.5f)\n    {\n        result = _3504;\n    }\n    else\n    {\n        float3 _3205 = _3506;\n        float3 _3206 = normalize(_3205);\n        _3506 = _3206;\n        SurfaceInput _3502 = { fa_world_pos, _3473, fa_world_tangent, fa_uv, fa_vertex_color, _3176, gl_FrontFacing };\n        SurfaceInput param_4 = _3502;\n        Surface _3585 = { _3504, _3505, _3206, _3507, _3508, _3509, _3510, _3511, _3512, _3513, _3514, _3515, _3516, _3517, _3518, _3519 };\n        Surface param_5 = _3585;\n        result = lighting(param_4, param_5);\n    }\n    float3 _3221 = result;\n    float3 _3222 = _3221 + _3510;\n    result = _3222;\n    float3 param_6 = _3222;\n    float3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _3231 = _467_fa_fog.w > 0.0f;\n    bool _3238;\n    if (!_3231)\n    {\n        _3238 = _467_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3238 = _3231;\n    }\n    if (_3238)\n    {\n        float3 _3247 = fa_world_pos - _467_fa_camera_pos.xyz;\n        float _3253 = dot(_3247, _467_fa_fog_c.xyz);\n        bool _3257 = _467_fa_fog_c.w > 0.5f;\n        float _3258;\n        if (_3257)\n        {\n            _3258 = _3253;\n        }\n        else\n        {\n            _3258 = length(_3247);\n        }\n        float _3270 = _3258 - _467_fa_fog_b.x;\n        if (_3270 > 0.0f)\n        {\n            float _3279 = _467_fa_fog.w * _3270;\n            float tau = _3279 * _3279;\n            if (_467_fa_fog_b.y > 0.0f)\n            {\n                float _3295;\n                if (_3257)\n                {\n                    _3295 = fa_world_pos.y - (_467_fa_fog_c.y * _3253);\n                }\n                else\n                {\n                    _3295 = _467_fa_camera_pos.y;\n                }\n                float _3316 = lerp(_3295, fa_world_pos.y, clamp(_467_fa_fog_b.x / _3258, 0.0f, 1.0f));\n                float _3320 = fa_world_pos.y - _3316;\n                float _3325 = _3316 - _467_fa_fog_b.z;\n                float _3330 = fa_world_pos.y - _467_fa_fog_b.z;\n                bool _3333 = _3325 <= 0.0f;\n                bool _3334 = !_3333;\n                bool _3340;\n                if (_3334)\n                {\n                    _3340 = _467_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3340 = _3333;\n                }\n                float _3341;\n                if (_3340)\n                {\n                    _3341 = _467_fa_fog_b.y;\n                }\n                else\n                {\n                    _3341 = _467_fa_fog_b.y * exp(-min(_467_fa_fog_b.w * _3325, 80.0f));\n                }\n                bool _3368;\n                if (_3334)\n                {\n                    _3368 = _467_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3368 = _3333;\n                }\n                float _3369;\n                if (_3368)\n                {\n                    _3369 = _467_fa_fog_b.y * _3325;\n                }\n                else\n                {\n                    _3369 = (_467_fa_fog_b.y * (1.0f - exp(-min(_467_fa_fog_b.w * _3325, 80.0f)))) / _467_fa_fog_b.w;\n                }\n                bool _3394 = _3330 <= 0.0f;\n                bool _3401;\n                if (!_3394)\n                {\n                    _3401 = _467_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3401 = _3394;\n                }\n                float _3402;\n                if (_3401)\n                {\n                    _3402 = _467_fa_fog_b.y * _3330;\n                }\n                else\n                {\n                    _3402 = (_467_fa_fog_b.y * (1.0f - exp(-min(_467_fa_fog_b.w * _3330, 80.0f)))) / _467_fa_fog_b.w;\n                }\n                float _3429;\n                if (abs(_3320) < 0.001000000047497451305389404296875f)\n                {\n                    _3429 = _3341;\n                }\n                else\n                {\n                    _3429 = (_3402 - _3369) / _3320;\n                }\n                tau += (_3270 * max(_3429, 0.0f));\n            }\n            result = lerp(result, _467_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3505);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_467",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_703",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2790",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _295 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _295;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0f);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _786 = base_t;\n    _786.x = _225.x;\n    _786.y = _225.y;\n    _786.z = _225.z;\n    base_t = _786;\n    float4 _241 = (_786 * _213_fa_base_color) * i.vertex_color;\n    float3 _749 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _794 = _279;\n        _794.x = _284.x;\n        _794.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _794;\n        _749 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _797 = mrt;\n    _797.x = _313.x;\n    _797.y = _313.y;\n    _797.z = _313.z;\n    mrt = _797;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _754 = _213_fa_layers_a.x;\n    float _755 = _213_fa_layers_a.y;\n    float _758 = _213_fa_layers_a.z;\n    float _757 = _213_fa_layers_b.w;\n    float _760 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _754 *= _355.y;\n            _755 *= _355.z;\n            _757 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _758 *= mrt.x;\n            _760 *= mrt.w;\n        }\n    }\n    Surface _779 = { _241.xyz, _241.w, _749, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _754, _755, _213_fa_layers_b.xyz, _757, _758, _213_fa_layers_a.w, _760, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _779;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _660 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _660 = -_660;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _673 = { fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _673;\n    SurfaceInput _681 = { fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _681;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _416 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _416;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0f);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _786 = base_t;\n    _786.x = _225.x;\n    _786.y = _225.y;\n    _786.z = _225.z;\n    base_t = _786;\n    float4 _241 = (_786 * _213_fa_base_color) * i.vertex_color;\n    float3 _749 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _794 = _279;\n        _794.x = _284.x;\n        _794.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _794;\n        _749 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _797 = mrt;\n    _797.x = _313.x;\n    _797.y = _313.y;\n    _797.z = _313.z;\n    mrt = _797;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _754 = _213_fa_layers_a.x;\n    float _755 = _213_fa_layers_a.y;\n    float _758 = _213_fa_layers_a.z;\n    float _757 = _213_fa_layers_b.w;\n    float _760 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _754 *= _355.y;\n            _755 *= _355.z;\n            _757 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _758 *= mrt.x;\n            _760 *= mrt.w;\n        }\n    }\n    Surface _779 = { _241.xyz, _241.w, _749, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _754, _755, _213_fa_layers_b.xyz, _757, _758, _213_fa_layers_a.w, _760, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _779;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _660 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _660 = -_660;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _673 = { fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _673;\n    SurfaceInput _681 = { fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _681;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
    }
  }
}
