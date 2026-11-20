{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "738bdbaa5d236ca82c68b48e7af94b35c54ba5d6311eabf2bcbbc814ba3d221c",
  "slang": "hlsl5",
  "params": [
    "alphaCutoff"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _261 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _261;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_268, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1985[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _381_fa_camera_pos : packoffset(c0);\n    float4 _381_fa_ambient : packoffset(c1);\n    float4 _381_fa_base_color : packoffset(c2);\n    float4 _381_fa_emissive : packoffset(c3);\n    float4 _381_fa_model_emissive : packoffset(c4);\n    float4 _381_fa_pbr : packoffset(c5);\n    float4 _381_fa_maps : packoffset(c6);\n    float4 _381_fa_fog : packoffset(c7);\n    float4 _381_fa_fog_b : packoffset(c8);\n    float4 _381_fa_fog_c : packoffset(c9);\n    float4 _381_fa_counts : packoffset(c10);\n    float4 _381_fa_env_sky : packoffset(c11);\n    float4 _381_fa_env_horizon : packoffset(c12);\n    float4 _381_fa_time : packoffset(c13);\n    float4 _381_fa_cl_vpx : packoffset(c14);\n    float4 _381_fa_cl_vpy : packoffset(c15);\n    float4 _381_fa_cl_vpw : packoffset(c16);\n    float4 _381_fa_cl_fwd : packoffset(c17);\n    float4 _381_fa_cl_grid : packoffset(c18);\n    float4 _381_fa_cl_info : packoffset(c19);\n    float4 _381_fa_layers_a : packoffset(c20);\n    float4 _381_fa_layers_b : packoffset(c21);\n    float4 _381_fa_layers_c : packoffset(c22);\n    float4 _381_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1094_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1094_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1094_fa_shadow_info[4] : packoffset(c20);\n    float4 _1094_fa_shadow_split : packoffset(c24);\n    float4 _1094_fa_shadow_cfg : packoffset(c25);\n    float4 _1094_fa_shadow_bias : packoffset(c26);\n    float4 _1094_fa_shadow_eye : packoffset(c27);\n    float4 _1094_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _4047_alphaCutoff : packoffset(c0);\n    float _4047_fa_pad0 : packoffset(c0.y);\n    float _4047_fa_pad1 : packoffset(c0.z);\n    float _4047_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _863 = _381_fa_cl_info.x < 0.0f;\n    bool _870;\n    if (!_863)\n    {\n        _870 = _381_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _870 = _863;\n    }\n    bool _878;\n    if (!_870)\n    {\n        _878 = _381_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _878 = _870;\n    }\n    bool _885;\n    if (!_878)\n    {\n        _885 = _381_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _885 = _878;\n    }\n    bool _892;\n    if (!_885)\n    {\n        _892 = _381_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _892 = _885;\n    }\n    if (_892)\n    {\n        return int2(0, 0);\n    }\n    float4 _902 = float4(world_pos, 1.0f);\n    float _909 = dot(_381_fa_cl_vpw, _902);\n    if (!(_909 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _931 = float2(dot(_381_fa_cl_vpx, _902), dot(_381_fa_cl_vpy, _902)) / _909.xx;\n    int _935 = int(_381_fa_cl_grid.x);\n    int _939 = int(_381_fa_cl_grid.y);\n    int param = (int(_381_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_381_fa_cl_fwd.xyz, world_pos) + _381_fa_cl_fwd.w, _381_fa_cl_grid.w) / _381_fa_cl_grid.w) * _381_fa_cl_grid.z)), 0, int(_381_fa_cl_info.y) - 1) * _939) + clamp(int(floor(((_931.y * 0.5f) + 0.5f) * _381_fa_cl_grid.y)), 0, _939 - 1)) * _935)) + clamp(int(floor(((_931.x * 0.5f) + 0.5f) * _381_fa_cl_grid.x)), 0, _935 - 1);\n    float4 _1010 = fa_light_texel(param);\n    return int2(int(_1010.x), int(_1010.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_381_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2802 = fa_cluster_lookup(param);\n    fa_cl_slot = _2802.x;\n    fa_cl_local = _2802.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3716 = fa_linear_to_srgb(param);\n        c = _3716;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3724 = fa_srgb_to_linear(param_1);\n            c = _3724;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _313;\n    if (i.front_facing)\n    {\n        _313 = i.world_normal;\n    }\n    else\n    {\n        _313 = -i.world_normal;\n    }\n    float3 _337 = normalize(i.world_tangent.xyz - (_313 * dot(_313, i.world_tangent.xyz)));\n    float3 _365 = normalize(((_337 * m.x) + ((cross(_313, _337) * i.world_tangent.w) * m.y)) + (_313 * m.z));\n    float3 _368;\n    if (i.front_facing)\n    {\n        _368 = _365;\n    }\n    else\n    {\n        _368 = -_365;\n    }\n    return _368;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _381_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3755 = fa_tex_fix(param_2, param_3);\n    float4 _4996 = base_t;\n    _4996.x = _3755.x;\n    _4996.y = _3755.y;\n    _4996.z = _3755.z;\n    base_t = _4996;\n    float4 _3769 = (_4996 * _381_fa_base_color) * i.vertex_color;\n    float3 _4906 = i.world_normal;\n    if (_381_fa_maps.z > 0.5f)\n    {\n        float param_4 = _381_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3801 = fa_tex_fix(param_6, param_7);\n        float3 _3804 = (_3801 * 2.0f) - 1.0f.xxx;\n        float2 _3809 = _3804.xy * _381_fa_maps.x;\n        float3 _5004 = _3804;\n        _5004.x = _3809.x;\n        _5004.y = _3809.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5004;\n        _4906 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _381_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3837 = fa_tex_fix(param_12, param_13);\n    float4 _5007 = mrt;\n    _5007.x = _3837.x;\n    _5007.y = _3837.y;\n    _5007.z = _3837.z;\n    mrt = _5007;\n    float4 _3865 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _381_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3865.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3877 = fa_tex_fix(param_16, param_17);\n    float param_18 = _381_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3907 = fa_tex_fix(param_20, param_21);\n    float _4911 = _381_fa_layers_a.x;\n    float _4912 = _381_fa_layers_a.y;\n    float _4915 = _381_fa_layers_a.z;\n    float _4914 = _381_fa_layers_b.w;\n    float _4917 = _381_fa_layers_c.x;\n    if (_381_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_381_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4911 *= _3877.y;\n            _4912 *= _3877.z;\n            _4914 *= _3865.w;\n        }\n        if (_381_fa_layers_c.z > 1.5f)\n        {\n            _4915 *= mrt.x;\n            _4917 *= mrt.w;\n        }\n    }\n    Surface _4936 = { _3769.xyz, _3769.w, _4906, clamp(_381_fa_pbr.x * _3837.z, 0.0f, 1.0f), clamp(_381_fa_pbr.y * _3837.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_381_fa_maps.y * (_3877.x - 1.0f)), _381_fa_emissive.xyz + (_381_fa_model_emissive.xyz * _3907), _4911, _4912, _381_fa_layers_b.xyz, _4914, _4915, _381_fa_layers_a.w, _4917, _381_fa_layers_c.y, _381_fa_layers_d.xyz };\n    return _4936;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1910 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1918 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1921 = int(_1910);\n    int _1924 = int(_1918);\n    float _1934 = _1918 - float(_1924);\n    int _1990 = (_1921 * 9) + _1924;\n    int _2010 = ((_1921 + 1) * 9) + _1924;\n    return lerp(lerp(_1985[_1990], _1985[_1990 + 1], _1934), lerp(_1985[_2010], _1985[_2010 + 1], _1934), _1910 - float(_1921));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4842 = false;\n    float _4843 = 1.0f;\n    float _4844 = 1.0f;\n    float _4845 = 1.0f;\n    float _4846 = 0.0f;\n    float _4847 = 0.0f;\n    float _4848 = 0.0f;\n    float _4849 = 0.0f;\n    float _4851 = 1.0f;\n    bool _4852 = false;\n    float3 _4853 = 0.0f.xxx;\n    float _4854 = 1.0f;\n    float _4855 = 1.0f;\n    float _4856 = 1.0f;\n    float _4857 = 0.0f;\n    float _4858 = 0.0f;\n    float3 _4859 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4860 = float3(0.0f, 0.0f, 1.0f);\n    float _4861 = 1.0f;\n    float _4862 = 1.0f;\n    float _2064 = clamp(s.specular, 0.0f, 1.0f);\n    float _2068 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2073 = (_2064 != 1.0f) || (_2068 != 1.5f);\n    bool _2082;\n    if (!_2073)\n    {\n        _2082 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2082 = _2073;\n    }\n    if (_2082)\n    {\n        float _2090 = (_2068 - 1.0f) / (_2068 + 1.0f);\n        f0 = lerp(min((_2090 * _2090).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2064, s.albedo, metallic.xxx);\n        _4843 = lerp(_2064, 1.0f, metallic);\n        _4842 = true;\n    }\n    float _2118 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2118 > 0.0f)\n    {\n        float _2126 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4846 = _2118;\n        _4847 = _2126;\n        float _2133 = _2126 * _2126;\n        _4848 = _2133;\n        _4849 = _2133 * _2133;\n        float _2145 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4851 = _2145;\n        _4844 = 1.0f - (_2118 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2145, 0.0f, 1.0f), 5.0f))));\n        _4842 = true;\n    }\n    float3 _2165 = max(s.sheen_color, 0.0f.xxx);\n    float _2174 = max(_2165.x, max(_2165.y, _2165.z));\n    if (_2174 > 0.0f)\n    {\n        float _2182 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4852 = true;\n        _4853 = _2165;\n        _4854 = _2182;\n        _4855 = _2182 * _2182;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2182;\n        float _2199 = fa_sheen_albedo(param, param_1);\n        _4857 = _2199;\n        _4856 = 1.0f - min(_2174 * _2199, 1.0f);\n        _4842 = true;\n    }\n    _4845 = _4844 * _4856;\n    float _2218 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2218 != 0.0f)\n    {\n        float3 _2233 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2233;\n        if (dot(_2233, _2233) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2247 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2247.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2247.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2247.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2251 = t;\n        float3 _2252 = normalize(_2251);\n        t = _2252;\n        float3 _2277 = normalize((_2252 * cos(s.anisotropy_rotation)) + ((cross(n, _2252) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4859 = _2277;\n        _4860 = cross(n, _2277);\n        float _2287 = roughness * roughness;\n        float _2293 = lerp(_2287, 1.0f, _2218 * _2218);\n        bool _2295 = _2218 > 0.0f;\n        _4861 = _2295 ? _2293 : _2287;\n        _4862 = _2295 ? _2287 : _2293;\n        _4858 = _2218;\n        _4842 = true;\n    }\n    FaLayers _4884 = { _4842, _4843, _4844, _4845, _4846, _4847, _4848, _4849, i.world_normal, _4851, _4852, _4853, _4854, _4855, _4856, _4857, _4858, _4859, _4860, _4861, _4862 };\n    return _4884;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_381_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _381_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_381_fa_cl_info.x) + int(_381_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_381_fa_counts.y > 4.5f) ? 8 : 4);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _431_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _431_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _471 = dot(d, right);\n    float _475 = dot(d, up);\n    float _486;\n    if (((_471 * _471) + (_475 * _475)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _486 = atan2(_475, _471) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _486 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_486 - floor(_486)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li;\n    int _519 = fa_light_base(param);\n    bool _523 = _381_fa_counts.y > 4.5f;\n    int param_1 = _519;\n    float4 _527 = fa_light_texel(param_1);\n    int param_2 = _519 + 1;\n    float4 _532 = fa_light_texel(param_2);\n    float _535 = _532.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _547 = _523 && (_535 > 2.5f);\n    fa_light_is_area = _547;\n    bool _550 = _535 < 0.5f;\n    float3 l;\n    if (_550)\n    {\n        l = normalize(_527.xyz);\n        if (_523)\n        {\n            int param_3 = _519 + 6;\n            float4 _564 = fa_light_texel(param_3);\n            if (_564.z > 0.5f)\n            {\n                int param_4 = _519 + 4;\n                float4 _574 = fa_light_texel(param_4);\n                int param_5 = _519 + 5;\n                float4 _580 = fa_light_texel(param_5);\n                float2 param_6 = _564.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _574.xyz) * _574.w, (-dot(world_pos, _580.xyz)) * _580.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _612 = _527.xyz - world_pos;\n        float _614 = length(_612);\n        dist = _614;\n        l = _612 / max(_614, 9.9999997473787516355514526367188e-05f).xxx;\n        float reach = _614;\n        if (_547)\n        {\n            int param_8 = _519 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0f);\n        }\n        float _646 = reach / max(_527.w, 0.001000000047497451305389404296875f);\n        float _652 = clamp(1.0f - (_646 * _646), 0.0f, 1.0f);\n        atten = _652 * _652;\n        bool _660 = _535 < 2.5f;\n        if ((_535 > 1.5f) && _660)\n        {\n            int param_9 = _519 + 2;\n            float4 _668 = fa_light_texel(param_9);\n            float _678 = _668.w;\n            int param_10 = _519 + 3;\n            float4 _684 = fa_light_texel(param_10);\n            float _685 = _684.x;\n            float cos_inner = _685;\n            if (_685 > 1.5f)\n            {\n                cos_inner = lerp(_678, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_678, cos_inner, dot(-l, normalize(_668.xyz)));\n        }\n        if (_523 && _660)\n        {\n            int param_11 = _519 + 6;\n            float4 _709 = fa_light_texel(param_11);\n            int param_12 = _519 + 7;\n            float4 _714 = fa_light_texel(param_12);\n            bool _717 = _709.z > 0.5f;\n            bool _724;\n            if (!_717)\n            {\n                _724 = _714.z > 0.5f;\n            }\n            else\n            {\n                _724 = _717;\n            }\n            if (_724)\n            {\n                int param_13 = _519 + 2;\n                float4 _731 = fa_light_texel(param_13);\n                float3 _735 = normalize(_731.xyz);\n                int param_14 = _519 + 4;\n                float4 _740 = fa_light_texel(param_14);\n                int param_15 = _519 + 5;\n                float4 _745 = fa_light_texel(param_15);\n                if (_717)\n                {\n                    float3 _753 = -_612;\n                    float _760 = _731.w;\n                    float _776 = 0.5f / max(dot(_753, _735) * (sqrt(max(1.0f - (_760 * _760), 0.0f)) / max(_760, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                    float2 param_16 = _709.xy;\n                    float2 param_17 = float2(0.5f + (dot(_753, _740.xyz) * _776), 0.5f - (dot(_753, _745.xyz) * _776));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_714.z > 0.5f)\n                {\n                    float2 param_18 = _714.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _735;\n                    float3 param_21 = _740.xyz;\n                    float3 param_22 = _745.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    float3 _4830 = _532.xyz * atten;\n    if (_523)\n    {\n        _4830 *= fa_light_tint;\n    }\n    int _845;\n    if (_550)\n    {\n        _845 = 0;\n    }\n    else\n    {\n        _845 = ((_535 > 1.5f) && (_535 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4841 = { l, _4830, atten, 1.0f, dist, _845 };\n    return _4841;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1084;\n    if (i == 0)\n    {\n        _1084 = _1094_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1100;\n        if (i == 1)\n        {\n            _1100 = _1094_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1108;\n            if (i == 2)\n            {\n                _1108 = _1094_fa_shadow_split.z;\n            }\n            else\n            {\n                _1108 = _1094_fa_shadow_split.w;\n            }\n            _1100 = _1108;\n        }\n        _1084 = _1100;\n    }\n    return _1084;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1072 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1072), sin(_1072)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1146 = max(_1094_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1151 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1157 = sqrt(1.0f - (_1151 * _1151));\n    float _1165 = min(_1157 / max(_1151, 0.20000000298023223876953125f), 4.0f);\n    float _1170;\n    if (_1094_fa_shadow_bias.y > 0.0f)\n    {\n        _1170 = _1094_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1170 = 1.5f * _1094_fa_shadow_info[ci].x;\n    }\n    float4 _1195 = mul(float4(world + (n * (_1170 * _1157)), 1.0f), _1094_fa_shadow_mat[ci]);\n    float _1202 = _1195.x;\n    bool _1205 = _1202 < _1094_fa_shadow_rect[ci].x;\n    bool _1214;\n    if (!_1205)\n    {\n        _1214 = _1202 > _1094_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1214 = _1205;\n    }\n    bool _1223;\n    if (!_1214)\n    {\n        _1223 = _1195.y < _1094_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1223 = _1214;\n    }\n    bool _1232;\n    if (!_1223)\n    {\n        _1232 = _1195.y > _1094_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1232 = _1223;\n    }\n    bool _1239;\n    if (!_1232)\n    {\n        _1239 = _1195.z > 1.0f;\n    }\n    else\n    {\n        _1239 = _1232;\n    }\n    if (_1239)\n    {\n        return -1.0f;\n    }\n    float _1247;\n    if (_1094_fa_shadow_bias.x > 0.0f)\n    {\n        _1247 = _1094_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1247 = 1.5f * _1094_fa_shadow_info[ci].x;\n    }\n    float _1266 = _1195.z - ((_1247 * (1.0f + (0.5f * _1165))) / _1146);\n    float _1275 = ((_1094_fa_shadow_info[ci].x * min(_1165, 3.0f)) * 0.5f) / _1146;\n    int _1284 = int(_1094_fa_shadow_cfg.z + 0.5f);\n    if (_1284 == 1)\n    {\n        float2 param = _1195.xy;\n        float4 param_1 = _1094_fa_shadow_rect[ci];\n        float _1295 = fa_shadow_depth(param, param_1);\n        return float(_1266 <= _1295);\n    }\n    float _1302 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1305 = _1284 == 2;\n    if (_1305)\n    {\n        float _1319 = clamp(((_1094_fa_shadow_cfg.w * _1146) * 0.25f) / _1094_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1302;\n            float2 _1338 = fa_shadow_vogel(param_2, param_3, param_4) * _1319;\n            float2 param_5 = _1195.xy + (_1338 * _1094_fa_shadow_bias.zw);\n            float4 param_6 = _1094_fa_shadow_rect[ci];\n            float _1349 = fa_shadow_depth(param_5, param_6);\n            if (_1349 < (_1266 - (length(_1338) * _1275)))\n            {\n                sum += _1349;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1266 - (sum / cnt), 0.0f) * _1146) * _1094_fa_shadow_cfg.w) / _1094_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1393 = _1305 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1393; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1393;\n        float param_9 = _1302;\n        float2 _1412 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1195.xy + (_1412 * _1094_fa_shadow_bias.zw);\n        float4 param_11 = _1094_fa_shadow_rect[ci];\n        float _1423 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1266 - (length(_1412) * _1275)) <= _1423);\n    }\n    return lit / float(_1393);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_381_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1453 = int(_1094_fa_shadow_cfg.x + 0.5f);\n    if (_1453 < 1)\n    {\n        return 1.0f;\n    }\n    float _1468 = dot(world - _1094_fa_shadow_eye.xyz, _1094_fa_shadow_fwd.xyz);\n    int param = _1453 - 1;\n    if (_1468 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1480 = _1453 > 1;\n    bool _1487;\n    if (_1480)\n    {\n        _1487 = _1468 > _1094_fa_shadow_split.x;\n    }\n    else\n    {\n        _1487 = _1480;\n    }\n    if (_1487)\n    {\n        ci = 1;\n    }\n    bool _1491 = _1453 > 2;\n    bool _1498;\n    if (_1491)\n    {\n        _1498 = _1468 > _1094_fa_shadow_split.y;\n    }\n    else\n    {\n        _1498 = _1491;\n    }\n    if (_1498)\n    {\n        ci = 2;\n    }\n    bool _1502 = _1453 > 3;\n    bool _1509;\n    if (_1502)\n    {\n        _1509 = _1468 > _1094_fa_shadow_split.z;\n    }\n    else\n    {\n        _1509 = _1502;\n    }\n    if (_1509)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1453)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1535 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1535;\n        if (_1535 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1094_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1560;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1560 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1560 = _1094_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1579 = _1094_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1560, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1590 = clamp((_1468 - (fa_shadow_split_at(param_7) - _1579)) / _1579, 0.0f, 1.0f);\n        if (_1590 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1453)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1611 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1611;\n                if (_1611 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1590);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2830 = fa_light_sample(param, param_1);\n    float3 _4886 = _2830.color;\n    float _4888 = _2830.shadow;\n    if ((_2830.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2830.direction;\n        float _2844 = fa_shadow_factor(param_2, param_3);\n        _4888 = _2844;\n        _4886 *= _2844;\n    }\n    LightSample _4903 = { _2830.direction, _4886, _2830.attenuation, _4888, _2830._distance, _2830.type };\n    return _4903;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _2884 = v - (n * dot(v, n));\n    float3 t = _2884;\n    float _2888 = dot(_2884, _2884);\n    float l2 = _2888;\n    if (_2888 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _2898;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _2898 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _2898 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _2898;\n        l2 = dot(_2898, _2898);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _2933 = dot(a, a);\n    float _2937 = dot(b, b);\n    if ((_2933 < 1.0000000195414813782625560981111e-24f) || (_2937 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _2951 = a * rsqrt(_2933);\n    float3 _2956 = b * rsqrt(_2937);\n    float _2960 = dot(_2951, _2956);\n    float _2963 = abs(_2960);\n    float g = (((((((((((0.0416471660137176513671875f * _2963) - 0.1924748718738555908203125f) * _2963) + 0.4179156124591827392578125f) * _2963) - 0.616057217121124267578125f) * _2963) + 0.777722418308258056640625f) * _2963) - 0.999542415142059326171875f) * _2963) + 1.570791721343994140625f;\n    if (_2960 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_2960 * _2960), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_2951, _2956) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _3020 = a.z > 0.0f;\n    bool _3024 = b.z > 0.0f;\n    if (_3020 && _3024)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_3020 != _3024)\n        {\n            float3 _3059 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _3059.z = 0.0f;\n            if (_3020)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _3059;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _3059;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _3059;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _3059;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _3108 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _3134 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _3160 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _3186 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _3108;\n    float3 param_1 = _3134;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _3134;\n    float3 param_7 = _3160;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _3160;\n    float3 param_13 = _3186;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _3186;\n    float3 param_19 = _3108;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _3336 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _3360 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _3376 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _3336;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _3360;\n    float4 param_9 = m;\n    float3 param_10 = _3336;\n    float3 param_11 = _3360;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _3376;\n    float4 param_14 = m;\n    float3 param_15 = _3336;\n    float3 param_16 = _3376;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _3434 = fa_light_base(param);\n    int param_1 = _3434;\n    int param_2 = _3434 + 1;\n    int param_3 = _3434 + 2;\n    int param_4 = _3434 + 4;\n    float4 _3456 = fa_light_texel(param_4);\n    int param_5 = _3434 + 5;\n    float4 _3461 = fa_light_texel(param_5);\n    int param_6 = _3434 + 6;\n    float4 _3466 = fa_light_texel(param_6);\n    float _3467 = _3466.w;\n    float3 _3472 = fa_light_texel(param_1).xyz - world_pos;\n    bool _3474 = _3467 < 1.5f;\n    bool _3481;\n    if (_3474)\n    {\n        _3481 = dot(normalize(fa_light_texel(param_3).xyz), _3472) >= 0.0f;\n    }\n    else\n    {\n        _3481 = _3474;\n    }\n    if (_3481)\n    {\n        return 0.0f.xxx;\n    }\n    bool _3490 = (_3467 > 0.5f) && _3474;\n    float _3494 = _3490 ? 1.0539000034332275390625f : 1.0f;\n    float3 _3497 = _3456.xyz;\n    float _3499 = _3456.w;\n    float3 _3505 = _3461.xyz;\n    float _3507 = _3461.w;\n    float3 up = _3505 * (_3507 * _3494);\n    float _3513;\n    if (_3490)\n    {\n        _3513 = (3.1415927410125732421875f * _3499) * _3499;\n    }\n    else\n    {\n        _3513 = (4.0f * _3499) * _3507;\n    }\n    if (_3467 > 1.5f)\n    {\n        float3 _3539 = cross(_3497, -_3472);\n        float3 perp = _3539;\n        float _3543 = dot(_3539, _3539);\n        float3 _3546;\n        if (_3543 > 1.0000000133514319600180897396058e-10f)\n        {\n            _3546 = perp * rsqrt(_3543);\n        }\n        else\n        {\n            _3546 = _3505;\n        }\n        perp = _3546;\n        up = _3546 * _3507;\n    }\n    float _3567 = max(_3513, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _3577 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _3577;\n    float3 param_10 = n;\n    float3 param_11 = _3472;\n    float3 _3585 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _3577;\n    float3 param_13 = n;\n    float3 param_14 = _3497 * (_3499 * _3494);\n    float3 _3593 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _3577;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _3601 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _3467;\n    float3 param_20 = _3585;\n    float3 param_21 = _3593;\n    float3 param_22 = _3601;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _3620 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _3620;\n    float2 param_26 = _3620 + float2(64.0f, 0.0f);\n    float4 _3630 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _3467;\n    float3 param_29 = _3585;\n    float3 param_30 = _3593;\n    float3 param_31 = _3601;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _3630.x) + ((1.0f.xxx - f0) * _3630.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_3472, _3472)) + _3567) / _3567) * window);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2445 = tdh / at;\n    float _2449 = bdh / ab;\n    float _2461 = ((_2445 * _2445) + (_2449 * _2449)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _2461) * _2461);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2542 = 1.0f / alpha;\n    return ((2.0f + _2542) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _2542)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2575 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2654 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _2654) * _2654);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _2575);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _2575));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _2727 = max(dot(L.nc, l), 0.0f);\n        float _2733 = max(dot(L.nc, h), 0.0f);\n        float _2742 = ((_2733 * _2733) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _2742) * _2742)) * (0.5f / max(lerp((2.0f * _2727) * L.coat_ndv, _2727 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2727)) * _2727).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1842 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1845 = _1842.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1845 * _1845, exp2((-9.27999973297119140625f) * ndv)) * _1845) + _1842.y)) + _1842.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_381_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _381_fa_env_horizon.w).xyz;\n    }\n    float _1747 = rough * rough;\n    float _1777 = 0.60000002384185791015625f * _1747;\n    return lerp(lerp(_381_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_381_fa_env_horizon.xyz, _381_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1747)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1777, 0.0500000007450580596923828125f + _1777, d.y).xxx), ((_381_fa_env_sky.xyz + _381_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1747 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2328;\n        if (L.aniso >= 0.0f)\n        {\n            _2328 = L.b;\n        }\n        else\n        {\n            _2328 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2328, v), _2328), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2361 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2361.x) + (L.f90.xxx * _2361.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2416 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2416.x) + _2416.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1884 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1884.x) + _1884.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1094_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1635 = int(_1094_fa_shadow_cfg.x + 0.5f);\n    float _1645 = dot(world - _1094_fa_shadow_eye.xyz, _1094_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1650 = _1635 > 0;\n    bool _1659;\n    if (_1650)\n    {\n        int param = _1635 - 1;\n        _1659 = _1645 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1659 = _1650;\n    }\n    if (_1659)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1666 = _1635 > 1;\n        bool _1673;\n        if (_1666)\n        {\n            _1673 = _1645 > _1094_fa_shadow_split.x;\n        }\n        else\n        {\n            _1673 = _1666;\n        }\n        if (_1673)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1679 = _1635 > 2;\n        bool _1686;\n        if (_1679)\n        {\n            _1686 = _1645 > _1094_fa_shadow_split.y;\n        }\n        else\n        {\n            _1686 = _1679;\n        }\n        if (_1686)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1692 = _1635 > 3;\n        bool _1699;\n        if (_1692)\n        {\n            _1699 = _1645 > _1094_fa_shadow_split.z;\n        }\n        else\n        {\n            _1699 = _1692;\n        }\n        if (_1699)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4621 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4621 = -_4621;\n    }\n    float3 _4028 = normalize(_381_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4634 = { fa_world_pos, _4621, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing };\n    SurfaceInput param_1 = _4634;\n    Surface _4036 = fa_standard_surface(param_1);\n    float3 _4652 = _4036.albedo;\n    float _4653 = _4036.alpha;\n    float3 _4654 = _4036.normal;\n    float _4655 = _4036.metallic;\n    float _4656 = _4036.roughness;\n    float _4657 = _4036.occlusion;\n    float3 _4658 = _4036.emission;\n    float _4659 = _4036.clearcoat;\n    float _4660 = _4036.clearcoat_roughness;\n    float3 _4661 = _4036.sheen_color;\n    float _4662 = _4036.sheen_roughness;\n    float _4663 = _4036.anisotropy;\n    float _4664 = _4036.anisotropy_rotation;\n    float _4665 = _4036.specular;\n    float _4666 = _4036.ior;\n    float3 _4667 = _4036.specular_color;\n    SurfaceInput _4642 = { fa_world_pos, _4621, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing };\n    SurfaceInput param_2 = _4642;\n    Surface param_3 = _4036;\n    surface(param_2, param_3);\n    _4652 = param_3.albedo;\n    _4653 = param_3.alpha;\n    _4654 = param_3.normal;\n    _4655 = param_3.metallic;\n    _4656 = param_3.roughness;\n    _4657 = param_3.occlusion;\n    _4658 = param_3.emission;\n    _4659 = param_3.clearcoat;\n    _4660 = param_3.clearcoat_roughness;\n    _4661 = param_3.sheen_color;\n    _4662 = param_3.sheen_roughness;\n    _4663 = param_3.anisotropy;\n    _4664 = param_3.anisotropy_rotation;\n    _4665 = param_3.specular;\n    _4666 = param_3.ior;\n    _4667 = param_3.specular_color;\n    if (param_3.alpha < _4047_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_381_fa_emissive.w > 0.5f)\n    {\n        result = _4652;\n    }\n    else\n    {\n        float3 _4069 = normalize(_4654);\n        float _4076 = clamp(_4655, 0.0f, 1.0f);\n        float _4080 = clamp(_4656, 0.0500000007450580596923828125f, 1.0f);\n        float _4084 = _4080 * _4080;\n        float _4088 = _4084 * _4084;\n        float _4093 = max(dot(_4069, _4028), 9.9999997473787516355514526367188e-05f);\n        float3 _4099 = _4652 * (1.0f - _4076);\n        float3 _4106 = lerp(0.039999999105930328369140625f.xxx, _4652, _4076.xxx);\n        float3 f0 = _4106;\n        SurfaceInput _4650 = { fa_world_pos, _4621, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing };\n        SurfaceInput param_4 = _4650;\n        Surface _4733 = { _4652, _4653, _4654, _4655, _4656, _4657, _4658, _4659, _4660, _4661, _4662, _4663, _4664, _4665, _4666, _4667 };\n        Surface param_5 = _4733;\n        float3 param_6 = _4069;\n        float3 param_7 = _4028;\n        float param_8 = _4076;\n        float param_9 = _4080;\n        float3 param_10 = _4106;\n        FaLayers _4122 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _4069;\n        float3 lit = (fa_ambient_light(param_11) * _4099) * _4657;\n        if (_4122.on)\n        {\n            lit *= _4122.base_scale;\n        }\n        int _4144 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4144; ln++)\n        {\n            int param_12 = ln;\n            int _4157 = fa_cl_light(param_12);\n            int param_13 = _4157;\n            float3 param_14 = fa_world_pos;\n            float3 param_15 = _4621;\n            LightSample _4166 = fa_light_shadowed(param_13, param_14, param_15);\n            float _4174 = max(dot(_4069, _4166.direction), 0.0f);\n            float _4180 = _4166.attenuation * _4166.shadow;\n            float3 _4185 = normalize(_4166.direction + _4028);\n            float _4190 = max(dot(_4069, _4185), 0.0f);\n            float _4195 = max(dot(_4028, _4185), 0.0f);\n            bool _4202;\n            if (fa_light_is_area)\n            {\n                _4202 = !_4122.on;\n            }\n            else\n            {\n                _4202 = fa_light_is_area;\n            }\n            if (_4202)\n            {\n                int param_16 = _4157;\n                float3 param_17 = fa_world_pos;\n                float3 param_18 = _4069;\n                float3 param_19 = _4028;\n                float3 param_20 = _4099;\n                float3 param_21 = f0;\n                float param_22 = _4080;\n                float param_23 = _4093;\n                float param_24 = _4180;\n                lit += fa_area_shade(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24);\n            }\n            else\n            {\n                if (_4122.on)\n                {\n                    FaLayers param_25 = _4122;\n                    float3 param_26 = _4099;\n                    float3 param_27 = f0;\n                    float3 param_28 = _4069;\n                    float3 param_29 = _4028;\n                    float3 param_30 = _4166.direction;\n                    float3 param_31 = _4185;\n                    float param_32 = _4174;\n                    float param_33 = _4093;\n                    float param_34 = _4190;\n                    float param_35 = _4195;\n                    float param_36 = _4084;\n                    float param_37 = _4088;\n                    int param_38 = _4157;\n                    lit += (fa_layers_light(param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33, param_34, param_35, param_36, param_37) * ((fa_light_rgb(param_38) * fa_light_tint) * _4180));\n                }\n                else\n                {\n                    float _4277 = ((_4190 * _4190) * (_4088 - 1.0f)) + 1.0f;\n                    int param_39 = _4157;\n                    lit += (((_4099 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _4195, 5.0f))) * (((_4088 / ((3.1415927410125732421875f * _4277) * _4277)) * (0.5f / max(lerp((2.0f * _4174) * _4093, _4174 + _4093, _4084), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4174))) * (fa_light_rgb(param_39) * fa_light_tint)) * (_4174 * _4180));\n                }\n            }\n        }\n        if (_4122.on)\n        {\n            FaLayers param_40 = _4122;\n            float3 param_41 = _4069;\n            float3 param_42 = _4028;\n            float3 param_43 = f0;\n            float param_44 = _4080;\n            lit += (fa_layers_ibl(param_40, param_41, param_42, param_43, param_44) * _4657);\n        }\n        else\n        {\n            float3 param_45 = _4069;\n            float3 param_46 = _4028;\n            float3 param_47 = f0;\n            float param_48 = _4080;\n            lit += (fa_sky_reflection(param_45, param_46, param_47, param_48) * _4657);\n        }\n        result = lit;\n    }\n    float3 _4372 = result;\n    float3 _4373 = _4372 + _4658;\n    result = _4373;\n    float3 param_49 = _4373;\n    float3 param_50 = fa_world_pos;\n    result = fa_shadow_debug(param_49, param_50);\n    bool _4382 = _381_fa_fog.w > 0.0f;\n    bool _4389;\n    if (!_4382)\n    {\n        _4389 = _381_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4389 = _4382;\n    }\n    if (_4389)\n    {\n        float3 _4398 = fa_world_pos - _381_fa_camera_pos.xyz;\n        float _4404 = dot(_4398, _381_fa_fog_c.xyz);\n        bool _4408 = _381_fa_fog_c.w > 0.5f;\n        float _4409;\n        if (_4408)\n        {\n            _4409 = _4404;\n        }\n        else\n        {\n            _4409 = length(_4398);\n        }\n        float _4421 = _4409 - _381_fa_fog_b.x;\n        if (_4421 > 0.0f)\n        {\n            float _4430 = _381_fa_fog.w * _4421;\n            float tau = _4430 * _4430;\n            if (_381_fa_fog_b.y > 0.0f)\n            {\n                float _4446;\n                if (_4408)\n                {\n                    _4446 = fa_world_pos.y - (_381_fa_fog_c.y * _4404);\n                }\n                else\n                {\n                    _4446 = _381_fa_camera_pos.y;\n                }\n                float _4467 = lerp(_4446, fa_world_pos.y, clamp(_381_fa_fog_b.x / _4409, 0.0f, 1.0f));\n                float _4471 = fa_world_pos.y - _4467;\n                float _4476 = _4467 - _381_fa_fog_b.z;\n                float _4481 = fa_world_pos.y - _381_fa_fog_b.z;\n                bool _4484 = _4476 <= 0.0f;\n                bool _4485 = !_4484;\n                bool _4491;\n                if (_4485)\n                {\n                    _4491 = _381_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4491 = _4484;\n                }\n                float _4492;\n                if (_4491)\n                {\n                    _4492 = _381_fa_fog_b.y;\n                }\n                else\n                {\n                    _4492 = _381_fa_fog_b.y * exp(-min(_381_fa_fog_b.w * _4476, 80.0f));\n                }\n                bool _4519;\n                if (_4485)\n                {\n                    _4519 = _381_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4519 = _4484;\n                }\n                float _4520;\n                if (_4519)\n                {\n                    _4520 = _381_fa_fog_b.y * _4476;\n                }\n                else\n                {\n                    _4520 = (_381_fa_fog_b.y * (1.0f - exp(-min(_381_fa_fog_b.w * _4476, 80.0f)))) / _381_fa_fog_b.w;\n                }\n                bool _4545 = _4481 <= 0.0f;\n                bool _4552;\n                if (!_4545)\n                {\n                    _4552 = _381_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4552 = _4545;\n                }\n                float _4553;\n                if (_4552)\n                {\n                    _4553 = _381_fa_fog_b.y * _4481;\n                }\n                else\n                {\n                    _4553 = (_381_fa_fog_b.y * (1.0f - exp(-min(_381_fa_fog_b.w * _4481, 80.0f)))) / _381_fa_fog_b.w;\n                }\n                float _4580;\n                if (abs(_4471) < 0.001000000047497451305389404296875f)\n                {\n                    _4580 = _4492;\n                }\n                else\n                {\n                    _4580 = (_4553 - _4520) / _4471;\n                }\n                tau += (_4421 * max(_4580, 0.0f));\n            }\n            result = lerp(result, _381_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4653);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_381",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1094",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_4047",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _382 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _382;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_389, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1985[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _381_fa_camera_pos : packoffset(c0);\n    float4 _381_fa_ambient : packoffset(c1);\n    float4 _381_fa_base_color : packoffset(c2);\n    float4 _381_fa_emissive : packoffset(c3);\n    float4 _381_fa_model_emissive : packoffset(c4);\n    float4 _381_fa_pbr : packoffset(c5);\n    float4 _381_fa_maps : packoffset(c6);\n    float4 _381_fa_fog : packoffset(c7);\n    float4 _381_fa_fog_b : packoffset(c8);\n    float4 _381_fa_fog_c : packoffset(c9);\n    float4 _381_fa_counts : packoffset(c10);\n    float4 _381_fa_env_sky : packoffset(c11);\n    float4 _381_fa_env_horizon : packoffset(c12);\n    float4 _381_fa_time : packoffset(c13);\n    float4 _381_fa_cl_vpx : packoffset(c14);\n    float4 _381_fa_cl_vpy : packoffset(c15);\n    float4 _381_fa_cl_vpw : packoffset(c16);\n    float4 _381_fa_cl_fwd : packoffset(c17);\n    float4 _381_fa_cl_grid : packoffset(c18);\n    float4 _381_fa_cl_info : packoffset(c19);\n    float4 _381_fa_layers_a : packoffset(c20);\n    float4 _381_fa_layers_b : packoffset(c21);\n    float4 _381_fa_layers_c : packoffset(c22);\n    float4 _381_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _1094_fa_shadow_mat[4] : packoffset(c0);\n    float4 _1094_fa_shadow_rect[4] : packoffset(c16);\n    float4 _1094_fa_shadow_info[4] : packoffset(c20);\n    float4 _1094_fa_shadow_split : packoffset(c24);\n    float4 _1094_fa_shadow_cfg : packoffset(c25);\n    float4 _1094_fa_shadow_bias : packoffset(c26);\n    float4 _1094_fa_shadow_eye : packoffset(c27);\n    float4 _1094_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _4047_alphaCutoff : packoffset(c0);\n    float _4047_fa_pad0 : packoffset(c0.y);\n    float _4047_fa_pad1 : packoffset(c0.z);\n    float _4047_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t9);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _863 = _381_fa_cl_info.x < 0.0f;\n    bool _870;\n    if (!_863)\n    {\n        _870 = _381_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _870 = _863;\n    }\n    bool _878;\n    if (!_870)\n    {\n        _878 = _381_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _878 = _870;\n    }\n    bool _885;\n    if (!_878)\n    {\n        _885 = _381_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _885 = _878;\n    }\n    bool _892;\n    if (!_885)\n    {\n        _892 = _381_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _892 = _885;\n    }\n    if (_892)\n    {\n        return int2(0, 0);\n    }\n    float4 _902 = float4(world_pos, 1.0f);\n    float _909 = dot(_381_fa_cl_vpw, _902);\n    if (!(_909 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _931 = float2(dot(_381_fa_cl_vpx, _902), dot(_381_fa_cl_vpy, _902)) / _909.xx;\n    int _935 = int(_381_fa_cl_grid.x);\n    int _939 = int(_381_fa_cl_grid.y);\n    int param = (int(_381_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_381_fa_cl_fwd.xyz, world_pos) + _381_fa_cl_fwd.w, _381_fa_cl_grid.w) / _381_fa_cl_grid.w) * _381_fa_cl_grid.z)), 0, int(_381_fa_cl_info.y) - 1) * _939) + clamp(int(floor(((_931.y * 0.5f) + 0.5f) * _381_fa_cl_grid.y)), 0, _939 - 1)) * _935)) + clamp(int(floor(((_931.x * 0.5f) + 0.5f) * _381_fa_cl_grid.x)), 0, _935 - 1);\n    float4 _1010 = fa_light_texel(param);\n    return int2(int(_1010.x), int(_1010.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_381_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2802 = fa_cluster_lookup(param);\n    fa_cl_slot = _2802.x;\n    fa_cl_local = _2802.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3716 = fa_linear_to_srgb(param);\n        c = _3716;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3724 = fa_srgb_to_linear(param_1);\n            c = _3724;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _313;\n    if (i.front_facing)\n    {\n        _313 = i.world_normal;\n    }\n    else\n    {\n        _313 = -i.world_normal;\n    }\n    float3 _337 = normalize(i.world_tangent.xyz - (_313 * dot(_313, i.world_tangent.xyz)));\n    float3 _365 = normalize(((_337 * m.x) + ((cross(_313, _337) * i.world_tangent.w) * m.y)) + (_313 * m.z));\n    float3 _368;\n    if (i.front_facing)\n    {\n        _368 = _365;\n    }\n    else\n    {\n        _368 = -_365;\n    }\n    return _368;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _381_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3755 = fa_tex_fix(param_2, param_3);\n    float4 _4996 = base_t;\n    _4996.x = _3755.x;\n    _4996.y = _3755.y;\n    _4996.z = _3755.z;\n    base_t = _4996;\n    float4 _3769 = (_4996 * _381_fa_base_color) * i.vertex_color;\n    float3 _4906 = i.world_normal;\n    if (_381_fa_maps.z > 0.5f)\n    {\n        float param_4 = _381_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3801 = fa_tex_fix(param_6, param_7);\n        float3 _3804 = (_3801 * 2.0f) - 1.0f.xxx;\n        float2 _3809 = _3804.xy * _381_fa_maps.x;\n        float3 _5004 = _3804;\n        _5004.x = _3809.x;\n        _5004.y = _3809.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5004;\n        _4906 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _381_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3837 = fa_tex_fix(param_12, param_13);\n    float4 _5007 = mrt;\n    _5007.x = _3837.x;\n    _5007.y = _3837.y;\n    _5007.z = _3837.z;\n    mrt = _5007;\n    float4 _3865 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _381_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3865.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3877 = fa_tex_fix(param_16, param_17);\n    float param_18 = _381_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3907 = fa_tex_fix(param_20, param_21);\n    float _4911 = _381_fa_layers_a.x;\n    float _4912 = _381_fa_layers_a.y;\n    float _4915 = _381_fa_layers_a.z;\n    float _4914 = _381_fa_layers_b.w;\n    float _4917 = _381_fa_layers_c.x;\n    if (_381_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_381_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4911 *= _3877.y;\n            _4912 *= _3877.z;\n            _4914 *= _3865.w;\n        }\n        if (_381_fa_layers_c.z > 1.5f)\n        {\n            _4915 *= mrt.x;\n            _4917 *= mrt.w;\n        }\n    }\n    Surface _4936 = { _3769.xyz, _3769.w, _4906, clamp(_381_fa_pbr.x * _3837.z, 0.0f, 1.0f), clamp(_381_fa_pbr.y * _3837.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_381_fa_maps.y * (_3877.x - 1.0f)), _381_fa_emissive.xyz + (_381_fa_model_emissive.xyz * _3907), _4911, _4912, _381_fa_layers_b.xyz, _4914, _4915, _381_fa_layers_a.w, _4917, _381_fa_layers_c.y, _381_fa_layers_d.xyz };\n    return _4936;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1910 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1918 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1921 = int(_1910);\n    int _1924 = int(_1918);\n    float _1934 = _1918 - float(_1924);\n    int _1990 = (_1921 * 9) + _1924;\n    int _2010 = ((_1921 + 1) * 9) + _1924;\n    return lerp(lerp(_1985[_1990], _1985[_1990 + 1], _1934), lerp(_1985[_2010], _1985[_2010 + 1], _1934), _1910 - float(_1921));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4842 = false;\n    float _4843 = 1.0f;\n    float _4844 = 1.0f;\n    float _4845 = 1.0f;\n    float _4846 = 0.0f;\n    float _4847 = 0.0f;\n    float _4848 = 0.0f;\n    float _4849 = 0.0f;\n    float _4851 = 1.0f;\n    bool _4852 = false;\n    float3 _4853 = 0.0f.xxx;\n    float _4854 = 1.0f;\n    float _4855 = 1.0f;\n    float _4856 = 1.0f;\n    float _4857 = 0.0f;\n    float _4858 = 0.0f;\n    float3 _4859 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4860 = float3(0.0f, 0.0f, 1.0f);\n    float _4861 = 1.0f;\n    float _4862 = 1.0f;\n    float _2064 = clamp(s.specular, 0.0f, 1.0f);\n    float _2068 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2073 = (_2064 != 1.0f) || (_2068 != 1.5f);\n    bool _2082;\n    if (!_2073)\n    {\n        _2082 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2082 = _2073;\n    }\n    if (_2082)\n    {\n        float _2090 = (_2068 - 1.0f) / (_2068 + 1.0f);\n        f0 = lerp(min((_2090 * _2090).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2064, s.albedo, metallic.xxx);\n        _4843 = lerp(_2064, 1.0f, metallic);\n        _4842 = true;\n    }\n    float _2118 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2118 > 0.0f)\n    {\n        float _2126 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4846 = _2118;\n        _4847 = _2126;\n        float _2133 = _2126 * _2126;\n        _4848 = _2133;\n        _4849 = _2133 * _2133;\n        float _2145 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4851 = _2145;\n        _4844 = 1.0f - (_2118 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2145, 0.0f, 1.0f), 5.0f))));\n        _4842 = true;\n    }\n    float3 _2165 = max(s.sheen_color, 0.0f.xxx);\n    float _2174 = max(_2165.x, max(_2165.y, _2165.z));\n    if (_2174 > 0.0f)\n    {\n        float _2182 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4852 = true;\n        _4853 = _2165;\n        _4854 = _2182;\n        _4855 = _2182 * _2182;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2182;\n        float _2199 = fa_sheen_albedo(param, param_1);\n        _4857 = _2199;\n        _4856 = 1.0f - min(_2174 * _2199, 1.0f);\n        _4842 = true;\n    }\n    _4845 = _4844 * _4856;\n    float _2218 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2218 != 0.0f)\n    {\n        float3 _2233 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2233;\n        if (dot(_2233, _2233) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2247 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2247.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2247.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2247.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2251 = t;\n        float3 _2252 = normalize(_2251);\n        t = _2252;\n        float3 _2277 = normalize((_2252 * cos(s.anisotropy_rotation)) + ((cross(n, _2252) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4859 = _2277;\n        _4860 = cross(n, _2277);\n        float _2287 = roughness * roughness;\n        float _2293 = lerp(_2287, 1.0f, _2218 * _2218);\n        bool _2295 = _2218 > 0.0f;\n        _4861 = _2295 ? _2293 : _2287;\n        _4862 = _2295 ? _2287 : _2293;\n        _4858 = _2218;\n        _4842 = true;\n    }\n    FaLayers _4884 = { _4842, _4843, _4844, _4845, _4846, _4847, _4848, _4849, i.world_normal, _4851, _4852, _4853, _4854, _4855, _4856, _4857, _4858, _4859, _4860, _4861, _4862 };\n    return _4884;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_381_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _381_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_381_fa_cl_info.x) + int(_381_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_381_fa_counts.y > 4.5f) ? 8 : 4);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _431_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _431_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _471 = dot(d, right);\n    float _475 = dot(d, up);\n    float _486;\n    if (((_471 * _471) + (_475 * _475)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _486 = atan2(_475, _471) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _486 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_486 - floor(_486)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li;\n    int _519 = fa_light_base(param);\n    bool _523 = _381_fa_counts.y > 4.5f;\n    int param_1 = _519;\n    float4 _527 = fa_light_texel(param_1);\n    int param_2 = _519 + 1;\n    float4 _532 = fa_light_texel(param_2);\n    float _535 = _532.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _547 = _523 && (_535 > 2.5f);\n    fa_light_is_area = _547;\n    bool _550 = _535 < 0.5f;\n    float3 l;\n    if (_550)\n    {\n        l = normalize(_527.xyz);\n        if (_523)\n        {\n            int param_3 = _519 + 6;\n            float4 _564 = fa_light_texel(param_3);\n            if (_564.z > 0.5f)\n            {\n                int param_4 = _519 + 4;\n                float4 _574 = fa_light_texel(param_4);\n                int param_5 = _519 + 5;\n                float4 _580 = fa_light_texel(param_5);\n                float2 param_6 = _564.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _574.xyz) * _574.w, (-dot(world_pos, _580.xyz)) * _580.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _612 = _527.xyz - world_pos;\n        float _614 = length(_612);\n        dist = _614;\n        l = _612 / max(_614, 9.9999997473787516355514526367188e-05f).xxx;\n        float reach = _614;\n        if (_547)\n        {\n            int param_8 = _519 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0f);\n        }\n        float _646 = reach / max(_527.w, 0.001000000047497451305389404296875f);\n        float _652 = clamp(1.0f - (_646 * _646), 0.0f, 1.0f);\n        atten = _652 * _652;\n        bool _660 = _535 < 2.5f;\n        if ((_535 > 1.5f) && _660)\n        {\n            int param_9 = _519 + 2;\n            float4 _668 = fa_light_texel(param_9);\n            float _678 = _668.w;\n            int param_10 = _519 + 3;\n            float4 _684 = fa_light_texel(param_10);\n            float _685 = _684.x;\n            float cos_inner = _685;\n            if (_685 > 1.5f)\n            {\n                cos_inner = lerp(_678, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_678, cos_inner, dot(-l, normalize(_668.xyz)));\n        }\n        if (_523 && _660)\n        {\n            int param_11 = _519 + 6;\n            float4 _709 = fa_light_texel(param_11);\n            int param_12 = _519 + 7;\n            float4 _714 = fa_light_texel(param_12);\n            bool _717 = _709.z > 0.5f;\n            bool _724;\n            if (!_717)\n            {\n                _724 = _714.z > 0.5f;\n            }\n            else\n            {\n                _724 = _717;\n            }\n            if (_724)\n            {\n                int param_13 = _519 + 2;\n                float4 _731 = fa_light_texel(param_13);\n                float3 _735 = normalize(_731.xyz);\n                int param_14 = _519 + 4;\n                float4 _740 = fa_light_texel(param_14);\n                int param_15 = _519 + 5;\n                float4 _745 = fa_light_texel(param_15);\n                if (_717)\n                {\n                    float3 _753 = -_612;\n                    float _760 = _731.w;\n                    float _776 = 0.5f / max(dot(_753, _735) * (sqrt(max(1.0f - (_760 * _760), 0.0f)) / max(_760, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                    float2 param_16 = _709.xy;\n                    float2 param_17 = float2(0.5f + (dot(_753, _740.xyz) * _776), 0.5f - (dot(_753, _745.xyz) * _776));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_714.z > 0.5f)\n                {\n                    float2 param_18 = _714.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _735;\n                    float3 param_21 = _740.xyz;\n                    float3 param_22 = _745.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    float3 _4830 = _532.xyz * atten;\n    if (_523)\n    {\n        _4830 *= fa_light_tint;\n    }\n    int _845;\n    if (_550)\n    {\n        _845 = 0;\n    }\n    else\n    {\n        _845 = ((_535 > 1.5f) && (_535 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4841 = { l, _4830, atten, 1.0f, dist, _845 };\n    return _4841;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1084;\n    if (i == 0)\n    {\n        _1084 = _1094_fa_shadow_split.x;\n    }\n    else\n    {\n        float _1100;\n        if (i == 1)\n        {\n            _1100 = _1094_fa_shadow_split.y;\n        }\n        else\n        {\n            float _1108;\n            if (i == 2)\n            {\n                _1108 = _1094_fa_shadow_split.z;\n            }\n            else\n            {\n                _1108 = _1094_fa_shadow_split.w;\n            }\n            _1100 = _1108;\n        }\n        _1084 = _1100;\n    }\n    return _1084;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1072 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_1072), sin(_1072)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _1146 = max(_1094_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _1151 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1157 = sqrt(1.0f - (_1151 * _1151));\n    float _1165 = min(_1157 / max(_1151, 0.20000000298023223876953125f), 4.0f);\n    float _1170;\n    if (_1094_fa_shadow_bias.y > 0.0f)\n    {\n        _1170 = _1094_fa_shadow_bias.y;\n    }\n    else\n    {\n        _1170 = 1.5f * _1094_fa_shadow_info[ci].x;\n    }\n    float4 _1195 = mul(float4(world + (n * (_1170 * _1157)), 1.0f), _1094_fa_shadow_mat[ci]);\n    float _1202 = _1195.x;\n    bool _1205 = _1202 < _1094_fa_shadow_rect[ci].x;\n    bool _1214;\n    if (!_1205)\n    {\n        _1214 = _1202 > _1094_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1214 = _1205;\n    }\n    bool _1223;\n    if (!_1214)\n    {\n        _1223 = _1195.y < _1094_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1223 = _1214;\n    }\n    bool _1232;\n    if (!_1223)\n    {\n        _1232 = _1195.y > _1094_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1232 = _1223;\n    }\n    bool _1239;\n    if (!_1232)\n    {\n        _1239 = _1195.z > 1.0f;\n    }\n    else\n    {\n        _1239 = _1232;\n    }\n    if (_1239)\n    {\n        return -1.0f;\n    }\n    float _1247;\n    if (_1094_fa_shadow_bias.x > 0.0f)\n    {\n        _1247 = _1094_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1247 = 1.5f * _1094_fa_shadow_info[ci].x;\n    }\n    float _1266 = _1195.z - ((_1247 * (1.0f + (0.5f * _1165))) / _1146);\n    float _1275 = ((_1094_fa_shadow_info[ci].x * min(_1165, 3.0f)) * 0.5f) / _1146;\n    int _1284 = int(_1094_fa_shadow_cfg.z + 0.5f);\n    if (_1284 == 1)\n    {\n        float2 param = _1195.xy;\n        float4 param_1 = _1094_fa_shadow_rect[ci];\n        float _1295 = fa_shadow_depth(param, param_1);\n        return float(_1266 <= _1295);\n    }\n    float _1302 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _1305 = _1284 == 2;\n    if (_1305)\n    {\n        float _1319 = clamp(((_1094_fa_shadow_cfg.w * _1146) * 0.25f) / _1094_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1302;\n            float2 _1338 = fa_shadow_vogel(param_2, param_3, param_4) * _1319;\n            float2 param_5 = _1195.xy + (_1338 * _1094_fa_shadow_bias.zw);\n            float4 param_6 = _1094_fa_shadow_rect[ci];\n            float _1349 = fa_shadow_depth(param_5, param_6);\n            if (_1349 < (_1266 - (length(_1338) * _1275)))\n            {\n                sum += _1349;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_1266 - (sum / cnt), 0.0f) * _1146) * _1094_fa_shadow_cfg.w) / _1094_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _1393 = _1305 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1393; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1393;\n        float param_9 = _1302;\n        float2 _1412 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1195.xy + (_1412 * _1094_fa_shadow_bias.zw);\n        float4 param_11 = _1094_fa_shadow_rect[ci];\n        float _1423 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1266 - (length(_1412) * _1275)) <= _1423);\n    }\n    return lit / float(_1393);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_381_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1453 = int(_1094_fa_shadow_cfg.x + 0.5f);\n    if (_1453 < 1)\n    {\n        return 1.0f;\n    }\n    float _1468 = dot(world - _1094_fa_shadow_eye.xyz, _1094_fa_shadow_fwd.xyz);\n    int param = _1453 - 1;\n    if (_1468 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1480 = _1453 > 1;\n    bool _1487;\n    if (_1480)\n    {\n        _1487 = _1468 > _1094_fa_shadow_split.x;\n    }\n    else\n    {\n        _1487 = _1480;\n    }\n    if (_1487)\n    {\n        ci = 1;\n    }\n    bool _1491 = _1453 > 2;\n    bool _1498;\n    if (_1491)\n    {\n        _1498 = _1468 > _1094_fa_shadow_split.y;\n    }\n    else\n    {\n        _1498 = _1491;\n    }\n    if (_1498)\n    {\n        ci = 2;\n    }\n    bool _1502 = _1453 > 3;\n    bool _1509;\n    if (_1502)\n    {\n        _1509 = _1468 > _1094_fa_shadow_split.z;\n    }\n    else\n    {\n        _1509 = _1502;\n    }\n    if (_1509)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1453)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1535 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1535;\n        if (_1535 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_1094_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1560;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1560 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1560 = _1094_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1579 = _1094_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1560, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1590 = clamp((_1468 - (fa_shadow_split_at(param_7) - _1579)) / _1579, 0.0f, 1.0f);\n        if (_1590 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1453)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1611 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1611;\n                if (_1611 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1590);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2830 = fa_light_sample(param, param_1);\n    float3 _4886 = _2830.color;\n    float _4888 = _2830.shadow;\n    if ((_2830.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2830.direction;\n        float _2844 = fa_shadow_factor(param_2, param_3);\n        _4888 = _2844;\n        _4886 *= _2844;\n    }\n    LightSample _4903 = { _2830.direction, _4886, _2830.attenuation, _4888, _2830._distance, _2830.type };\n    return _4903;\n}\n\nfloat3 fa_ltc_tangent(float3 n, float3 v)\n{\n    float3 _2884 = v - (n * dot(v, n));\n    float3 t = _2884;\n    float _2888 = dot(_2884, _2884);\n    float l2 = _2888;\n    if (_2888 < 1.0000000133514319600180897396058e-10f)\n    {\n        float3 _2898;\n        if (abs(n.z) < 0.999000012874603271484375f)\n        {\n            _2898 = cross(n, float3(0.0f, 0.0f, 1.0f));\n        }\n        else\n        {\n            _2898 = cross(n, float3(1.0f, 0.0f, 0.0f));\n        }\n        t = _2898;\n        l2 = dot(_2898, _2898);\n    }\n    return t * rsqrt(l2);\n}\n\nfloat3 fa_ltc_local(float3 t1, float3 n, float3 p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nfloat3 fa_ltc_edge_vector(float3 a, float3 b)\n{\n    float _2933 = dot(a, a);\n    float _2937 = dot(b, b);\n    if ((_2933 < 1.0000000195414813782625560981111e-24f) || (_2937 < 1.0000000195414813782625560981111e-24f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _2951 = a * rsqrt(_2933);\n    float3 _2956 = b * rsqrt(_2937);\n    float _2960 = dot(_2951, _2956);\n    float _2963 = abs(_2960);\n    float g = (((((((((((0.0416471660137176513671875f * _2963) - 0.1924748718738555908203125f) * _2963) + 0.4179156124591827392578125f) * _2963) - 0.616057217121124267578125f) * _2963) + 0.777722418308258056640625f) * _2963) - 0.999542415142059326171875f) * _2963) + 1.570791721343994140625f;\n    if (_2960 < 0.0f)\n    {\n        g = (3.1415927410125732421875f * rsqrt(max(1.0f - (_2960 * _2960), 1.0000000116860974230803549289703e-07f))) - g;\n    }\n    return cross(_2951, _2956) * g;\n}\n\nvoid fa_ltc_clip_edge(float3 a, float3 b, inout float3 sum, inout float3 leave, inout float3 enter, inout float2 seen)\n{\n    bool _3020 = a.z > 0.0f;\n    bool _3024 = b.z > 0.0f;\n    if (_3020 && _3024)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_3020 != _3024)\n        {\n            float3 _3059 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _3059.z = 0.0f;\n            if (_3020)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _3059;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _3059;\n                seen.x = 1.0f;\n            }\n            else\n            {\n                float3 param_4 = _3059;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _3059;\n                seen.y = 1.0f;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(float4 abcd, float3 p0, float3 p1, float3 p2, float3 p3)\n{\n    float3 _3108 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _3134 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _3160 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _3186 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = 0.0f.xxx;\n    float3 leave = 0.0f.xxx;\n    float3 enter = 0.0f.xxx;\n    float3 param = _3108;\n    float3 param_1 = _3134;\n    float3 param_2 = 0.0f.xxx;\n    float3 param_3 = 0.0f.xxx;\n    float3 param_4 = 0.0f.xxx;\n    float2 param_5 = 0.0f.xx;\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _3134;\n    float3 param_7 = _3160;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _3160;\n    float3 param_13 = _3186;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _3186;\n    float3 param_19 = _3108;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5f)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875f;\n}\n\nfloat fa_ltc_rect(float4 abcd, float3 center, float3 ex, float3 ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(float4 m, float shape, float3 pc, float3 ex, float3 ey)\n{\n    if ((shape < 0.5f) || (shape > 1.5f))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _3336 = (pc + (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _3360 = (pc - (ex * 0.92387950420379638671875f)) + (ey * 0.3826834261417388916015625f);\n    float3 _3376 = (pc - (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float4 param_4 = m;\n    float3 param_5 = _3336;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625f)) + (ey * 0.92387950420379638671875f);\n    float3 param_8 = _3360;\n    float4 param_9 = m;\n    float3 param_10 = _3336;\n    float3 param_11 = _3360;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    float3 param_13 = _3376;\n    float4 param_14 = m;\n    float3 param_15 = _3336;\n    float3 param_16 = _3376;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625f)) - (ey * 0.92387950420379638671875f);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875f)) - (ey * 0.3826834261417388916015625f);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nfloat2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((float2(clamp((roughness - 0.0500000007450580596923828125f) * 1.0526316165924072265625f, 0.0f, 1.0f), sqrt(clamp(1.0f - ndv, 0.0f, 1.0f))) * 63.0f) + 0.5f.xx) * 0.015625f.xx;\n}\n\nfloat3 fa_area_shade(int li, float3 world_pos, float3 n, float3 v, float3 diffuse_color, float3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _3434 = fa_light_base(param);\n    int param_1 = _3434;\n    int param_2 = _3434 + 1;\n    int param_3 = _3434 + 2;\n    int param_4 = _3434 + 4;\n    float4 _3456 = fa_light_texel(param_4);\n    int param_5 = _3434 + 5;\n    float4 _3461 = fa_light_texel(param_5);\n    int param_6 = _3434 + 6;\n    float4 _3466 = fa_light_texel(param_6);\n    float _3467 = _3466.w;\n    float3 _3472 = fa_light_texel(param_1).xyz - world_pos;\n    bool _3474 = _3467 < 1.5f;\n    bool _3481;\n    if (_3474)\n    {\n        _3481 = dot(normalize(fa_light_texel(param_3).xyz), _3472) >= 0.0f;\n    }\n    else\n    {\n        _3481 = _3474;\n    }\n    if (_3481)\n    {\n        return 0.0f.xxx;\n    }\n    bool _3490 = (_3467 > 0.5f) && _3474;\n    float _3494 = _3490 ? 1.0539000034332275390625f : 1.0f;\n    float3 _3497 = _3456.xyz;\n    float _3499 = _3456.w;\n    float3 _3505 = _3461.xyz;\n    float _3507 = _3461.w;\n    float3 up = _3505 * (_3507 * _3494);\n    float _3513;\n    if (_3490)\n    {\n        _3513 = (3.1415927410125732421875f * _3499) * _3499;\n    }\n    else\n    {\n        _3513 = (4.0f * _3499) * _3507;\n    }\n    if (_3467 > 1.5f)\n    {\n        float3 _3539 = cross(_3497, -_3472);\n        float3 perp = _3539;\n        float _3543 = dot(_3539, _3539);\n        float3 _3546;\n        if (_3543 > 1.0000000133514319600180897396058e-10f)\n        {\n            _3546 = perp * rsqrt(_3543);\n        }\n        else\n        {\n            _3546 = _3505;\n        }\n        perp = _3546;\n        up = _3546 * _3507;\n    }\n    float _3567 = max(_3513, 9.9999999747524270787835121154785e-07f);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _3577 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _3577;\n    float3 param_10 = n;\n    float3 param_11 = _3472;\n    float3 _3585 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _3577;\n    float3 param_13 = n;\n    float3 param_14 = _3497 * (_3499 * _3494);\n    float3 _3593 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _3577;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _3601 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0f, 0.0f, 0.0f, 1.0f);\n    float param_19 = _3467;\n    float3 param_20 = _3585;\n    float3 param_21 = _3593;\n    float3 param_22 = _3601;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _3620 = fa_ltc_uv(param_23, param_24) * 64.0f;\n    float2 param_25 = _3620;\n    float2 param_26 = _3620 + float2(64.0f, 0.0f);\n    float4 _3630 = fa_atlas_fetch(param_26);\n    float4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _3467;\n    float3 param_29 = _3585;\n    float3 param_30 = _3593;\n    float3 param_31 = _3601;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _3630.x) + ((1.0f.xxx - f0) * _3630.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875f * dot(_3472, _3472)) + _3567) / _3567) * window);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2445 = tdh / at;\n    float _2449 = bdh / ab;\n    float _2461 = ((_2445 * _2445) + (_2449 * _2449)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _2461) * _2461);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2542 = 1.0f / alpha;\n    return ((2.0f + _2542) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _2542)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2575 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2654 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _2654) * _2654);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _2575);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _2575));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _2727 = max(dot(L.nc, l), 0.0f);\n        float _2733 = max(dot(L.nc, h), 0.0f);\n        float _2742 = ((_2733 * _2733) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _2742) * _2742)) * (0.5f / max(lerp((2.0f * _2727) * L.coat_ndv, _2727 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2727)) * _2727).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1842 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1845 = _1842.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1845 * _1845, exp2((-9.27999973297119140625f) * ndv)) * _1845) + _1842.y)) + _1842.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_381_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _381_fa_env_horizon.w).xyz;\n    }\n    float _1747 = rough * rough;\n    float _1777 = 0.60000002384185791015625f * _1747;\n    return lerp(lerp(_381_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_381_fa_env_horizon.xyz, _381_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1747)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1777, 0.0500000007450580596923828125f + _1777, d.y).xxx), ((_381_fa_env_sky.xyz + _381_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1747 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2328;\n        if (L.aniso >= 0.0f)\n        {\n            _2328 = L.b;\n        }\n        else\n        {\n            _2328 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2328, v), _2328), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2361 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2361.x) + (L.f90.xxx * _2361.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2416 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2416.x) + _2416.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1884 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1884.x) + _1884.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_1094_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1635 = int(_1094_fa_shadow_cfg.x + 0.5f);\n    float _1645 = dot(world - _1094_fa_shadow_eye.xyz, _1094_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1650 = _1635 > 0;\n    bool _1659;\n    if (_1650)\n    {\n        int param = _1635 - 1;\n        _1659 = _1645 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1659 = _1650;\n    }\n    if (_1659)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1666 = _1635 > 1;\n        bool _1673;\n        if (_1666)\n        {\n            _1673 = _1645 > _1094_fa_shadow_split.x;\n        }\n        else\n        {\n            _1673 = _1666;\n        }\n        if (_1673)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1679 = _1635 > 2;\n        bool _1686;\n        if (_1679)\n        {\n            _1686 = _1645 > _1094_fa_shadow_split.y;\n        }\n        else\n        {\n            _1686 = _1679;\n        }\n        if (_1686)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1692 = _1635 > 3;\n        bool _1699;\n        if (_1692)\n        {\n            _1699 = _1645 > _1094_fa_shadow_split.z;\n        }\n        else\n        {\n            _1699 = _1692;\n        }\n        if (_1699)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4621 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4621 = -_4621;\n    }\n    float3 _4028 = normalize(_381_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4634 = { fa_world_pos, _4621, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing };\n    SurfaceInput param_1 = _4634;\n    Surface _4036 = fa_standard_surface(param_1);\n    float3 _4652 = _4036.albedo;\n    float _4653 = _4036.alpha;\n    float3 _4654 = _4036.normal;\n    float _4655 = _4036.metallic;\n    float _4656 = _4036.roughness;\n    float _4657 = _4036.occlusion;\n    float3 _4658 = _4036.emission;\n    float _4659 = _4036.clearcoat;\n    float _4660 = _4036.clearcoat_roughness;\n    float3 _4661 = _4036.sheen_color;\n    float _4662 = _4036.sheen_roughness;\n    float _4663 = _4036.anisotropy;\n    float _4664 = _4036.anisotropy_rotation;\n    float _4665 = _4036.specular;\n    float _4666 = _4036.ior;\n    float3 _4667 = _4036.specular_color;\n    SurfaceInput _4642 = { fa_world_pos, _4621, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing };\n    SurfaceInput param_2 = _4642;\n    Surface param_3 = _4036;\n    surface(param_2, param_3);\n    _4652 = param_3.albedo;\n    _4653 = param_3.alpha;\n    _4654 = param_3.normal;\n    _4655 = param_3.metallic;\n    _4656 = param_3.roughness;\n    _4657 = param_3.occlusion;\n    _4658 = param_3.emission;\n    _4659 = param_3.clearcoat;\n    _4660 = param_3.clearcoat_roughness;\n    _4661 = param_3.sheen_color;\n    _4662 = param_3.sheen_roughness;\n    _4663 = param_3.anisotropy;\n    _4664 = param_3.anisotropy_rotation;\n    _4665 = param_3.specular;\n    _4666 = param_3.ior;\n    _4667 = param_3.specular_color;\n    if (param_3.alpha < _4047_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_381_fa_emissive.w > 0.5f)\n    {\n        result = _4652;\n    }\n    else\n    {\n        float3 _4069 = normalize(_4654);\n        float _4076 = clamp(_4655, 0.0f, 1.0f);\n        float _4080 = clamp(_4656, 0.0500000007450580596923828125f, 1.0f);\n        float _4084 = _4080 * _4080;\n        float _4088 = _4084 * _4084;\n        float _4093 = max(dot(_4069, _4028), 9.9999997473787516355514526367188e-05f);\n        float3 _4099 = _4652 * (1.0f - _4076);\n        float3 _4106 = lerp(0.039999999105930328369140625f.xxx, _4652, _4076.xxx);\n        float3 f0 = _4106;\n        SurfaceInput _4650 = { fa_world_pos, _4621, fa_world_tangent, fa_uv, fa_vertex_color, _4028, gl_FrontFacing };\n        SurfaceInput param_4 = _4650;\n        Surface _4733 = { _4652, _4653, _4654, _4655, _4656, _4657, _4658, _4659, _4660, _4661, _4662, _4663, _4664, _4665, _4666, _4667 };\n        Surface param_5 = _4733;\n        float3 param_6 = _4069;\n        float3 param_7 = _4028;\n        float param_8 = _4076;\n        float param_9 = _4080;\n        float3 param_10 = _4106;\n        FaLayers _4122 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _4069;\n        float3 lit = (fa_ambient_light(param_11) * _4099) * _4657;\n        if (_4122.on)\n        {\n            lit *= _4122.base_scale;\n        }\n        int _4144 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4144; ln++)\n        {\n            int param_12 = ln;\n            int _4157 = fa_cl_light(param_12);\n            int param_13 = _4157;\n            float3 param_14 = fa_world_pos;\n            float3 param_15 = _4621;\n            LightSample _4166 = fa_light_shadowed(param_13, param_14, param_15);\n            float _4174 = max(dot(_4069, _4166.direction), 0.0f);\n            float _4180 = _4166.attenuation * _4166.shadow;\n            float3 _4185 = normalize(_4166.direction + _4028);\n            float _4190 = max(dot(_4069, _4185), 0.0f);\n            float _4195 = max(dot(_4028, _4185), 0.0f);\n            bool _4202;\n            if (fa_light_is_area)\n            {\n                _4202 = !_4122.on;\n            }\n            else\n            {\n                _4202 = fa_light_is_area;\n            }\n            if (_4202)\n            {\n                int param_16 = _4157;\n                float3 param_17 = fa_world_pos;\n                float3 param_18 = _4069;\n                float3 param_19 = _4028;\n                float3 param_20 = _4099;\n                float3 param_21 = f0;\n                float param_22 = _4080;\n                float param_23 = _4093;\n                float param_24 = _4180;\n                lit += fa_area_shade(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24);\n            }\n            else\n            {\n                if (_4122.on)\n                {\n                    FaLayers param_25 = _4122;\n                    float3 param_26 = _4099;\n                    float3 param_27 = f0;\n                    float3 param_28 = _4069;\n                    float3 param_29 = _4028;\n                    float3 param_30 = _4166.direction;\n                    float3 param_31 = _4185;\n                    float param_32 = _4174;\n                    float param_33 = _4093;\n                    float param_34 = _4190;\n                    float param_35 = _4195;\n                    float param_36 = _4084;\n                    float param_37 = _4088;\n                    int param_38 = _4157;\n                    lit += (fa_layers_light(param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33, param_34, param_35, param_36, param_37) * ((fa_light_rgb(param_38) * fa_light_tint) * _4180));\n                }\n                else\n                {\n                    float _4277 = ((_4190 * _4190) * (_4088 - 1.0f)) + 1.0f;\n                    int param_39 = _4157;\n                    lit += (((_4099 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _4195, 5.0f))) * (((_4088 / ((3.1415927410125732421875f * _4277) * _4277)) * (0.5f / max(lerp((2.0f * _4174) * _4093, _4174 + _4093, _4084), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _4174))) * (fa_light_rgb(param_39) * fa_light_tint)) * (_4174 * _4180));\n                }\n            }\n        }\n        if (_4122.on)\n        {\n            FaLayers param_40 = _4122;\n            float3 param_41 = _4069;\n            float3 param_42 = _4028;\n            float3 param_43 = f0;\n            float param_44 = _4080;\n            lit += (fa_layers_ibl(param_40, param_41, param_42, param_43, param_44) * _4657);\n        }\n        else\n        {\n            float3 param_45 = _4069;\n            float3 param_46 = _4028;\n            float3 param_47 = f0;\n            float param_48 = _4080;\n            lit += (fa_sky_reflection(param_45, param_46, param_47, param_48) * _4657);\n        }\n        result = lit;\n    }\n    float3 _4372 = result;\n    float3 _4373 = _4372 + _4658;\n    result = _4373;\n    float3 param_49 = _4373;\n    float3 param_50 = fa_world_pos;\n    result = fa_shadow_debug(param_49, param_50);\n    bool _4382 = _381_fa_fog.w > 0.0f;\n    bool _4389;\n    if (!_4382)\n    {\n        _4389 = _381_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4389 = _4382;\n    }\n    if (_4389)\n    {\n        float3 _4398 = fa_world_pos - _381_fa_camera_pos.xyz;\n        float _4404 = dot(_4398, _381_fa_fog_c.xyz);\n        bool _4408 = _381_fa_fog_c.w > 0.5f;\n        float _4409;\n        if (_4408)\n        {\n            _4409 = _4404;\n        }\n        else\n        {\n            _4409 = length(_4398);\n        }\n        float _4421 = _4409 - _381_fa_fog_b.x;\n        if (_4421 > 0.0f)\n        {\n            float _4430 = _381_fa_fog.w * _4421;\n            float tau = _4430 * _4430;\n            if (_381_fa_fog_b.y > 0.0f)\n            {\n                float _4446;\n                if (_4408)\n                {\n                    _4446 = fa_world_pos.y - (_381_fa_fog_c.y * _4404);\n                }\n                else\n                {\n                    _4446 = _381_fa_camera_pos.y;\n                }\n                float _4467 = lerp(_4446, fa_world_pos.y, clamp(_381_fa_fog_b.x / _4409, 0.0f, 1.0f));\n                float _4471 = fa_world_pos.y - _4467;\n                float _4476 = _4467 - _381_fa_fog_b.z;\n                float _4481 = fa_world_pos.y - _381_fa_fog_b.z;\n                bool _4484 = _4476 <= 0.0f;\n                bool _4485 = !_4484;\n                bool _4491;\n                if (_4485)\n                {\n                    _4491 = _381_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4491 = _4484;\n                }\n                float _4492;\n                if (_4491)\n                {\n                    _4492 = _381_fa_fog_b.y;\n                }\n                else\n                {\n                    _4492 = _381_fa_fog_b.y * exp(-min(_381_fa_fog_b.w * _4476, 80.0f));\n                }\n                bool _4519;\n                if (_4485)\n                {\n                    _4519 = _381_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4519 = _4484;\n                }\n                float _4520;\n                if (_4519)\n                {\n                    _4520 = _381_fa_fog_b.y * _4476;\n                }\n                else\n                {\n                    _4520 = (_381_fa_fog_b.y * (1.0f - exp(-min(_381_fa_fog_b.w * _4476, 80.0f)))) / _381_fa_fog_b.w;\n                }\n                bool _4545 = _4481 <= 0.0f;\n                bool _4552;\n                if (!_4545)\n                {\n                    _4552 = _381_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4552 = _4545;\n                }\n                float _4553;\n                if (_4552)\n                {\n                    _4553 = _381_fa_fog_b.y * _4481;\n                }\n                else\n                {\n                    _4553 = (_381_fa_fog_b.y * (1.0f - exp(-min(_381_fa_fog_b.w * _4481, 80.0f)))) / _381_fa_fog_b.w;\n                }\n                float _4580;\n                if (abs(_4471) < 0.001000000047497451305389404296875f)\n                {\n                    _4580 = _4492;\n                }\n                else\n                {\n                    _4580 = (_4553 - _4520) / _4471;\n                }\n                tau += (_4421 * max(_4580, 0.0f));\n            }\n            result = lerp(result, _381_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4653);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_381",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1094",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_4047",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _295 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _295;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0f);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _535_alphaCutoff : packoffset(c0);\n    float _535_fa_pad0 : packoffset(c0.y);\n    float _535_fa_pad1 : packoffset(c0.z);\n    float _535_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _745 = base_t;\n    _745.x = _225.x;\n    _745.y = _225.y;\n    _745.z = _225.z;\n    base_t = _745;\n    float4 _241 = (_745 * _213_fa_base_color) * i.vertex_color;\n    float3 _708 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _753 = _279;\n        _753.x = _284.x;\n        _753.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _753;\n        _708 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _756 = mrt;\n    _756.x = _313.x;\n    _756.y = _313.y;\n    _756.z = _313.z;\n    mrt = _756;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _713 = _213_fa_layers_a.x;\n    float _714 = _213_fa_layers_a.y;\n    float _717 = _213_fa_layers_a.z;\n    float _716 = _213_fa_layers_b.w;\n    float _719 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _713 *= _355.y;\n            _714 *= _355.z;\n            _716 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _717 *= mrt.x;\n            _719 *= mrt.w;\n        }\n    }\n    Surface _738 = { _241.xyz, _241.w, _708, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _713, _714, _213_fa_layers_b.xyz, _716, _717, _213_fa_layers_a.w, _719, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _738;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _619 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _619 = -_619;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _632 = { fa_world_pos, _619, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _632;\n    Surface _524 = fa_standard_surface(param);\n    float3 _643 = _524.normal;\n    SurfaceInput _640 = { fa_world_pos, _619, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _640;\n    Surface param_2 = _524;\n    surface(param_1, param_2);\n    _643 = param_2.normal;\n    if (param_2.alpha < _535_alphaCutoff)\n    {\n        discard;\n    }\n    float3 _545 = normalize(_643);\n    float3 _560 = normalize(float3(dot(fa_pre_r0, _545), dot(fa_pre_r1, _545), dot(fa_pre_r2, _545)));\n    float _572 = _560.z;\n    float2 e = _560.xy / ((abs(_560.x) + abs(_560.y)) + abs(_572)).xx;\n    if (_572 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_535",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _535_alphaCutoff : packoffset(c0);\n    float _535_fa_pad0 : packoffset(c0.y);\n    float _535_fa_pad1 : packoffset(c0.z);\n    float _535_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _745 = base_t;\n    _745.x = _225.x;\n    _745.y = _225.y;\n    _745.z = _225.z;\n    base_t = _745;\n    float4 _241 = (_745 * _213_fa_base_color) * i.vertex_color;\n    float3 _708 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _753 = _279;\n        _753.x = _284.x;\n        _753.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _753;\n        _708 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _756 = mrt;\n    _756.x = _313.x;\n    _756.y = _313.y;\n    _756.z = _313.z;\n    mrt = _756;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _713 = _213_fa_layers_a.x;\n    float _714 = _213_fa_layers_a.y;\n    float _717 = _213_fa_layers_a.z;\n    float _716 = _213_fa_layers_b.w;\n    float _719 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _713 *= _355.y;\n            _714 *= _355.z;\n            _716 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _717 *= mrt.x;\n            _719 *= mrt.w;\n        }\n    }\n    Surface _738 = { _241.xyz, _241.w, _708, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _713, _714, _213_fa_layers_b.xyz, _716, _717, _213_fa_layers_a.w, _719, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _738;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _619 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _619 = -_619;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _632 = { fa_world_pos, _619, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _632;\n    Surface _524 = fa_standard_surface(param);\n    float3 _643 = _524.normal;\n    SurfaceInput _640 = { fa_world_pos, _619, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _640;\n    Surface param_2 = _524;\n    surface(param_1, param_2);\n    _643 = param_2.normal;\n    if (param_2.alpha < _535_alphaCutoff)\n    {\n        discard;\n    }\n    float3 _545 = normalize(_643);\n    float3 _560 = normalize(float3(dot(fa_pre_r0, _545), dot(fa_pre_r1, _545), dot(fa_pre_r2, _545)));\n    float _572 = _560.z;\n    float2 e = _560.xy / ((abs(_560.x) + abs(_560.y)) + abs(_572)).xx;\n    if (_572 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_535",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _122_fa_view_proj : packoffset(c0);\n    row_major float4x4 _122_fa_light_vp : packoffset(c4);\n    float4 _122_fa_uv_scale : packoffset(c8);\n    float4 _122_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _250 = { mul(float4(position, 1.0f), model).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * _122_fa_uv_scale.xy, color, position };\n    return _250;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _233 = _190.world_pos;\n    fa_world_pos = _233;\n    fa_world_normal = _190.world_normal;\n    fa_world_tangent = _190.world_tangent;\n    fa_uv = _190.uv;\n    fa_vertex_color = _190.color;\n    gl_Position = mul(float4(_233, 1.0f), _122_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _535_alphaCutoff : packoffset(c0);\n    float _535_fa_pad0 : packoffset(c0.y);\n    float _535_fa_pad1 : packoffset(c0.z);\n    float _535_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _679 = base_t;\n    _679.x = _225.x;\n    _679.y = _225.y;\n    _679.z = _225.z;\n    base_t = _679;\n    float4 _241 = (_679 * _213_fa_base_color) * i.vertex_color;\n    float3 _648 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _687 = _279;\n        _687.x = _284.x;\n        _687.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _687;\n        _648 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _690 = mrt;\n    _690.x = _313.x;\n    _690.y = _313.y;\n    _690.z = _313.z;\n    mrt = _690;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _653 = _213_fa_layers_a.x;\n    float _654 = _213_fa_layers_a.y;\n    float _657 = _213_fa_layers_a.z;\n    float _656 = _213_fa_layers_b.w;\n    float _659 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _653 *= _355.y;\n            _654 *= _355.z;\n            _656 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _657 *= mrt.x;\n            _659 *= mrt.w;\n        }\n    }\n    Surface _678 = { _241.xyz, _241.w, _648, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _653, _654, _213_fa_layers_b.xyz, _656, _657, _213_fa_layers_a.w, _659, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _678;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _559 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _559 = -_559;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _572 = { fa_world_pos, _559, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _572;\n    SurfaceInput _580 = { fa_world_pos, _559, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _580;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _535_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_122",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_535",
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
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _127_fa_view_proj : packoffset(c0);\n    row_major float4x4 _127_fa_light_vp : packoffset(c4);\n    float4 _127_fa_uv_scale : packoffset(c8);\n    float4 _127_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _174_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _165 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_174_fa_joint_rows[_165] * weights[i]);\n        r1 += (_174_fa_joint_rows[_165 + 1] * weights[i]);\n        r2 += (_174_fa_joint_rows[_165 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _371 = { mul(float4(position, 1.0f), model).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * _127_fa_uv_scale.xy, color, position };\n    return _371;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData _311 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    float3 _354 = _311.world_pos;\n    fa_world_pos = _354;\n    fa_world_normal = _311.world_normal;\n    fa_world_tangent = _311.world_tangent;\n    fa_uv = _311.uv;\n    fa_vertex_color = _311.color;\n    gl_Position = mul(float4(_354, 1.0f), _127_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _535_alphaCutoff : packoffset(c0);\n    float _535_fa_pad0 : packoffset(c0.y);\n    float _535_fa_pad1 : packoffset(c0.z);\n    float _535_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _679 = base_t;\n    _679.x = _225.x;\n    _679.y = _225.y;\n    _679.z = _225.z;\n    base_t = _679;\n    float4 _241 = (_679 * _213_fa_base_color) * i.vertex_color;\n    float3 _648 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _687 = _279;\n        _687.x = _284.x;\n        _687.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _687;\n        _648 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _690 = mrt;\n    _690.x = _313.x;\n    _690.y = _313.y;\n    _690.z = _313.z;\n    mrt = _690;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _653 = _213_fa_layers_a.x;\n    float _654 = _213_fa_layers_a.y;\n    float _657 = _213_fa_layers_a.z;\n    float _656 = _213_fa_layers_b.w;\n    float _659 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _653 *= _355.y;\n            _654 *= _355.z;\n            _656 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _657 *= mrt.x;\n            _659 *= mrt.w;\n        }\n    }\n    Surface _678 = { _241.xyz, _241.w, _648, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _653, _654, _213_fa_layers_b.xyz, _656, _657, _213_fa_layers_a.w, _659, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _678;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _559 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _559 = -_559;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _572 = { fa_world_pos, _559, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _572;\n    SurfaceInput _580 = { fa_world_pos, _559, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _580;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _535_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 160,
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_535",
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
