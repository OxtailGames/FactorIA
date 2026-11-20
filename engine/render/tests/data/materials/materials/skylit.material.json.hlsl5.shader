{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "738bdbaa5d236ca82c68b48e7af94b35c54ba5d6311eabf2bcbbc814ba3d221c",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _258 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _258;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_265, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1877[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _283_fa_camera_pos : packoffset(c0);\n    float4 _283_fa_ambient : packoffset(c1);\n    float4 _283_fa_base_color : packoffset(c2);\n    float4 _283_fa_emissive : packoffset(c3);\n    float4 _283_fa_model_emissive : packoffset(c4);\n    float4 _283_fa_pbr : packoffset(c5);\n    float4 _283_fa_maps : packoffset(c6);\n    float4 _283_fa_fog : packoffset(c7);\n    float4 _283_fa_fog_b : packoffset(c8);\n    float4 _283_fa_fog_c : packoffset(c9);\n    float4 _283_fa_counts : packoffset(c10);\n    float4 _283_fa_env_sky : packoffset(c11);\n    float4 _283_fa_env_horizon : packoffset(c12);\n    float4 _283_fa_time : packoffset(c13);\n    float4 _283_fa_cl_vpx : packoffset(c14);\n    float4 _283_fa_cl_vpy : packoffset(c15);\n    float4 _283_fa_cl_vpw : packoffset(c16);\n    float4 _283_fa_cl_fwd : packoffset(c17);\n    float4 _283_fa_cl_grid : packoffset(c18);\n    float4 _283_fa_cl_info : packoffset(c19);\n    float4 _283_fa_layers_a : packoffset(c20);\n    float4 _283_fa_layers_b : packoffset(c21);\n    float4 _283_fa_layers_c : packoffset(c22);\n    float4 _283_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _986_fa_shadow_mat[4] : packoffset(c0);\n    float4 _986_fa_shadow_rect[4] : packoffset(c16);\n    float4 _986_fa_shadow_info[4] : packoffset(c20);\n    float4 _986_fa_shadow_split : packoffset(c24);\n    float4 _986_fa_shadow_cfg : packoffset(c25);\n    float4 _986_fa_shadow_bias : packoffset(c26);\n    float4 _986_fa_shadow_eye : packoffset(c27);\n    float4 _986_fa_shadow_fwd : packoffset(c28);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _755 = _283_fa_cl_info.x < 0.0f;\n    bool _762;\n    if (!_755)\n    {\n        _762 = _283_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _762 = _755;\n    }\n    bool _770;\n    if (!_762)\n    {\n        _770 = _283_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _770 = _762;\n    }\n    bool _777;\n    if (!_770)\n    {\n        _777 = _283_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _777 = _770;\n    }\n    bool _784;\n    if (!_777)\n    {\n        _784 = _283_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _784 = _777;\n    }\n    if (_784)\n    {\n        return int2(0, 0);\n    }\n    float4 _794 = float4(world_pos, 1.0f);\n    float _801 = dot(_283_fa_cl_vpw, _794);\n    if (!(_801 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _823 = float2(dot(_283_fa_cl_vpx, _794), dot(_283_fa_cl_vpy, _794)) / _801.xx;\n    int _827 = int(_283_fa_cl_grid.x);\n    int _831 = int(_283_fa_cl_grid.y);\n    int param = (int(_283_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_283_fa_cl_fwd.xyz, world_pos) + _283_fa_cl_fwd.w, _283_fa_cl_grid.w) / _283_fa_cl_grid.w) * _283_fa_cl_grid.z)), 0, int(_283_fa_cl_info.y) - 1) * _831) + clamp(int(floor(((_823.y * 0.5f) + 0.5f) * _283_fa_cl_grid.y)), 0, _831 - 1)) * _827)) + clamp(int(floor(((_823.x * 0.5f) + 0.5f) * _283_fa_cl_grid.x)), 0, _827 - 1);\n    float4 _902 = fa_light_texel(param);\n    return int2(int(_902.x), int(_902.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_283_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2415 = fa_cluster_lookup(param);\n    fa_cl_slot = _2415.x;\n    fa_cl_local = _2415.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2524 = fa_linear_to_srgb(param);\n        c = _2524;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2532 = fa_srgb_to_linear(param_1);\n            c = _2532;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _215;\n    if (i.front_facing)\n    {\n        _215 = i.world_normal;\n    }\n    else\n    {\n        _215 = -i.world_normal;\n    }\n    float3 _239 = normalize(i.world_tangent.xyz - (_215 * dot(_215, i.world_tangent.xyz)));\n    float3 _267 = normalize(((_239 * m.x) + ((cross(_215, _239) * i.world_tangent.w) * m.y)) + (_215 * m.z));\n    float3 _270;\n    if (i.front_facing)\n    {\n        _270 = _267;\n    }\n    else\n    {\n        _270 = -_267;\n    }\n    return _270;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _283_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2563 = fa_tex_fix(param_2, param_3);\n    float4 _3547 = base_t;\n    _3547.x = _2563.x;\n    _3547.y = _2563.y;\n    _3547.z = _2563.z;\n    base_t = _3547;\n    float4 _2577 = (_3547 * _283_fa_base_color) * i.vertex_color;\n    float3 _3471 = i.world_normal;\n    if (_283_fa_maps.z > 0.5f)\n    {\n        float param_4 = _283_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2609 = fa_tex_fix(param_6, param_7);\n        float3 _2613 = (_2609 * 2.0f) - 1.0f.xxx;\n        float2 _2618 = _2613.xy * _283_fa_maps.x;\n        float3 _3555 = _2613;\n        _3555.x = _2618.x;\n        _3555.y = _2618.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3555;\n        _3471 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _283_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2646 = fa_tex_fix(param_12, param_13);\n    float4 _3558 = mrt;\n    _3558.x = _2646.x;\n    _3558.y = _2646.y;\n    _3558.z = _2646.z;\n    mrt = _3558;\n    float4 _2674 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _283_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2674.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2686 = fa_tex_fix(param_16, param_17);\n    float param_18 = _283_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2716 = fa_tex_fix(param_20, param_21);\n    float _3476 = _283_fa_layers_a.x;\n    float _3477 = _283_fa_layers_a.y;\n    float _3480 = _283_fa_layers_a.z;\n    float _3479 = _283_fa_layers_b.w;\n    float _3482 = _283_fa_layers_c.x;\n    if (_283_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_283_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3476 *= _2686.y;\n            _3477 *= _2686.z;\n            _3479 *= _2674.w;\n        }\n        if (_283_fa_layers_c.z > 1.5f)\n        {\n            _3480 *= mrt.x;\n            _3482 *= mrt.w;\n        }\n    }\n    Surface _3501 = { _2577.xyz, _2577.w, _3471, clamp(_283_fa_pbr.x * _2646.z, 0.0f, 1.0f), clamp(_283_fa_pbr.y * _2646.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_283_fa_maps.y * (_2686.x - 1.0f)), _283_fa_emissive.xyz + (_283_fa_model_emissive.xyz * _2716), _3476, _3477, _283_fa_layers_b.xyz, _3479, _3480, _283_fa_layers_a.w, _3482, _283_fa_layers_c.y, _283_fa_layers_d.xyz };\n    return _3501;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_283_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _283_fa_ambient.xyz;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1802 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1810 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1813 = int(_1802);\n    int _1816 = int(_1810);\n    float _1826 = _1810 - float(_1816);\n    int _1882 = (_1813 * 9) + _1816;\n    int _1902 = ((_1813 + 1) * 9) + _1816;\n    return lerp(lerp(_1877[_1882], _1877[_1882 + 1], _1826), lerp(_1877[_1902], _1877[_1902 + 1], _1826), _1802 - float(_1813));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3343 = false;\n    float _3344 = 1.0f;\n    float _3345 = 1.0f;\n    float _3346 = 1.0f;\n    float _3347 = 0.0f;\n    float _3348 = 0.0f;\n    float _3349 = 0.0f;\n    float _3350 = 0.0f;\n    float _3352 = 1.0f;\n    bool _3353 = false;\n    float3 _3354 = 0.0f.xxx;\n    float _3355 = 1.0f;\n    float _3356 = 1.0f;\n    float _3357 = 1.0f;\n    float _3358 = 0.0f;\n    float _3359 = 0.0f;\n    float3 _3360 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3361 = float3(0.0f, 0.0f, 1.0f);\n    float _3362 = 1.0f;\n    float _3363 = 1.0f;\n    float _1956 = clamp(s.specular, 0.0f, 1.0f);\n    float _1960 = clamp(s.ior, 1.0f, 3.0f);\n    bool _1965 = (_1956 != 1.0f) || (_1960 != 1.5f);\n    bool _1974;\n    if (!_1965)\n    {\n        _1974 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _1974 = _1965;\n    }\n    if (_1974)\n    {\n        float _1982 = (_1960 - 1.0f) / (_1960 + 1.0f);\n        f0 = lerp(min((_1982 * _1982).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _1956, s.albedo, metallic.xxx);\n        _3344 = lerp(_1956, 1.0f, metallic);\n        _3343 = true;\n    }\n    float _2010 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2010 > 0.0f)\n    {\n        float _2018 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3347 = _2010;\n        _3348 = _2018;\n        float _2025 = _2018 * _2018;\n        _3349 = _2025;\n        _3350 = _2025 * _2025;\n        float _2037 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3352 = _2037;\n        _3345 = 1.0f - (_2010 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2037, 0.0f, 1.0f), 5.0f))));\n        _3343 = true;\n    }\n    float3 _2057 = max(s.sheen_color, 0.0f.xxx);\n    float _2066 = max(_2057.x, max(_2057.y, _2057.z));\n    if (_2066 > 0.0f)\n    {\n        float _2074 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3353 = true;\n        _3354 = _2057;\n        _3355 = _2074;\n        _3356 = _2074 * _2074;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2074;\n        float _2091 = fa_sheen_albedo(param, param_1);\n        _3358 = _2091;\n        _3357 = 1.0f - min(_2066 * _2091, 1.0f);\n        _3343 = true;\n    }\n    _3346 = _3345 * _3357;\n    float _2110 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2110 != 0.0f)\n    {\n        float3 _2125 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2125;\n        if (dot(_2125, _2125) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2139 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2139.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2139.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2139.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2143 = t;\n        float3 _2144 = normalize(_2143);\n        t = _2144;\n        float3 _2169 = normalize((_2144 * cos(s.anisotropy_rotation)) + ((cross(n, _2144) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3360 = _2169;\n        _3361 = cross(n, _2169);\n        float _2179 = roughness * roughness;\n        float _2185 = lerp(_2179, 1.0f, _2110 * _2110);\n        bool _2187 = _2110 > 0.0f;\n        _3362 = _2187 ? _2185 : _2179;\n        _3363 = _2187 ? _2179 : _2185;\n        _3359 = _2110;\n        _3343 = true;\n    }\n    FaLayers _3385 = { _3343, _3344, _3345, _3346, _3347, _3348, _3349, _3350, i.world_normal, _3352, _3353, _3354, _3355, _3356, _3357, _3358, _3359, _3360, _3361, _3362, _3363 };\n    return _3385;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1734 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1737 = _1734.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1737 * _1737, exp2((-9.27999973297119140625f) * ndv)) * _1737) + _1734.y)) + _1734.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_283_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _283_fa_env_horizon.w).xyz;\n    }\n    float _1639 = rough * rough;\n    float _1669 = 0.60000002384185791015625f * _1639;\n    return lerp(lerp(_283_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_283_fa_env_horizon.xyz, _283_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1639)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1669, 0.0500000007450580596923828125f + _1669, d.y).xxx), ((_283_fa_env_sky.xyz + _283_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1639 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2220;\n        if (L.aniso >= 0.0f)\n        {\n            _2220 = L.b;\n        }\n        else\n        {\n            _2220 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2220, v), _2220), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2253 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2253.x) + (L.f90.xxx * _2253.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2308 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2308.x) + _2308.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1776 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1776.x) + _1776.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2337 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2341 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2348 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2337.xxx);\n    float3 f0 = _2348;\n    float3 _2352 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2352;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2337;\n    float param_5 = _2341;\n    float3 param_6 = _2348;\n    FaLayers _2369 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2369.on)\n    {\n        FaLayers param_7 = _2369;\n        float3 param_8 = _2352;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2341;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2352;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2341;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_283_fa_cl_info.x) + int(_283_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_283_fa_counts.y > 4.5f) ? 8 : 4);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _324_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _324_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _364 = dot(d, right);\n    float _368 = dot(d, up);\n    float _379;\n    if (((_364 * _364) + (_368 * _368)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _379 = atan2(_368, _364) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _379 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_379 - floor(_379)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li;\n    int _412 = fa_light_base(param);\n    bool _416 = _283_fa_counts.y > 4.5f;\n    int param_1 = _412;\n    float4 _420 = fa_light_texel(param_1);\n    int param_2 = _412 + 1;\n    float4 _425 = fa_light_texel(param_2);\n    float _428 = _425.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _440 = _416 && (_428 > 2.5f);\n    fa_light_is_area = _440;\n    bool _443 = _428 < 0.5f;\n    float3 l;\n    if (_443)\n    {\n        l = normalize(_420.xyz);\n        if (_416)\n        {\n            int param_3 = _412 + 6;\n            float4 _457 = fa_light_texel(param_3);\n            if (_457.z > 0.5f)\n            {\n                int param_4 = _412 + 4;\n                float4 _467 = fa_light_texel(param_4);\n                int param_5 = _412 + 5;\n                float4 _473 = fa_light_texel(param_5);\n                float2 param_6 = _457.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _467.xyz) * _467.w, (-dot(world_pos, _473.xyz)) * _473.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _505 = _420.xyz - world_pos;\n        float _507 = length(_505);\n        dist = _507;\n        l = _505 / max(_507, 9.9999997473787516355514526367188e-05f).xxx;\n        float reach = _507;\n        if (_440)\n        {\n            int param_8 = _412 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0f);\n        }\n        float _539 = reach / max(_420.w, 0.001000000047497451305389404296875f);\n        float _545 = clamp(1.0f - (_539 * _539), 0.0f, 1.0f);\n        atten = _545 * _545;\n        bool _553 = _428 < 2.5f;\n        if ((_428 > 1.5f) && _553)\n        {\n            int param_9 = _412 + 2;\n            float4 _561 = fa_light_texel(param_9);\n            float _571 = _561.w;\n            int param_10 = _412 + 3;\n            float4 _577 = fa_light_texel(param_10);\n            float _578 = _577.x;\n            float cos_inner = _578;\n            if (_578 > 1.5f)\n            {\n                cos_inner = lerp(_571, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_571, cos_inner, dot(-l, normalize(_561.xyz)));\n        }\n        if (_416 && _553)\n        {\n            int param_11 = _412 + 6;\n            float4 _602 = fa_light_texel(param_11);\n            int param_12 = _412 + 7;\n            float4 _607 = fa_light_texel(param_12);\n            bool _610 = _602.z > 0.5f;\n            bool _617;\n            if (!_610)\n            {\n                _617 = _607.z > 0.5f;\n            }\n            else\n            {\n                _617 = _610;\n            }\n            if (_617)\n            {\n                int param_13 = _412 + 2;\n                float4 _624 = fa_light_texel(param_13);\n                float3 _628 = normalize(_624.xyz);\n                int param_14 = _412 + 4;\n                float4 _633 = fa_light_texel(param_14);\n                int param_15 = _412 + 5;\n                float4 _638 = fa_light_texel(param_15);\n                if (_610)\n                {\n                    float3 _646 = -_505;\n                    float _653 = _624.w;\n                    float _669 = 0.5f / max(dot(_646, _628) * (sqrt(max(1.0f - (_653 * _653), 0.0f)) / max(_653, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                    float2 param_16 = _602.xy;\n                    float2 param_17 = float2(0.5f + (dot(_646, _633.xyz) * _669), 0.5f - (dot(_646, _638.xyz) * _669));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_607.z > 0.5f)\n                {\n                    float2 param_18 = _607.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _628;\n                    float3 param_21 = _633.xyz;\n                    float3 param_22 = _638.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    float3 _3331 = _425.xyz * atten;\n    if (_416)\n    {\n        _3331 *= fa_light_tint;\n    }\n    int _737;\n    if (_443)\n    {\n        _737 = 0;\n    }\n    else\n    {\n        _737 = ((_428 > 1.5f) && (_428 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _3342 = { l, _3331, atten, 1.0f, dist, _737 };\n    return _3342;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _976;\n    if (i == 0)\n    {\n        _976 = _986_fa_shadow_split.x;\n    }\n    else\n    {\n        float _992;\n        if (i == 1)\n        {\n            _992 = _986_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1000;\n            if (i == 2)\n            {\n                _1000 = _986_fa_shadow_split.z;\n            }\n            else\n            {\n                _1000 = _986_fa_shadow_split.w;\n            }\n            _992 = _1000;\n        }\n        _976 = _992;\n    }\n    return _976;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _964 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_964), sin(_964)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1038 = max(_986_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1043 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1049 = sqrt(1.0f - (_1043 * _1043));\n    float _1057 = min(_1049 / max(_1043, 0.20000000298023223876953125f), 4.0f);\n    float _1062;\n    if (_986_fa_shadow_bias.y > 0.0f)\n    {\n        _1062 = _986_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1062 = 1.5f * _986_fa_shadow_info[ci].x;\n    }\n    float4 _1087 = mul(float4(world + (n * (_1062 * _1049)), 1.0f), _986_fa_shadow_mat[ci]);\n    float _1094 = _1087.x;\n    bool _1097 = _1094 < _986_fa_shadow_rect[ci].x;\n    bool _1106;\n    if (!_1097)\n    {\n        _1106 = _1094 > _986_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1106 = _1097;\n    }\n    bool _1115;\n    if (!_1106)\n    {\n        _1115 = _1087.y < _986_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1115 = _1106;\n    }\n    bool _1124;\n    if (!_1115)\n    {\n        _1124 = _1087.y > _986_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1124 = _1115;\n    }\n    bool _1131;\n    if (!_1124)\n    {\n        _1131 = _1087.z > 1.0f;\n    }\n    else\n    {\n        _1131 = _1124;\n    }\n    if (_1131)\n    {\n        return -1.0f;\n    }\n    float _1139;\n    if (_986_fa_shadow_bias.x > 0.0f)\n    {\n        _1139 = _986_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1139 = 1.5f * _986_fa_shadow_info[ci].x;\n    }\n    float _1158 = _1087.z - ((_1139 * (1.0f + (0.5f * _1057))) / _1038);\n    float _1167 = ((_986_fa_shadow_info[ci].x * min(_1057, 3.0f)) * 0.5f) / _1038;\n    int _1176 = int(_986_fa_shadow_cfg.z + 0.5f);\n    if (_1176 == 1)\n    {\n        float2 param = _1087.xy;\n        float4 param_1 = _986_fa_shadow_rect[ci];\n        float _1187 = fa_shadow_depth(param, param_1);\n        return float(_1158 <= _1187);\n    }\n    float _1194 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1197 = _1176 == 2;\n    if (_1197)\n    {\n        float _1211 = clamp(((_986_fa_shadow_cfg.w * _1038) * 0.25f) / _986_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1194;\n            float2 _1230 = fa_shadow_vogel(param_2, param_3, param_4) * _1211;\n            float2 param_5 = _1087.xy + (_1230 * _986_fa_shadow_bias.zw);\n            float4 param_6 = _986_fa_shadow_rect[ci];\n            float _1241 = fa_shadow_depth(param_5, param_6);\n            if (_1241 < (_1158 - (length(_1230) * _1167)))\n            {\n                sum += _1241;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1158 - (sum / cnt), 0.0f) * _1038) * _986_fa_shadow_cfg.w) / _986_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1285 = _1197 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1285; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1285;\n        float param_9 = _1194;\n        float2 _1304 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1087.xy + (_1304 * _986_fa_shadow_bias.zw);\n        float4 param_11 = _986_fa_shadow_rect[ci];\n        float _1315 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1158 - (length(_1304) * _1167)) <= _1315);\n    }\n    return lit / float(_1285);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_283_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1345 = int(_986_fa_shadow_cfg.x + 0.5f);\n    if (_1345 < 1)\n    {\n        return 1.0f;\n    }\n    float _1360 = dot(world - _986_fa_shadow_eye.xyz, _986_fa_shadow_fwd.xyz);\n    int param = _1345 - 1;\n    if (_1360 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1372 = _1345 > 1;\n    bool _1379;\n    if (_1372)\n    {\n        _1379 = _1360 > _986_fa_shadow_split.x;\n    }\n    else\n    {\n        _1379 = _1372;\n    }\n    if (_1379)\n    {\n        ci = 1;\n    }\n    bool _1383 = _1345 > 2;\n    bool _1390;\n    if (_1383)\n    {\n        _1390 = _1360 > _986_fa_shadow_split.y;\n    }\n    else\n    {\n        _1390 = _1383;\n    }\n    if (_1390)\n    {\n        ci = 2;\n    }\n    bool _1394 = _1345 > 3;\n    bool _1401;\n    if (_1394)\n    {\n        _1401 = _1360 > _986_fa_shadow_split.z;\n    }\n    else\n    {\n        _1401 = _1394;\n    }\n    if (_1401)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1345)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1427 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1427;\n        if (_1427 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_986_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1452;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1452 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1452 = _986_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1471 = _986_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1452, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1482 = clamp((_1360 - (fa_shadow_split_at(param_7) - _1471)) / _1471, 0.0f, 1.0f);\n        if (_1482 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1345)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1503 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1503;\n                if (_1503 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1482);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2443 = fa_light_sample(param, param_1);\n    float3 _3451 = _2443.color;\n    float _3453 = _2443.shadow;\n    if ((_2443.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2443.direction;\n        float _2457 = fa_shadow_factor(param_2, param_3);\n        _3453 = _2457;\n        _3451 *= _2457;\n    }\n    LightSample _3468 = { _2443.direction, _3451, _2443.attenuation, _3453, _2443._distance, _2443.type };\n    return _3468;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_986_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1527 = int(_986_fa_shadow_cfg.x + 0.5f);\n    float _1537 = dot(world - _986_fa_shadow_eye.xyz, _986_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1542 = _1527 > 0;\n    bool _1551;\n    if (_1542)\n    {\n        int param = _1527 - 1;\n        _1551 = _1537 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1551 = _1542;\n    }\n    if (_1551)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1558 = _1527 > 1;\n        bool _1565;\n        if (_1558)\n        {\n            _1565 = _1537 > _986_fa_shadow_split.x;\n        }\n        else\n        {\n            _1565 = _1558;\n        }\n        if (_1565)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1571 = _1527 > 2;\n        bool _1578;\n        if (_1571)\n        {\n            _1578 = _1537 > _986_fa_shadow_split.y;\n        }\n        else\n        {\n            _1578 = _1571;\n        }\n        if (_1578)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1584 = _1527 > 3;\n        bool _1591;\n        if (_1584)\n        {\n            _1591 = _1537 > _986_fa_shadow_split.z;\n        }\n        else\n        {\n            _1591 = _1584;\n        }\n        if (_1591)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3173 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3173 = -_3173;\n    }\n    float3 _2837 = normalize(_283_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3186 = { fa_world_pos, _3173, fa_world_tangent, fa_uv, fa_vertex_color, _2837, gl_FrontFacing };\n    SurfaceInput param_1 = _3186;\n    Surface _2845 = fa_standard_surface(param_1);\n    float3 _3212 = _2845.albedo;\n    float _3213 = _2845.alpha;\n    float3 _3214 = _2845.normal;\n    float _3215 = _2845.metallic;\n    float _3216 = _2845.roughness;\n    float _3217 = _2845.occlusion;\n    float3 _3218 = _2845.emission;\n    float _3219 = _2845.clearcoat;\n    float _3220 = _2845.clearcoat_roughness;\n    float3 _3221 = _2845.sheen_color;\n    float _3222 = _2845.sheen_roughness;\n    float _3223 = _2845.anisotropy;\n    float _3224 = _2845.anisotropy_rotation;\n    float _3225 = _2845.specular;\n    float _3226 = _2845.ior;\n    float3 _3227 = _2845.specular_color;\n    SurfaceInput _3194 = { fa_world_pos, _3173, fa_world_tangent, fa_uv, fa_vertex_color, _2837, gl_FrontFacing };\n    SurfaceInput param_2 = _3194;\n    Surface param_3 = _2845;\n    surface(param_2, param_3);\n    _3212 = param_3.albedo;\n    _3213 = param_3.alpha;\n    _3214 = param_3.normal;\n    _3215 = param_3.metallic;\n    _3216 = param_3.roughness;\n    _3217 = param_3.occlusion;\n    _3218 = param_3.emission;\n    _3219 = param_3.clearcoat;\n    _3220 = param_3.clearcoat_roughness;\n    _3221 = param_3.sheen_color;\n    _3222 = param_3.sheen_roughness;\n    _3223 = param_3.anisotropy;\n    _3224 = param_3.anisotropy_rotation;\n    _3225 = param_3.specular;\n    _3226 = param_3.ior;\n    _3227 = param_3.specular_color;\n    float3 result;\n    if (_283_fa_emissive.w > 0.5f)\n    {\n        result = _3212;\n    }\n    else\n    {\n        float3 _2866 = _3214;\n        float3 _2867 = normalize(_2866);\n        _3214 = _2867;\n        float3 param_4 = _2867;\n        SurfaceInput _3202 = { fa_world_pos, _3173, fa_world_tangent, fa_uv, fa_vertex_color, _2837, gl_FrontFacing };\n        SurfaceInput param_5 = _3202;\n        Surface _3293 = { _3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219, _3220, _3221, _3222, _3223, _3224, _3225, _3226, _3227 };\n        Surface param_6 = _3293;\n        float3 param_7 = fa_ambient_light(param_4);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _2886 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2886; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8);\n            float3 param_10 = fa_world_pos;\n            float3 param_11 = _3173;\n            LightSample _2908 = fa_light_shadowed(param_9, param_10, param_11);\n            SurfaceInput _3210 = { fa_world_pos, _3173, fa_world_tangent, fa_uv, fa_vertex_color, _2837, gl_FrontFacing };\n            SurfaceInput param_12 = _3210;\n            Surface _3310 = { _3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219, _3220, _3221, _3222, _3223, _3224, _3225, _3226, _3227 };\n            Surface param_13 = _3310;\n            LightSample param_14 = _2908;\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _2923 = result;\n    float3 _2924 = _2923 + _3218;\n    result = _2924;\n    float3 param_15 = _2924;\n    float3 param_16 = fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16);\n    bool _2933 = _283_fa_fog.w > 0.0f;\n    bool _2940;\n    if (!_2933)\n    {\n        _2940 = _283_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2940 = _2933;\n    }\n    if (_2940)\n    {\n        float3 _2949 = fa_world_pos - _283_fa_camera_pos.xyz;\n        float _2955 = dot(_2949, _283_fa_fog_c.xyz);\n        bool _2959 = _283_fa_fog_c.w > 0.5f;\n        float _2960;\n        if (_2959)\n        {\n            _2960 = _2955;\n        }\n        else\n        {\n            _2960 = length(_2949);\n        }\n        float _2972 = _2960 - _283_fa_fog_b.x;\n        if (_2972 > 0.0f)\n        {\n            float _2981 = _283_fa_fog.w * _2972;\n            float tau = _2981 * _2981;\n            if (_283_fa_fog_b.y > 0.0f)\n            {\n                float _2997;\n                if (_2959)\n                {\n                    _2997 = fa_world_pos.y - (_283_fa_fog_c.y * _2955);\n                }\n                else\n                {\n                    _2997 = _283_fa_camera_pos.y;\n                }\n                float _3018 = lerp(_2997, fa_world_pos.y, clamp(_283_fa_fog_b.x / _2960, 0.0f, 1.0f));\n                float _3022 = fa_world_pos.y - _3018;\n                float _3027 = _3018 - _283_fa_fog_b.z;\n                float _3032 = fa_world_pos.y - _283_fa_fog_b.z;\n                bool _3035 = _3027 <= 0.0f;\n                bool _3036 = !_3035;\n                bool _3042;\n                if (_3036)\n                {\n                    _3042 = _283_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3042 = _3035;\n                }\n                float _3043;\n                if (_3042)\n                {\n                    _3043 = _283_fa_fog_b.y;\n                }\n                else\n                {\n                    _3043 = _283_fa_fog_b.y * exp(-min(_283_fa_fog_b.w * _3027, 80.0f));\n                }\n                bool _3070;\n                if (_3036)\n                {\n                    _3070 = _283_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3070 = _3035;\n                }\n                float _3071;\n                if (_3070)\n                {\n                    _3071 = _283_fa_fog_b.y * _3027;\n                }\n                else\n                {\n                    _3071 = (_283_fa_fog_b.y * (1.0f - exp(-min(_283_fa_fog_b.w * _3027, 80.0f)))) / _283_fa_fog_b.w;\n                }\n                bool _3096 = _3032 <= 0.0f;\n                bool _3103;\n                if (!_3096)\n                {\n                    _3103 = _283_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3103 = _3096;\n                }\n                float _3104;\n                if (_3103)\n                {\n                    _3104 = _283_fa_fog_b.y * _3032;\n                }\n                else\n                {\n                    _3104 = (_283_fa_fog_b.y * (1.0f - exp(-min(_283_fa_fog_b.w * _3032, 80.0f)))) / _283_fa_fog_b.w;\n                }\n                float _3131;\n                if (abs(_3022) < 0.001000000047497451305389404296875f)\n                {\n                    _3131 = _3043;\n                }\n                else\n                {\n                    _3131 = (_3104 - _3071) / _3022;\n                }\n                tau += (_2972 * max(_3131, 0.0f));\n            }\n            result = lerp(result, _283_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3213);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_283",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_986",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _379 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _379;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_386, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1877[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _283_fa_camera_pos : packoffset(c0);\n    float4 _283_fa_ambient : packoffset(c1);\n    float4 _283_fa_base_color : packoffset(c2);\n    float4 _283_fa_emissive : packoffset(c3);\n    float4 _283_fa_model_emissive : packoffset(c4);\n    float4 _283_fa_pbr : packoffset(c5);\n    float4 _283_fa_maps : packoffset(c6);\n    float4 _283_fa_fog : packoffset(c7);\n    float4 _283_fa_fog_b : packoffset(c8);\n    float4 _283_fa_fog_c : packoffset(c9);\n    float4 _283_fa_counts : packoffset(c10);\n    float4 _283_fa_env_sky : packoffset(c11);\n    float4 _283_fa_env_horizon : packoffset(c12);\n    float4 _283_fa_time : packoffset(c13);\n    float4 _283_fa_cl_vpx : packoffset(c14);\n    float4 _283_fa_cl_vpy : packoffset(c15);\n    float4 _283_fa_cl_vpw : packoffset(c16);\n    float4 _283_fa_cl_fwd : packoffset(c17);\n    float4 _283_fa_cl_grid : packoffset(c18);\n    float4 _283_fa_cl_info : packoffset(c19);\n    float4 _283_fa_layers_a : packoffset(c20);\n    float4 _283_fa_layers_b : packoffset(c21);\n    float4 _283_fa_layers_c : packoffset(c22);\n    float4 _283_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _986_fa_shadow_mat[4] : packoffset(c0);\n    float4 _986_fa_shadow_rect[4] : packoffset(c16);\n    float4 _986_fa_shadow_info[4] : packoffset(c20);\n    float4 _986_fa_shadow_split : packoffset(c24);\n    float4 _986_fa_shadow_cfg : packoffset(c25);\n    float4 _986_fa_shadow_bias : packoffset(c26);\n    float4 _986_fa_shadow_eye : packoffset(c27);\n    float4 _986_fa_shadow_fwd : packoffset(c28);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _755 = _283_fa_cl_info.x < 0.0f;\n    bool _762;\n    if (!_755)\n    {\n        _762 = _283_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _762 = _755;\n    }\n    bool _770;\n    if (!_762)\n    {\n        _770 = _283_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _770 = _762;\n    }\n    bool _777;\n    if (!_770)\n    {\n        _777 = _283_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _777 = _770;\n    }\n    bool _784;\n    if (!_777)\n    {\n        _784 = _283_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _784 = _777;\n    }\n    if (_784)\n    {\n        return int2(0, 0);\n    }\n    float4 _794 = float4(world_pos, 1.0f);\n    float _801 = dot(_283_fa_cl_vpw, _794);\n    if (!(_801 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _823 = float2(dot(_283_fa_cl_vpx, _794), dot(_283_fa_cl_vpy, _794)) / _801.xx;\n    int _827 = int(_283_fa_cl_grid.x);\n    int _831 = int(_283_fa_cl_grid.y);\n    int param = (int(_283_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_283_fa_cl_fwd.xyz, world_pos) + _283_fa_cl_fwd.w, _283_fa_cl_grid.w) / _283_fa_cl_grid.w) * _283_fa_cl_grid.z)), 0, int(_283_fa_cl_info.y) - 1) * _831) + clamp(int(floor(((_823.y * 0.5f) + 0.5f) * _283_fa_cl_grid.y)), 0, _831 - 1)) * _827)) + clamp(int(floor(((_823.x * 0.5f) + 0.5f) * _283_fa_cl_grid.x)), 0, _827 - 1);\n    float4 _902 = fa_light_texel(param);\n    return int2(int(_902.x), int(_902.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_283_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2415 = fa_cluster_lookup(param);\n    fa_cl_slot = _2415.x;\n    fa_cl_local = _2415.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2524 = fa_linear_to_srgb(param);\n        c = _2524;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2532 = fa_srgb_to_linear(param_1);\n            c = _2532;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _215;\n    if (i.front_facing)\n    {\n        _215 = i.world_normal;\n    }\n    else\n    {\n        _215 = -i.world_normal;\n    }\n    float3 _239 = normalize(i.world_tangent.xyz - (_215 * dot(_215, i.world_tangent.xyz)));\n    float3 _267 = normalize(((_239 * m.x) + ((cross(_215, _239) * i.world_tangent.w) * m.y)) + (_215 * m.z));\n    float3 _270;\n    if (i.front_facing)\n    {\n        _270 = _267;\n    }\n    else\n    {\n        _270 = -_267;\n    }\n    return _270;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _283_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2563 = fa_tex_fix(param_2, param_3);\n    float4 _3547 = base_t;\n    _3547.x = _2563.x;\n    _3547.y = _2563.y;\n    _3547.z = _2563.z;\n    base_t = _3547;\n    float4 _2577 = (_3547 * _283_fa_base_color) * i.vertex_color;\n    float3 _3471 = i.world_normal;\n    if (_283_fa_maps.z > 0.5f)\n    {\n        float param_4 = _283_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2609 = fa_tex_fix(param_6, param_7);\n        float3 _2613 = (_2609 * 2.0f) - 1.0f.xxx;\n        float2 _2618 = _2613.xy * _283_fa_maps.x;\n        float3 _3555 = _2613;\n        _3555.x = _2618.x;\n        _3555.y = _2618.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3555;\n        _3471 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _283_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2646 = fa_tex_fix(param_12, param_13);\n    float4 _3558 = mrt;\n    _3558.x = _2646.x;\n    _3558.y = _2646.y;\n    _3558.z = _2646.z;\n    mrt = _3558;\n    float4 _2674 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _283_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2674.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2686 = fa_tex_fix(param_16, param_17);\n    float param_18 = _283_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2716 = fa_tex_fix(param_20, param_21);\n    float _3476 = _283_fa_layers_a.x;\n    float _3477 = _283_fa_layers_a.y;\n    float _3480 = _283_fa_layers_a.z;\n    float _3479 = _283_fa_layers_b.w;\n    float _3482 = _283_fa_layers_c.x;\n    if (_283_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_283_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3476 *= _2686.y;\n            _3477 *= _2686.z;\n            _3479 *= _2674.w;\n        }\n        if (_283_fa_layers_c.z > 1.5f)\n        {\n            _3480 *= mrt.x;\n            _3482 *= mrt.w;\n        }\n    }\n    Surface _3501 = { _2577.xyz, _2577.w, _3471, clamp(_283_fa_pbr.x * _2646.z, 0.0f, 1.0f), clamp(_283_fa_pbr.y * _2646.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_283_fa_maps.y * (_2686.x - 1.0f)), _283_fa_emissive.xyz + (_283_fa_model_emissive.xyz * _2716), _3476, _3477, _283_fa_layers_b.xyz, _3479, _3480, _283_fa_layers_a.w, _3482, _283_fa_layers_c.y, _283_fa_layers_d.xyz };\n    return _3501;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_283_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _283_fa_ambient.xyz;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1802 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1810 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1813 = int(_1802);\n    int _1816 = int(_1810);\n    float _1826 = _1810 - float(_1816);\n    int _1882 = (_1813 * 9) + _1816;\n    int _1902 = ((_1813 + 1) * 9) + _1816;\n    return lerp(lerp(_1877[_1882], _1877[_1882 + 1], _1826), lerp(_1877[_1902], _1877[_1902 + 1], _1826), _1802 - float(_1813));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3343 = false;\n    float _3344 = 1.0f;\n    float _3345 = 1.0f;\n    float _3346 = 1.0f;\n    float _3347 = 0.0f;\n    float _3348 = 0.0f;\n    float _3349 = 0.0f;\n    float _3350 = 0.0f;\n    float _3352 = 1.0f;\n    bool _3353 = false;\n    float3 _3354 = 0.0f.xxx;\n    float _3355 = 1.0f;\n    float _3356 = 1.0f;\n    float _3357 = 1.0f;\n    float _3358 = 0.0f;\n    float _3359 = 0.0f;\n    float3 _3360 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3361 = float3(0.0f, 0.0f, 1.0f);\n    float _3362 = 1.0f;\n    float _3363 = 1.0f;\n    float _1956 = clamp(s.specular, 0.0f, 1.0f);\n    float _1960 = clamp(s.ior, 1.0f, 3.0f);\n    bool _1965 = (_1956 != 1.0f) || (_1960 != 1.5f);\n    bool _1974;\n    if (!_1965)\n    {\n        _1974 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _1974 = _1965;\n    }\n    if (_1974)\n    {\n        float _1982 = (_1960 - 1.0f) / (_1960 + 1.0f);\n        f0 = lerp(min((_1982 * _1982).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _1956, s.albedo, metallic.xxx);\n        _3344 = lerp(_1956, 1.0f, metallic);\n        _3343 = true;\n    }\n    float _2010 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2010 > 0.0f)\n    {\n        float _2018 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3347 = _2010;\n        _3348 = _2018;\n        float _2025 = _2018 * _2018;\n        _3349 = _2025;\n        _3350 = _2025 * _2025;\n        float _2037 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3352 = _2037;\n        _3345 = 1.0f - (_2010 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2037, 0.0f, 1.0f), 5.0f))));\n        _3343 = true;\n    }\n    float3 _2057 = max(s.sheen_color, 0.0f.xxx);\n    float _2066 = max(_2057.x, max(_2057.y, _2057.z));\n    if (_2066 > 0.0f)\n    {\n        float _2074 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3353 = true;\n        _3354 = _2057;\n        _3355 = _2074;\n        _3356 = _2074 * _2074;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2074;\n        float _2091 = fa_sheen_albedo(param, param_1);\n        _3358 = _2091;\n        _3357 = 1.0f - min(_2066 * _2091, 1.0f);\n        _3343 = true;\n    }\n    _3346 = _3345 * _3357;\n    float _2110 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2110 != 0.0f)\n    {\n        float3 _2125 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2125;\n        if (dot(_2125, _2125) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2139 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2139.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2139.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2139.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2143 = t;\n        float3 _2144 = normalize(_2143);\n        t = _2144;\n        float3 _2169 = normalize((_2144 * cos(s.anisotropy_rotation)) + ((cross(n, _2144) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3360 = _2169;\n        _3361 = cross(n, _2169);\n        float _2179 = roughness * roughness;\n        float _2185 = lerp(_2179, 1.0f, _2110 * _2110);\n        bool _2187 = _2110 > 0.0f;\n        _3362 = _2187 ? _2185 : _2179;\n        _3363 = _2187 ? _2179 : _2185;\n        _3359 = _2110;\n        _3343 = true;\n    }\n    FaLayers _3385 = { _3343, _3344, _3345, _3346, _3347, _3348, _3349, _3350, i.world_normal, _3352, _3353, _3354, _3355, _3356, _3357, _3358, _3359, _3360, _3361, _3362, _3363 };\n    return _3385;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1734 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1737 = _1734.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1737 * _1737, exp2((-9.27999973297119140625f) * ndv)) * _1737) + _1734.y)) + _1734.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_283_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _283_fa_env_horizon.w).xyz;\n    }\n    float _1639 = rough * rough;\n    float _1669 = 0.60000002384185791015625f * _1639;\n    return lerp(lerp(_283_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_283_fa_env_horizon.xyz, _283_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1639)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1669, 0.0500000007450580596923828125f + _1669, d.y).xxx), ((_283_fa_env_sky.xyz + _283_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1639 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2220;\n        if (L.aniso >= 0.0f)\n        {\n            _2220 = L.b;\n        }\n        else\n        {\n            _2220 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2220, v), _2220), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2253 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2253.x) + (L.f90.xxx * _2253.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2308 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2308.x) + _2308.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1776 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1776.x) + _1776.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2337 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2341 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2348 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2337.xxx);\n    float3 f0 = _2348;\n    float3 _2352 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2352;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2337;\n    float param_5 = _2341;\n    float3 param_6 = _2348;\n    FaLayers _2369 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2369.on)\n    {\n        FaLayers param_7 = _2369;\n        float3 param_8 = _2352;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2341;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2352;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2341;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_283_fa_cl_info.x) + int(_283_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_283_fa_counts.y > 4.5f) ? 8 : 4);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _324_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _324_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _364 = dot(d, right);\n    float _368 = dot(d, up);\n    float _379;\n    if (((_364 * _364) + (_368 * _368)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _379 = atan2(_368, _364) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _379 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_379 - floor(_379)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li;\n    int _412 = fa_light_base(param);\n    bool _416 = _283_fa_counts.y > 4.5f;\n    int param_1 = _412;\n    float4 _420 = fa_light_texel(param_1);\n    int param_2 = _412 + 1;\n    float4 _425 = fa_light_texel(param_2);\n    float _428 = _425.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _440 = _416 && (_428 > 2.5f);\n    fa_light_is_area = _440;\n    bool _443 = _428 < 0.5f;\n    float3 l;\n    if (_443)\n    {\n        l = normalize(_420.xyz);\n        if (_416)\n        {\n            int param_3 = _412 + 6;\n            float4 _457 = fa_light_texel(param_3);\n            if (_457.z > 0.5f)\n            {\n                int param_4 = _412 + 4;\n                float4 _467 = fa_light_texel(param_4);\n                int param_5 = _412 + 5;\n                float4 _473 = fa_light_texel(param_5);\n                float2 param_6 = _457.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _467.xyz) * _467.w, (-dot(world_pos, _473.xyz)) * _473.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _505 = _420.xyz - world_pos;\n        float _507 = length(_505);\n        dist = _507;\n        l = _505 / max(_507, 9.9999997473787516355514526367188e-05f).xxx;\n        float reach = _507;\n        if (_440)\n        {\n            int param_8 = _412 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0f);\n        }\n        float _539 = reach / max(_420.w, 0.001000000047497451305389404296875f);\n        float _545 = clamp(1.0f - (_539 * _539), 0.0f, 1.0f);\n        atten = _545 * _545;\n        bool _553 = _428 < 2.5f;\n        if ((_428 > 1.5f) && _553)\n        {\n            int param_9 = _412 + 2;\n            float4 _561 = fa_light_texel(param_9);\n            float _571 = _561.w;\n            int param_10 = _412 + 3;\n            float4 _577 = fa_light_texel(param_10);\n            float _578 = _577.x;\n            float cos_inner = _578;\n            if (_578 > 1.5f)\n            {\n                cos_inner = lerp(_571, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_571, cos_inner, dot(-l, normalize(_561.xyz)));\n        }\n        if (_416 && _553)\n        {\n            int param_11 = _412 + 6;\n            float4 _602 = fa_light_texel(param_11);\n            int param_12 = _412 + 7;\n            float4 _607 = fa_light_texel(param_12);\n            bool _610 = _602.z > 0.5f;\n            bool _617;\n            if (!_610)\n            {\n                _617 = _607.z > 0.5f;\n            }\n            else\n            {\n                _617 = _610;\n            }\n            if (_617)\n            {\n                int param_13 = _412 + 2;\n                float4 _624 = fa_light_texel(param_13);\n                float3 _628 = normalize(_624.xyz);\n                int param_14 = _412 + 4;\n                float4 _633 = fa_light_texel(param_14);\n                int param_15 = _412 + 5;\n                float4 _638 = fa_light_texel(param_15);\n                if (_610)\n                {\n                    float3 _646 = -_505;\n                    float _653 = _624.w;\n                    float _669 = 0.5f / max(dot(_646, _628) * (sqrt(max(1.0f - (_653 * _653), 0.0f)) / max(_653, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                    float2 param_16 = _602.xy;\n                    float2 param_17 = float2(0.5f + (dot(_646, _633.xyz) * _669), 0.5f - (dot(_646, _638.xyz) * _669));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_607.z > 0.5f)\n                {\n                    float2 param_18 = _607.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _628;\n                    float3 param_21 = _633.xyz;\n                    float3 param_22 = _638.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    float3 _3331 = _425.xyz * atten;\n    if (_416)\n    {\n        _3331 *= fa_light_tint;\n    }\n    int _737;\n    if (_443)\n    {\n        _737 = 0;\n    }\n    else\n    {\n        _737 = ((_428 > 1.5f) && (_428 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _3342 = { l, _3331, atten, 1.0f, dist, _737 };\n    return _3342;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _976;\n    if (i == 0)\n    {\n        _976 = _986_fa_shadow_split.x;\n    }\n    else\n    {\n        float _992;\n        if (i == 1)\n        {\n            _992 = _986_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1000;\n            if (i == 2)\n            {\n                _1000 = _986_fa_shadow_split.z;\n            }\n            else\n            {\n                _1000 = _986_fa_shadow_split.w;\n            }\n            _992 = _1000;\n        }\n        _976 = _992;\n    }\n    return _976;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _964 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_964), sin(_964)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1038 = max(_986_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1043 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1049 = sqrt(1.0f - (_1043 * _1043));\n    float _1057 = min(_1049 / max(_1043, 0.20000000298023223876953125f), 4.0f);\n    float _1062;\n    if (_986_fa_shadow_bias.y > 0.0f)\n    {\n        _1062 = _986_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1062 = 1.5f * _986_fa_shadow_info[ci].x;\n    }\n    float4 _1087 = mul(float4(world + (n * (_1062 * _1049)), 1.0f), _986_fa_shadow_mat[ci]);\n    float _1094 = _1087.x;\n    bool _1097 = _1094 < _986_fa_shadow_rect[ci].x;\n    bool _1106;\n    if (!_1097)\n    {\n        _1106 = _1094 > _986_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1106 = _1097;\n    }\n    bool _1115;\n    if (!_1106)\n    {\n        _1115 = _1087.y < _986_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1115 = _1106;\n    }\n    bool _1124;\n    if (!_1115)\n    {\n        _1124 = _1087.y > _986_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1124 = _1115;\n    }\n    bool _1131;\n    if (!_1124)\n    {\n        _1131 = _1087.z > 1.0f;\n    }\n    else\n    {\n        _1131 = _1124;\n    }\n    if (_1131)\n    {\n        return -1.0f;\n    }\n    float _1139;\n    if (_986_fa_shadow_bias.x > 0.0f)\n    {\n        _1139 = _986_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1139 = 1.5f * _986_fa_shadow_info[ci].x;\n    }\n    float _1158 = _1087.z - ((_1139 * (1.0f + (0.5f * _1057))) / _1038);\n    float _1167 = ((_986_fa_shadow_info[ci].x * min(_1057, 3.0f)) * 0.5f) / _1038;\n    int _1176 = int(_986_fa_shadow_cfg.z + 0.5f);\n    if (_1176 == 1)\n    {\n        float2 param = _1087.xy;\n        float4 param_1 = _986_fa_shadow_rect[ci];\n        float _1187 = fa_shadow_depth(param, param_1);\n        return float(_1158 <= _1187);\n    }\n    float _1194 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1197 = _1176 == 2;\n    if (_1197)\n    {\n        float _1211 = clamp(((_986_fa_shadow_cfg.w * _1038) * 0.25f) / _986_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1194;\n            float2 _1230 = fa_shadow_vogel(param_2, param_3, param_4) * _1211;\n            float2 param_5 = _1087.xy + (_1230 * _986_fa_shadow_bias.zw);\n            float4 param_6 = _986_fa_shadow_rect[ci];\n            float _1241 = fa_shadow_depth(param_5, param_6);\n            if (_1241 < (_1158 - (length(_1230) * _1167)))\n            {\n                sum += _1241;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1158 - (sum / cnt), 0.0f) * _1038) * _986_fa_shadow_cfg.w) / _986_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1285 = _1197 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1285; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1285;\n        float param_9 = _1194;\n        float2 _1304 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1087.xy + (_1304 * _986_fa_shadow_bias.zw);\n        float4 param_11 = _986_fa_shadow_rect[ci];\n        float _1315 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1158 - (length(_1304) * _1167)) <= _1315);\n    }\n    return lit / float(_1285);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_283_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1345 = int(_986_fa_shadow_cfg.x + 0.5f);\n    if (_1345 < 1)\n    {\n        return 1.0f;\n    }\n    float _1360 = dot(world - _986_fa_shadow_eye.xyz, _986_fa_shadow_fwd.xyz);\n    int param = _1345 - 1;\n    if (_1360 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1372 = _1345 > 1;\n    bool _1379;\n    if (_1372)\n    {\n        _1379 = _1360 > _986_fa_shadow_split.x;\n    }\n    else\n    {\n        _1379 = _1372;\n    }\n    if (_1379)\n    {\n        ci = 1;\n    }\n    bool _1383 = _1345 > 2;\n    bool _1390;\n    if (_1383)\n    {\n        _1390 = _1360 > _986_fa_shadow_split.y;\n    }\n    else\n    {\n        _1390 = _1383;\n    }\n    if (_1390)\n    {\n        ci = 2;\n    }\n    bool _1394 = _1345 > 3;\n    bool _1401;\n    if (_1394)\n    {\n        _1401 = _1360 > _986_fa_shadow_split.z;\n    }\n    else\n    {\n        _1401 = _1394;\n    }\n    if (_1401)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1345)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1427 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1427;\n        if (_1427 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_986_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1452;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1452 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1452 = _986_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1471 = _986_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1452, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1482 = clamp((_1360 - (fa_shadow_split_at(param_7) - _1471)) / _1471, 0.0f, 1.0f);\n        if (_1482 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1345)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1503 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1503;\n                if (_1503 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1482);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2443 = fa_light_sample(param, param_1);\n    float3 _3451 = _2443.color;\n    float _3453 = _2443.shadow;\n    if ((_2443.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2443.direction;\n        float _2457 = fa_shadow_factor(param_2, param_3);\n        _3453 = _2457;\n        _3451 *= _2457;\n    }\n    LightSample _3468 = { _2443.direction, _3451, _2443.attenuation, _3453, _2443._distance, _2443.type };\n    return _3468;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_986_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1527 = int(_986_fa_shadow_cfg.x + 0.5f);\n    float _1537 = dot(world - _986_fa_shadow_eye.xyz, _986_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1542 = _1527 > 0;\n    bool _1551;\n    if (_1542)\n    {\n        int param = _1527 - 1;\n        _1551 = _1537 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1551 = _1542;\n    }\n    if (_1551)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1558 = _1527 > 1;\n        bool _1565;\n        if (_1558)\n        {\n            _1565 = _1537 > _986_fa_shadow_split.x;\n        }\n        else\n        {\n            _1565 = _1558;\n        }\n        if (_1565)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1571 = _1527 > 2;\n        bool _1578;\n        if (_1571)\n        {\n            _1578 = _1537 > _986_fa_shadow_split.y;\n        }\n        else\n        {\n            _1578 = _1571;\n        }\n        if (_1578)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1584 = _1527 > 3;\n        bool _1591;\n        if (_1584)\n        {\n            _1591 = _1537 > _986_fa_shadow_split.z;\n        }\n        else\n        {\n            _1591 = _1584;\n        }\n        if (_1591)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3173 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3173 = -_3173;\n    }\n    float3 _2837 = normalize(_283_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3186 = { fa_world_pos, _3173, fa_world_tangent, fa_uv, fa_vertex_color, _2837, gl_FrontFacing };\n    SurfaceInput param_1 = _3186;\n    Surface _2845 = fa_standard_surface(param_1);\n    float3 _3212 = _2845.albedo;\n    float _3213 = _2845.alpha;\n    float3 _3214 = _2845.normal;\n    float _3215 = _2845.metallic;\n    float _3216 = _2845.roughness;\n    float _3217 = _2845.occlusion;\n    float3 _3218 = _2845.emission;\n    float _3219 = _2845.clearcoat;\n    float _3220 = _2845.clearcoat_roughness;\n    float3 _3221 = _2845.sheen_color;\n    float _3222 = _2845.sheen_roughness;\n    float _3223 = _2845.anisotropy;\n    float _3224 = _2845.anisotropy_rotation;\n    float _3225 = _2845.specular;\n    float _3226 = _2845.ior;\n    float3 _3227 = _2845.specular_color;\n    SurfaceInput _3194 = { fa_world_pos, _3173, fa_world_tangent, fa_uv, fa_vertex_color, _2837, gl_FrontFacing };\n    SurfaceInput param_2 = _3194;\n    Surface param_3 = _2845;\n    surface(param_2, param_3);\n    _3212 = param_3.albedo;\n    _3213 = param_3.alpha;\n    _3214 = param_3.normal;\n    _3215 = param_3.metallic;\n    _3216 = param_3.roughness;\n    _3217 = param_3.occlusion;\n    _3218 = param_3.emission;\n    _3219 = param_3.clearcoat;\n    _3220 = param_3.clearcoat_roughness;\n    _3221 = param_3.sheen_color;\n    _3222 = param_3.sheen_roughness;\n    _3223 = param_3.anisotropy;\n    _3224 = param_3.anisotropy_rotation;\n    _3225 = param_3.specular;\n    _3226 = param_3.ior;\n    _3227 = param_3.specular_color;\n    float3 result;\n    if (_283_fa_emissive.w > 0.5f)\n    {\n        result = _3212;\n    }\n    else\n    {\n        float3 _2866 = _3214;\n        float3 _2867 = normalize(_2866);\n        _3214 = _2867;\n        float3 param_4 = _2867;\n        SurfaceInput _3202 = { fa_world_pos, _3173, fa_world_tangent, fa_uv, fa_vertex_color, _2837, gl_FrontFacing };\n        SurfaceInput param_5 = _3202;\n        Surface _3293 = { _3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219, _3220, _3221, _3222, _3223, _3224, _3225, _3226, _3227 };\n        Surface param_6 = _3293;\n        float3 param_7 = fa_ambient_light(param_4);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _2886 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2886; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8);\n            float3 param_10 = fa_world_pos;\n            float3 param_11 = _3173;\n            LightSample _2908 = fa_light_shadowed(param_9, param_10, param_11);\n            SurfaceInput _3210 = { fa_world_pos, _3173, fa_world_tangent, fa_uv, fa_vertex_color, _2837, gl_FrontFacing };\n            SurfaceInput param_12 = _3210;\n            Surface _3310 = { _3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219, _3220, _3221, _3222, _3223, _3224, _3225, _3226, _3227 };\n            Surface param_13 = _3310;\n            LightSample param_14 = _2908;\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _2923 = result;\n    float3 _2924 = _2923 + _3218;\n    result = _2924;\n    float3 param_15 = _2924;\n    float3 param_16 = fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16);\n    bool _2933 = _283_fa_fog.w > 0.0f;\n    bool _2940;\n    if (!_2933)\n    {\n        _2940 = _283_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2940 = _2933;\n    }\n    if (_2940)\n    {\n        float3 _2949 = fa_world_pos - _283_fa_camera_pos.xyz;\n        float _2955 = dot(_2949, _283_fa_fog_c.xyz);\n        bool _2959 = _283_fa_fog_c.w > 0.5f;\n        float _2960;\n        if (_2959)\n        {\n            _2960 = _2955;\n        }\n        else\n        {\n            _2960 = length(_2949);\n        }\n        float _2972 = _2960 - _283_fa_fog_b.x;\n        if (_2972 > 0.0f)\n        {\n            float _2981 = _283_fa_fog.w * _2972;\n            float tau = _2981 * _2981;\n            if (_283_fa_fog_b.y > 0.0f)\n            {\n                float _2997;\n                if (_2959)\n                {\n                    _2997 = fa_world_pos.y - (_283_fa_fog_c.y * _2955);\n                }\n                else\n                {\n                    _2997 = _283_fa_camera_pos.y;\n                }\n                float _3018 = lerp(_2997, fa_world_pos.y, clamp(_283_fa_fog_b.x / _2960, 0.0f, 1.0f));\n                float _3022 = fa_world_pos.y - _3018;\n                float _3027 = _3018 - _283_fa_fog_b.z;\n                float _3032 = fa_world_pos.y - _283_fa_fog_b.z;\n                bool _3035 = _3027 <= 0.0f;\n                bool _3036 = !_3035;\n                bool _3042;\n                if (_3036)\n                {\n                    _3042 = _283_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3042 = _3035;\n                }\n                float _3043;\n                if (_3042)\n                {\n                    _3043 = _283_fa_fog_b.y;\n                }\n                else\n                {\n                    _3043 = _283_fa_fog_b.y * exp(-min(_283_fa_fog_b.w * _3027, 80.0f));\n                }\n                bool _3070;\n                if (_3036)\n                {\n                    _3070 = _283_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3070 = _3035;\n                }\n                float _3071;\n                if (_3070)\n                {\n                    _3071 = _283_fa_fog_b.y * _3027;\n                }\n                else\n                {\n                    _3071 = (_283_fa_fog_b.y * (1.0f - exp(-min(_283_fa_fog_b.w * _3027, 80.0f)))) / _283_fa_fog_b.w;\n                }\n                bool _3096 = _3032 <= 0.0f;\n                bool _3103;\n                if (!_3096)\n                {\n                    _3103 = _283_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3103 = _3096;\n                }\n                float _3104;\n                if (_3103)\n                {\n                    _3104 = _283_fa_fog_b.y * _3032;\n                }\n                else\n                {\n                    _3104 = (_283_fa_fog_b.y * (1.0f - exp(-min(_283_fa_fog_b.w * _3032, 80.0f)))) / _283_fa_fog_b.w;\n                }\n                float _3131;\n                if (abs(_3022) < 0.001000000047497451305389404296875f)\n                {\n                    _3131 = _3043;\n                }\n                else\n                {\n                    _3131 = (_3104 - _3071) / _3022;\n                }\n                tau += (_2972 * max(_3131, 0.0f));\n            }\n            result = lerp(result, _283_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3213);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_283",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_986",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213_fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213_fa_layers_a.x;\n    float _753 = _213_fa_layers_a.y;\n    float _756 = _213_fa_layers_a.z;\n    float _755 = _213_fa_layers_b.w;\n    float _758 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    Surface _777 = { _241.xyz, _241.w, _747, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _752, _753, _213_fa_layers_b.xyz, _755, _756, _213_fa_layers_a.w, _758, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _777;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _671 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _671;\n    SurfaceInput _679 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _679;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _413 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _413;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0f);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213_fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213_fa_layers_a.x;\n    float _753 = _213_fa_layers_a.y;\n    float _756 = _213_fa_layers_a.z;\n    float _755 = _213_fa_layers_b.w;\n    float _758 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    Surface _777 = { _241.xyz, _241.w, _747, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _752, _753, _213_fa_layers_b.xyz, _755, _756, _213_fa_layers_a.w, _758, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _777;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _671 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _671;\n    SurfaceInput _679 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _679;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
