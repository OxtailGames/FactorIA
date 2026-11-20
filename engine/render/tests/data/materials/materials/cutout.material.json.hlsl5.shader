{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "7cd31c28ac6572768802838498bbbd3180b96e0a1bb1bab7ad49d1d6af9d528c",
  "slang": "hlsl5",
  "params": [
    "alphaCutoff"
  ],
  "textures": [
    "mask"
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _267 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _267;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _274 = _160.world_pos;\n    fa_world_pos = _274;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_274, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1997[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _484_fa_camera_pos : packoffset(c0);\n    float4 _484_fa_ambient : packoffset(c1);\n    float4 _484_fa_base_color : packoffset(c2);\n    float4 _484_fa_emissive : packoffset(c3);\n    float4 _484_fa_model_emissive : packoffset(c4);\n    float4 _484_fa_pbr : packoffset(c5);\n    float4 _484_fa_maps : packoffset(c6);\n    float4 _484_fa_fog : packoffset(c7);\n    float4 _484_fa_fog_b : packoffset(c8);\n    float4 _484_fa_fog_c : packoffset(c9);\n    float4 _484_fa_counts : packoffset(c10);\n    float4 _484_fa_env_sky : packoffset(c11);\n    float4 _484_fa_env_horizon : packoffset(c12);\n    float4 _484_fa_time : packoffset(c13);\n    float4 _484_fa_cl_vpx : packoffset(c14);\n    float4 _484_fa_cl_vpy : packoffset(c15);\n    float4 _484_fa_cl_vpw : packoffset(c16);\n    float4 _484_fa_cl_fwd : packoffset(c17);\n    float4 _484_fa_cl_grid : packoffset(c18);\n    float4 _484_fa_cl_info : packoffset(c19);\n    float4 _484_fa_layers_a : packoffset(c20);\n    float4 _484_fa_layers_b : packoffset(c21);\n    float4 _484_fa_layers_c : packoffset(c22);\n    float4 _484_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _720_fa_shadow_mat[4] : packoffset(c0);\n    float4 _720_fa_shadow_rect[4] : packoffset(c16);\n    float4 _720_fa_shadow_info[4] : packoffset(c20);\n    float4 _720_fa_shadow_split : packoffset(c24);\n    float4 _720_fa_shadow_cfg : packoffset(c25);\n    float4 _720_fa_shadow_bias : packoffset(c26);\n    float4 _720_fa_shadow_eye : packoffset(c27);\n    float4 _720_fa_shadow_fwd : packoffset(c28);\n    float4 _720_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _3286_alphaCutoff : packoffset(c0);\n    float _3286_fa_pad0 : packoffset(c0.y);\n    float _3286_fa_pad1 : packoffset(c0.z);\n    float _3286_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t9);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t7);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t8);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _489 = _484_fa_cl_info.x < 0.0f;\n    bool _496;\n    if (!_489)\n    {\n        _496 = _484_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _496 = _489;\n    }\n    bool _504;\n    if (!_496)\n    {\n        _504 = _484_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _504 = _496;\n    }\n    bool _511;\n    if (!_504)\n    {\n        _511 = _484_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _511 = _504;\n    }\n    bool _518;\n    if (!_511)\n    {\n        _518 = _484_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _518 = _511;\n    }\n    if (_518)\n    {\n        return int2(0, 0);\n    }\n    float4 _528 = float4(world_pos, 1.0f);\n    float _535 = dot(_484_fa_cl_vpw, _528);\n    if (!(_535 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _557 = float2(dot(_484_fa_cl_vpx, _528), dot(_484_fa_cl_vpy, _528)) / _535.xx;\n    int _561 = int(_484_fa_cl_grid.x);\n    int _565 = int(_484_fa_cl_grid.y);\n    int param = (int(_484_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_484_fa_cl_fwd.xyz, world_pos) + _484_fa_cl_fwd.w, _484_fa_cl_grid.w) / _484_fa_cl_grid.w) * _484_fa_cl_grid.z)), 0, int(_484_fa_cl_info.y) - 1) * _565) + clamp(int(floor(((_557.y * 0.5f) + 0.5f) * _484_fa_cl_grid.y)), 0, _565 - 1)) * _561)) + clamp(int(floor(((_557.x * 0.5f) + 0.5f) * _484_fa_cl_grid.x)), 0, _561 - 1);\n    float4 _636 = fa_light_texel(param);\n    return int2(int(_636.x), int(_636.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_484_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2814 = fa_cluster_lookup(param);\n    fa_cl_slot = _2814.x;\n    fa_cl_local = _2814.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2954 = fa_linear_to_srgb(param);\n        c = _2954;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2962 = fa_srgb_to_linear(param_1);\n            c = _2962;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _256;\n    if (i.front_facing)\n    {\n        _256 = i.world_normal;\n    }\n    else\n    {\n        _256 = -i.world_normal;\n    }\n    float3 _280 = normalize(i.world_tangent.xyz - (_256 * dot(_256, i.world_tangent.xyz)));\n    float3 _308 = normalize(((_280 * m.x) + ((cross(_256, _280) * i.world_tangent.w) * m.y)) + (_256 * m.z));\n    float3 _311;\n    if (i.front_facing)\n    {\n        _311 = _308;\n    }\n    else\n    {\n        _311 = -_308;\n    }\n    return _311;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _484_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2993 = fa_tex_fix(param_2, param_3);\n    float4 _4207 = base_t;\n    _4207.x = _2993.x;\n    _4207.y = _2993.y;\n    _4207.z = _2993.z;\n    base_t = _4207;\n    float4 _3007 = (_4207 * _484_fa_base_color) * i.vertex_color;\n    float3 _4109 = i.world_normal;\n    if (_484_fa_maps.z > 0.5f)\n    {\n        float param_4 = _484_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3039 = fa_tex_fix(param_6, param_7);\n        float3 _3042 = (_3039 * 2.0f) - 1.0f.xxx;\n        float2 _3047 = _3042.xy * _484_fa_maps.x;\n        float3 _4215 = _3042;\n        _4215.x = _3047.x;\n        _4215.y = _3047.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4215;\n        _4109 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _484_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3076 = fa_tex_fix(param_12, param_13);\n    float4 _4218 = mrt;\n    _4218.x = _3076.x;\n    _4218.y = _3076.y;\n    _4218.z = _3076.z;\n    mrt = _4218;\n    float4 _3104 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _484_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3104.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3116 = fa_tex_fix(param_16, param_17);\n    float param_18 = _484_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3146 = fa_tex_fix(param_20, param_21);\n    float _4114 = _484_fa_layers_a.x;\n    float _4115 = _484_fa_layers_a.y;\n    float _4118 = _484_fa_layers_a.z;\n    float _4117 = _484_fa_layers_b.w;\n    float _4120 = _484_fa_layers_c.x;\n    if (_484_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_484_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4114 *= _3116.y;\n            _4115 *= _3116.z;\n            _4117 *= _3104.w;\n        }\n        if (_484_fa_layers_c.z > 1.5f)\n        {\n            _4118 *= mrt.x;\n            _4120 *= mrt.w;\n        }\n    }\n    Surface _4139 = { _3007.xyz, _3007.w, _4109, clamp(_484_fa_pbr.x * _3076.z, 0.0f, 1.0f), clamp(_484_fa_pbr.y * _3076.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_484_fa_maps.y * (_3116.x - 1.0f)), _484_fa_emissive.xyz + (_484_fa_model_emissive.xyz * _3146), _4114, _4115, _484_fa_layers_b.xyz, _4117, _4118, _484_fa_layers_a.w, _4120, _484_fa_layers_c.y, _484_fa_layers_d.xyz };\n    return _4139;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1922 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1930 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1933 = int(_1922);\n    int _1936 = int(_1930);\n    float _1946 = _1930 - float(_1936);\n    int _2002 = (_1933 * 9) + _1936;\n    int _2022 = ((_1933 + 1) * 9) + _1936;\n    return lerp(lerp(_1997[_2002], _1997[_2002 + 1], _1946), lerp(_1997[_2022], _1997[_2022 + 1], _1946), _1922 - float(_1933));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4045 = false;\n    float _4046 = 1.0f;\n    float _4047 = 1.0f;\n    float _4048 = 1.0f;\n    float _4049 = 0.0f;\n    float _4050 = 0.0f;\n    float _4051 = 0.0f;\n    float _4052 = 0.0f;\n    float _4054 = 1.0f;\n    bool _4055 = false;\n    float3 _4056 = 0.0f.xxx;\n    float _4057 = 1.0f;\n    float _4058 = 1.0f;\n    float _4059 = 1.0f;\n    float _4060 = 0.0f;\n    float _4061 = 0.0f;\n    float3 _4062 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4063 = float3(0.0f, 0.0f, 1.0f);\n    float _4064 = 1.0f;\n    float _4065 = 1.0f;\n    float _2075 = clamp(s.specular, 0.0f, 1.0f);\n    float _2079 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2084 = (_2075 != 1.0f) || (_2079 != 1.5f);\n    bool _2094;\n    if (!_2084)\n    {\n        _2094 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2094 = _2084;\n    }\n    if (_2094)\n    {\n        float _2102 = (_2079 - 1.0f) / (_2079 + 1.0f);\n        f0 = lerp(min((_2102 * _2102).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2075, s.albedo, metallic.xxx);\n        _4046 = lerp(_2075, 1.0f, metallic);\n        _4045 = true;\n    }\n    float _2130 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2130 > 0.0f)\n    {\n        float _2138 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4049 = _2130;\n        _4050 = _2138;\n        float _2145 = _2138 * _2138;\n        _4051 = _2145;\n        _4052 = _2145 * _2145;\n        float _2157 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4054 = _2157;\n        _4047 = 1.0f - (_2130 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2157, 0.0f, 1.0f), 5.0f))));\n        _4045 = true;\n    }\n    float3 _2177 = max(s.sheen_color, 0.0f.xxx);\n    float _2186 = max(_2177.x, max(_2177.y, _2177.z));\n    if (_2186 > 0.0f)\n    {\n        float _2194 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4055 = true;\n        _4056 = _2177;\n        _4057 = _2194;\n        _4058 = _2194 * _2194;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2194;\n        float _2211 = fa_sheen_albedo(param, param_1);\n        _4060 = _2211;\n        _4059 = 1.0f - min(_2186 * _2211, 1.0f);\n        _4045 = true;\n    }\n    _4048 = _4047 * _4059;\n    float _2230 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2230 != 0.0f)\n    {\n        float3 _2245 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2245;\n        if (dot(_2245, _2245) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2259 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2259.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2259.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2259.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2263 = t;\n        float3 _2264 = normalize(_2263);\n        t = _2264;\n        float3 _2289 = normalize((_2264 * cos(s.anisotropy_rotation)) + ((cross(n, _2264) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4062 = _2289;\n        _4063 = cross(n, _2289);\n        float _2299 = roughness * roughness;\n        float _2305 = lerp(_2299, 1.0f, _2230 * _2230);\n        bool _2307 = _2230 > 0.0f;\n        _4064 = _2307 ? _2305 : _2299;\n        _4065 = _2307 ? _2299 : _2305;\n        _4061 = _2230;\n        _4045 = true;\n    }\n    FaLayers _4087 = { _4045, _4046, _4047, _4048, _4049, _4050, _4051, _4052, i.world_normal, _4054, _4055, _4056, _4057, _4058, _4059, _4060, _4061, _4062, _4063, _4064, _4065 };\n    return _4087;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_484_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _484_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_484_fa_cl_info.x) + int(_484_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _356 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _362 = fa_light_texel(param_1);\n    float _365 = _362.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _372 = _365 < 0.5f;\n    float3 l;\n    if (_372)\n    {\n        l = normalize(_356.xyz);\n    }\n    else\n    {\n        float3 _384 = _356.xyz - world_pos;\n        float _386 = length(_384);\n        dist = _386;\n        l = _384 / max(_386, 9.9999997473787516355514526367188e-05f).xxx;\n        float _401 = _386 / max(_356.w, 0.001000000047497451305389404296875f);\n        float _407 = clamp(1.0f - (_401 * _401), 0.0f, 1.0f);\n        atten = _407 * _407;\n        if (_365 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _421 = fa_light_texel(param_2);\n            float _431 = _421.w;\n            int param_3 = (li * 4) + 3;\n            float4 _438 = fa_light_texel(param_3);\n            float _439 = _438.x;\n            float cos_inner = _439;\n            if (_439 > 1.5f)\n            {\n                cos_inner = lerp(_431, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_431, cos_inner, dot(-l, normalize(_421.xyz)));\n        }\n    }\n    int _470;\n    if (_372)\n    {\n        _470 = 0;\n    }\n    else\n    {\n        _470 = (_365 > 1.5f) ? 2 : 1;\n    }\n    LightSample _4044 = { l, _362.xyz * atten, atten, 1.0f, dist, _470 };\n    return _4044;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _710;\n    if (i == 0)\n    {\n        _710 = _720_fa_shadow_split.x;\n    }\n    else\n    {\n        float _726;\n        if (i == 1)\n        {\n            _726 = _720_fa_shadow_split.y;\n        }\n        else\n        {\n            float _734;\n            if (i == 2)\n            {\n                _734 = _720_fa_shadow_split.z;\n            }\n            else\n            {\n                _734 = _720_fa_shadow_split.w;\n            }\n            _726 = _734;\n        }\n        _710 = _726;\n    }\n    return _710;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _767 = fa_shadow_depth(param, param_1);\n    float _771;\n    if (conv.x < 0.5f)\n    {\n        _771 = _767;\n    }\n    else\n    {\n        _771 = (conv.y * conv.z) / (conv.z - (_767 * (conv.z - conv.y)));\n    }\n    return _771;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _698 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_698), sin(_698)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _817 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _831 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _817;\n            float2 _850 = fa_shadow_vogel(param_3, param_4, param_5) * _831;\n            float2 param_6 = uv + (_850 * _720_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _862 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_862 < (zr - (length(_850) * plane)))\n            {\n                sum += _862;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _906 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _906; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _906;\n        float param_11 = _817;\n        float2 _925 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_925 * _720_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_925) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_906);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _967 = max(_720_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _972 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _978 = sqrt(1.0f - (_972 * _972));\n    float _986 = min(_978 / max(_972, 0.20000000298023223876953125f), 4.0f);\n    float _991;\n    if (_720_fa_shadow_bias.y > 0.0f)\n    {\n        _991 = _720_fa_shadow_bias.y;\n    }\n    else\n    {\n        _991 = 1.5f * _720_fa_shadow_info[ci].x;\n    }\n    float4 _1016 = mul(float4(world + (n * (_991 * _978)), 1.0f), _720_fa_shadow_mat[ci]);\n    float _1023 = _1016.x;\n    bool _1026 = _1023 < _720_fa_shadow_rect[ci].x;\n    bool _1035;\n    if (!_1026)\n    {\n        _1035 = _1023 > _720_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1035 = _1026;\n    }\n    bool _1044;\n    if (!_1035)\n    {\n        _1044 = _1016.y < _720_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1044 = _1035;\n    }\n    bool _1053;\n    if (!_1044)\n    {\n        _1053 = _1016.y > _720_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1053 = _1044;\n    }\n    bool _1060;\n    if (!_1053)\n    {\n        _1060 = _1016.z > 1.0f;\n    }\n    else\n    {\n        _1060 = _1053;\n    }\n    if (_1060)\n    {\n        return -1.0f;\n    }\n    float _1069;\n    if (_720_fa_shadow_bias.x > 0.0f)\n    {\n        _1069 = _720_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1069 = 1.5f * _720_fa_shadow_info[ci].x;\n    }\n    float2 param = _1016.xy;\n    float4 param_1 = _720_fa_shadow_rect[ci];\n    float param_2 = _1016.z - ((_1069 * (1.0f + (0.5f * _986))) / _967);\n    float param_3 = _720_fa_shadow_info[ci].x;\n    float param_4 = _967;\n    float param_5 = _967 * 0.25f;\n    float param_6 = ((_720_fa_shadow_info[ci].x * min(_986, 3.0f)) * 0.5f) / _967;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_720_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _720_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_484_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1463 = int(_720_fa_shadow_cfg.x + 0.5f);\n    if (_1463 < 1)\n    {\n        return 1.0f;\n    }\n    float _1479 = dot(world - _720_fa_shadow_eye.xyz, _720_fa_shadow_fwd.xyz);\n    int param = _1463 - 1;\n    if (_1479 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1491 = _1463 > 1;\n    bool _1498;\n    if (_1491)\n    {\n        _1498 = _1479 > _720_fa_shadow_split.x;\n    }\n    else\n    {\n        _1498 = _1491;\n    }\n    if (_1498)\n    {\n        ci = 1;\n    }\n    bool _1502 = _1463 > 2;\n    bool _1509;\n    if (_1502)\n    {\n        _1509 = _1479 > _720_fa_shadow_split.y;\n    }\n    else\n    {\n        _1509 = _1502;\n    }\n    if (_1509)\n    {\n        ci = 2;\n    }\n    bool _1513 = _1463 > 3;\n    bool _1520;\n    if (_1513)\n    {\n        _1520 = _1479 > _720_fa_shadow_split.z;\n    }\n    else\n    {\n        _1520 = _1513;\n    }\n    if (_1520)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1463)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1546 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1546;\n        if (_1546 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_720_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1571;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1571 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1571 = _720_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1590 = _720_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1571, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1601 = clamp((_1479 - (fa_shadow_split_at(param_7) - _1590)) / _1590, 0.0f, 1.0f);\n        if (_1601 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1463)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1622 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1622;\n                if (_1622 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1601);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1128 = _484_fa_pbr.z < 0.5f;\n    bool _1136;\n    if (!_1128)\n    {\n        _1136 = _720_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1136 = _1128;\n    }\n    if (_1136)\n    {\n        return 1.0f;\n    }\n    int param = (int(_720_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1149 = fa_light_texel(param);\n    float _1150 = _1149.x;\n    if (_1150 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1159 = int(_1150 + 0.5f);\n    int param_1 = _1159;\n    float4 _1163 = fa_light_texel(param_1);\n    int param_2 = _1159 + 1;\n    float4 _1168 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1171 = _1163.y;\n    if (_1171 > 0.0f)\n    {\n        float _1188 = 1.0f - smoothstep(0.75f * _1171, _1171, length(world - _720_fa_shadow_eye.xyz));\n        fade = _1188;\n        if (_1188 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1163.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1207 = world - fa_light_texel(param_3).xyz;\n        float3 _1210 = abs(_1207);\n        float _1212 = _1210.x;\n        float _1214 = _1210.y;\n        bool _1215 = _1212 >= _1214;\n        bool _1223;\n        if (_1215)\n        {\n            _1223 = _1212 >= _1210.z;\n        }\n        else\n        {\n            _1223 = _1215;\n        }\n        int _1224;\n        if (_1223)\n        {\n            _1224 = (_1207.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1237;\n            if (_1214 >= _1210.z)\n            {\n                _1237 = (_1207.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1237 = (_1207.z > 0.0f) ? 4 : 5;\n            }\n            _1224 = _1237;\n        }\n        face = _1224;\n    }\n    int _1256 = (_1159 + 2) + (face * 6);\n    int param_4 = _1256;\n    int param_5 = _1256 + 1;\n    int param_6 = _1256 + 3;\n    float4 _1270 = fa_light_texel(param_6);\n    int param_7 = _1256 + 4;\n    float4 _1275 = fa_light_texel(param_7);\n    int param_8 = _1256 + 5;\n    float4 _1280 = fa_light_texel(param_8);\n    float _1292 = _1280.x * max(dot(_1270, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1297 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1303 = sqrt(1.0f - (_1297 * _1297));\n    float _1309 = min(_1303 / max(_1297, 0.20000000298023223876953125f), 4.0f);\n    float _1312 = _1168.y;\n    float _1314;\n    if (_1312 > 0.0f)\n    {\n        _1314 = _1312;\n    }\n    else\n    {\n        _1314 = 1.5f * _1292;\n    }\n    float4 _1334 = float4(world + (n * (_1314 * _1303)), 1.0f);\n    float _1338 = dot(_1270, _1334);\n    float _1341 = _1280.y;\n    if (_1338 < _1341)\n    {\n        return 1.0f;\n    }\n    float2 _1356 = float2(dot(fa_light_texel(param_4), _1334), dot(fa_light_texel(param_5), _1334)) / _1338.xx;\n    float _1358 = _1356.x;\n    bool _1361 = _1358 < _1275.x;\n    bool _1370;\n    if (!_1361)\n    {\n        _1370 = _1358 > _1275.z;\n    }\n    else\n    {\n        _1370 = _1361;\n    }\n    bool _1379;\n    if (!_1370)\n    {\n        _1379 = _1356.y < _1275.y;\n    }\n    else\n    {\n        _1379 = _1370;\n    }\n    bool _1388;\n    if (!_1379)\n    {\n        _1388 = _1356.y > _1275.w;\n    }\n    else\n    {\n        _1388 = _1379;\n    }\n    if (_1388)\n    {\n        return 1.0f;\n    }\n    float _1394 = _1168.x;\n    float _1396;\n    if (_1394 > 0.0f)\n    {\n        _1396 = _1394;\n    }\n    else\n    {\n        _1396 = 1.5f * _1292;\n    }\n    float2 param_9 = _1356;\n    float4 param_10 = _1275;\n    float param_11 = _1338 - (_1396 * (1.0f + (0.5f * _1309)));\n    float param_12 = _1292;\n    float param_13 = 1.0f;\n    float param_14 = _1280.z * 0.25f;\n    float param_15 = (_1292 * min(_1309, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _1341, _1280.z);\n    int param_17 = int(_1163.z + 0.5f);\n    float param_18 = _1163.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2842 = fa_light_sample(param, param_1);\n    float3 _4094 = _2842.direction;\n    float3 _4089 = _2842.color;\n    float _4096 = _2842.attenuation;\n    float _4091 = _2842.shadow;\n    int _4099 = _2842.type;\n    if ((_4099 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _4094;\n        float _2856 = fa_shadow_factor(param_2, param_3);\n        _4091 = _2856;\n        _4089 *= _2856;\n    }\n    else\n    {\n        bool _2867 = _4099 != 0;\n        bool _2873;\n        if (_2867)\n        {\n            _2873 = _4096 > 0.0f;\n        }\n        else\n        {\n            _2873 = _2867;\n        }\n        if (_2873)\n        {\n            int param_4 = li;\n            float3 param_5 = world_pos;\n            float3 param_6 = gn;\n            float3 param_7 = _4094;\n            float _2885 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _4091 = _2885;\n            _4089 *= _2885;\n        }\n    }\n    LightSample _4106 = { _4094, _4089, _4096, _4091, _2842._distance, _4099 };\n    return _4106;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2457 = tdh / at;\n    float _2461 = bdh / ab;\n    float _2473 = ((_2457 * _2457) + (_2461 * _2461)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _2473) * _2473);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2554 = 1.0f / alpha;\n    return ((2.0f + _2554) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _2554)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2587 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2666 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _2666) * _2666);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _2587);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _2587));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _2739 = max(dot(L.nc, l), 0.0f);\n        float _2745 = max(dot(L.nc, h), 0.0f);\n        float _2754 = ((_2745 * _2745) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _2754) * _2754)) * (0.5f / max(lerp((2.0f * _2739) * L.coat_ndv, _2739 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2739)) * _2739).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1854 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1857 = _1854.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1857 * _1857, exp2((-9.27999973297119140625f) * ndv)) * _1857) + _1854.y)) + _1854.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_484_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _484_fa_env_horizon.w).xyz;\n    }\n    float _1759 = rough * rough;\n    float _1789 = 0.60000002384185791015625f * _1759;\n    return lerp(lerp(_484_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_484_fa_env_horizon.xyz, _484_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1759)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1789, 0.0500000007450580596923828125f + _1789, d.y).xxx), ((_484_fa_env_sky.xyz + _484_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1759 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2340;\n        if (L.aniso >= 0.0f)\n        {\n            _2340 = L.b;\n        }\n        else\n        {\n            _2340 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2340, v), _2340), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2373 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2373.x) + (L.f90.xxx * _2373.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2428 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2428.x) + _2428.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1896 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1896.x) + _1896.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_720_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1646 = int(_720_fa_shadow_cfg.x + 0.5f);\n    float _1656 = dot(world - _720_fa_shadow_eye.xyz, _720_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1661 = _1646 > 0;\n    bool _1670;\n    if (_1661)\n    {\n        int param = _1646 - 1;\n        _1670 = _1656 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1670 = _1661;\n    }\n    if (_1670)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1677 = _1646 > 1;\n        bool _1684;\n        if (_1677)\n        {\n            _1684 = _1656 > _720_fa_shadow_split.x;\n        }\n        else\n        {\n            _1684 = _1677;\n        }\n        if (_1684)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1690 = _1646 > 2;\n        bool _1697;\n        if (_1690)\n        {\n            _1697 = _1656 > _720_fa_shadow_split.y;\n        }\n        else\n        {\n            _1697 = _1690;\n        }\n        if (_1697)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1703 = _1646 > 3;\n        bool _1710;\n        if (_1703)\n        {\n            _1710 = _1656 > _720_fa_shadow_split.z;\n        }\n        else\n        {\n            _1710 = _1703;\n        }\n        if (_1710)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3824 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3824 = -_3824;\n    }\n    float3 _3267 = normalize(_484_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3837 = { fa_world_pos, _3824, fa_world_tangent, fa_uv, fa_vertex_color, _3267, gl_FrontFacing };\n    SurfaceInput param_1 = _3837;\n    Surface _3275 = fa_standard_surface(param_1);\n    float3 _3855 = _3275.albedo;\n    float _3856 = _3275.alpha;\n    float3 _3857 = _3275.normal;\n    float _3858 = _3275.metallic;\n    float _3859 = _3275.roughness;\n    float _3860 = _3275.occlusion;\n    float3 _3861 = _3275.emission;\n    float _3862 = _3275.clearcoat;\n    float _3863 = _3275.clearcoat_roughness;\n    float3 _3864 = _3275.sheen_color;\n    float _3865 = _3275.sheen_roughness;\n    float _3866 = _3275.anisotropy;\n    float _3867 = _3275.anisotropy_rotation;\n    float _3868 = _3275.specular;\n    float _3869 = _3275.ior;\n    float3 _3870 = _3275.specular_color;\n    SurfaceInput _3845 = { fa_world_pos, _3824, fa_world_tangent, fa_uv, fa_vertex_color, _3267, gl_FrontFacing };\n    SurfaceInput param_2 = _3845;\n    Surface param_3 = _3275;\n    surface(param_2, param_3);\n    _3855 = param_3.albedo;\n    _3856 = param_3.alpha;\n    _3857 = param_3.normal;\n    _3858 = param_3.metallic;\n    _3859 = param_3.roughness;\n    _3860 = param_3.occlusion;\n    _3861 = param_3.emission;\n    _3862 = param_3.clearcoat;\n    _3863 = param_3.clearcoat_roughness;\n    _3864 = param_3.sheen_color;\n    _3865 = param_3.sheen_roughness;\n    _3866 = param_3.anisotropy;\n    _3867 = param_3.anisotropy_rotation;\n    _3868 = param_3.specular;\n    _3869 = param_3.ior;\n    _3870 = param_3.specular_color;\n    if (param_3.alpha < _3286_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_484_fa_emissive.w > 0.5f)\n    {\n        result = _3855;\n    }\n    else\n    {\n        float3 _3308 = normalize(_3857);\n        float _3315 = clamp(_3858, 0.0f, 1.0f);\n        float _3319 = clamp(_3859, 0.0500000007450580596923828125f, 1.0f);\n        float _3323 = _3319 * _3319;\n        float _3327 = _3323 * _3323;\n        float _3332 = max(dot(_3308, _3267), 9.9999997473787516355514526367188e-05f);\n        float3 _3338 = _3855 * (1.0f - _3315);\n        float3 _3345 = lerp(0.039999999105930328369140625f.xxx, _3855, _3315.xxx);\n        float3 f0 = _3345;\n        SurfaceInput _3853 = { fa_world_pos, _3824, fa_world_tangent, fa_uv, fa_vertex_color, _3267, gl_FrontFacing };\n        SurfaceInput param_4 = _3853;\n        Surface _3936 = { _3855, _3856, _3857, _3858, _3859, _3860, _3861, _3862, _3863, _3864, _3865, _3866, _3867, _3868, _3869, _3870 };\n        Surface param_5 = _3936;\n        float3 param_6 = _3308;\n        float3 param_7 = _3267;\n        float param_8 = _3315;\n        float param_9 = _3319;\n        float3 param_10 = _3345;\n        FaLayers _3361 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _3308;\n        float3 lit = (fa_ambient_light(param_11) * _3338) * _3860;\n        if (_3361.on)\n        {\n            lit *= _3361.base_scale;\n        }\n        int _3383 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3383; ln++)\n        {\n            int param_12 = ln;\n            int _3396 = fa_cl_light(param_12);\n            int param_13 = _3396;\n            float3 param_14 = fa_world_pos;\n            float3 param_15 = _3824;\n            LightSample _3405 = fa_light_shadowed(param_13, param_14, param_15);\n            float3 _4029 = _3405.direction;\n            float _3413 = max(dot(_3308, _4029), 0.0f);\n            float _3419 = _3405.attenuation * _3405.shadow;\n            float3 _3424 = normalize(_4029 + _3267);\n            float _3429 = max(dot(_3308, _3424), 0.0f);\n            float _3434 = max(dot(_3267, _3424), 0.0f);\n            if (_3361.on)\n            {\n                FaLayers param_16 = _3361;\n                float3 param_17 = _3338;\n                float3 param_18 = f0;\n                float3 param_19 = _3308;\n                float3 param_20 = _3267;\n                float3 param_21 = _4029;\n                float3 param_22 = _3424;\n                float param_23 = _3413;\n                float param_24 = _3332;\n                float param_25 = _3429;\n                float param_26 = _3434;\n                float param_27 = _3323;\n                float param_28 = _3327;\n                int param_29 = _3396;\n                lit += (fa_layers_light(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28) * (fa_light_rgb(param_29) * _3419));\n            }\n            else\n            {\n                float _3482 = ((_3429 * _3429) * (_3327 - 1.0f)) + 1.0f;\n                int param_30 = _3396;\n                lit += (((_3338 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _3434, 5.0f))) * (((_3327 / ((3.1415927410125732421875f * _3482) * _3482)) * (0.5f / max(lerp((2.0f * _3413) * _3332, _3413 + _3332, _3323), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _3413))) * fa_light_rgb(param_30)) * (_3413 * _3419));\n            }\n        }\n        if (_3361.on)\n        {\n            FaLayers param_31 = _3361;\n            float3 param_32 = _3308;\n            float3 param_33 = _3267;\n            float3 param_34 = f0;\n            float param_35 = _3319;\n            lit += (fa_layers_ibl(param_31, param_32, param_33, param_34, param_35) * _3860);\n        }\n        else\n        {\n            float3 param_36 = _3308;\n            float3 param_37 = _3267;\n            float3 param_38 = f0;\n            float param_39 = _3319;\n            lit += (fa_sky_reflection(param_36, param_37, param_38, param_39) * _3860);\n        }\n        result = lit;\n    }\n    float3 _3575 = result;\n    float3 _3576 = _3575 + _3861;\n    result = _3576;\n    float3 param_40 = _3576;\n    float3 param_41 = fa_world_pos;\n    result = fa_shadow_debug(param_40, param_41);\n    bool _3585 = _484_fa_fog.w > 0.0f;\n    bool _3592;\n    if (!_3585)\n    {\n        _3592 = _484_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3592 = _3585;\n    }\n    if (_3592)\n    {\n        float3 _3601 = fa_world_pos - _484_fa_camera_pos.xyz;\n        float _3607 = dot(_3601, _484_fa_fog_c.xyz);\n        bool _3611 = _484_fa_fog_c.w > 0.5f;\n        float _3612;\n        if (_3611)\n        {\n            _3612 = _3607;\n        }\n        else\n        {\n            _3612 = length(_3601);\n        }\n        float _3624 = _3612 - _484_fa_fog_b.x;\n        if (_3624 > 0.0f)\n        {\n            float _3633 = _484_fa_fog.w * _3624;\n            float tau = _3633 * _3633;\n            if (_484_fa_fog_b.y > 0.0f)\n            {\n                float _3649;\n                if (_3611)\n                {\n                    _3649 = fa_world_pos.y - (_484_fa_fog_c.y * _3607);\n                }\n                else\n                {\n                    _3649 = _484_fa_camera_pos.y;\n                }\n                float _3670 = lerp(_3649, fa_world_pos.y, clamp(_484_fa_fog_b.x / _3612, 0.0f, 1.0f));\n                float _3674 = fa_world_pos.y - _3670;\n                float _3679 = _3670 - _484_fa_fog_b.z;\n                float _3684 = fa_world_pos.y - _484_fa_fog_b.z;\n                bool _3687 = _3679 <= 0.0f;\n                bool _3688 = !_3687;\n                bool _3694;\n                if (_3688)\n                {\n                    _3694 = _484_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3694 = _3687;\n                }\n                float _3695;\n                if (_3694)\n                {\n                    _3695 = _484_fa_fog_b.y;\n                }\n                else\n                {\n                    _3695 = _484_fa_fog_b.y * exp(-min(_484_fa_fog_b.w * _3679, 80.0f));\n                }\n                bool _3722;\n                if (_3688)\n                {\n                    _3722 = _484_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3722 = _3687;\n                }\n                float _3723;\n                if (_3722)\n                {\n                    _3723 = _484_fa_fog_b.y * _3679;\n                }\n                else\n                {\n                    _3723 = (_484_fa_fog_b.y * (1.0f - exp(-min(_484_fa_fog_b.w * _3679, 80.0f)))) / _484_fa_fog_b.w;\n                }\n                bool _3748 = _3684 <= 0.0f;\n                bool _3755;\n                if (!_3748)\n                {\n                    _3755 = _484_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3755 = _3748;\n                }\n                float _3756;\n                if (_3755)\n                {\n                    _3756 = _484_fa_fog_b.y * _3684;\n                }\n                else\n                {\n                    _3756 = (_484_fa_fog_b.y * (1.0f - exp(-min(_484_fa_fog_b.w * _3684, 80.0f)))) / _484_fa_fog_b.w;\n                }\n                float _3783;\n                if (abs(_3674) < 0.001000000047497451305389404296875f)\n                {\n                    _3783 = _3695;\n                }\n                else\n                {\n                    _3783 = (_3756 - _3723) / _3674;\n                }\n                tau += (_3624 * max(_3783, 0.0f));\n            }\n            result = lerp(result, _484_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3856);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_484",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_720",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3286",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 8
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _388 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _388;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _395 = _273.world_pos;\n    fa_world_pos = _395;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_395, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _1997[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _484_fa_camera_pos : packoffset(c0);\n    float4 _484_fa_ambient : packoffset(c1);\n    float4 _484_fa_base_color : packoffset(c2);\n    float4 _484_fa_emissive : packoffset(c3);\n    float4 _484_fa_model_emissive : packoffset(c4);\n    float4 _484_fa_pbr : packoffset(c5);\n    float4 _484_fa_maps : packoffset(c6);\n    float4 _484_fa_fog : packoffset(c7);\n    float4 _484_fa_fog_b : packoffset(c8);\n    float4 _484_fa_fog_c : packoffset(c9);\n    float4 _484_fa_counts : packoffset(c10);\n    float4 _484_fa_env_sky : packoffset(c11);\n    float4 _484_fa_env_horizon : packoffset(c12);\n    float4 _484_fa_time : packoffset(c13);\n    float4 _484_fa_cl_vpx : packoffset(c14);\n    float4 _484_fa_cl_vpy : packoffset(c15);\n    float4 _484_fa_cl_vpw : packoffset(c16);\n    float4 _484_fa_cl_fwd : packoffset(c17);\n    float4 _484_fa_cl_grid : packoffset(c18);\n    float4 _484_fa_cl_info : packoffset(c19);\n    float4 _484_fa_layers_a : packoffset(c20);\n    float4 _484_fa_layers_b : packoffset(c21);\n    float4 _484_fa_layers_c : packoffset(c22);\n    float4 _484_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _720_fa_shadow_mat[4] : packoffset(c0);\n    float4 _720_fa_shadow_rect[4] : packoffset(c16);\n    float4 _720_fa_shadow_info[4] : packoffset(c20);\n    float4 _720_fa_shadow_split : packoffset(c24);\n    float4 _720_fa_shadow_cfg : packoffset(c25);\n    float4 _720_fa_shadow_bias : packoffset(c26);\n    float4 _720_fa_shadow_eye : packoffset(c27);\n    float4 _720_fa_shadow_fwd : packoffset(c28);\n    float4 _720_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _3286_alphaCutoff : packoffset(c0);\n    float _3286_fa_pad0 : packoffset(c0.y);\n    float _3286_fa_pad1 : packoffset(c0.z);\n    float _3286_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t9);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t7);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t8);\nTexture2D<float4> mask : register(t6);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _489 = _484_fa_cl_info.x < 0.0f;\n    bool _496;\n    if (!_489)\n    {\n        _496 = _484_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _496 = _489;\n    }\n    bool _504;\n    if (!_496)\n    {\n        _504 = _484_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _504 = _496;\n    }\n    bool _511;\n    if (!_504)\n    {\n        _511 = _484_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _511 = _504;\n    }\n    bool _518;\n    if (!_511)\n    {\n        _518 = _484_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _518 = _511;\n    }\n    if (_518)\n    {\n        return int2(0, 0);\n    }\n    float4 _528 = float4(world_pos, 1.0f);\n    float _535 = dot(_484_fa_cl_vpw, _528);\n    if (!(_535 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _557 = float2(dot(_484_fa_cl_vpx, _528), dot(_484_fa_cl_vpy, _528)) / _535.xx;\n    int _561 = int(_484_fa_cl_grid.x);\n    int _565 = int(_484_fa_cl_grid.y);\n    int param = (int(_484_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_484_fa_cl_fwd.xyz, world_pos) + _484_fa_cl_fwd.w, _484_fa_cl_grid.w) / _484_fa_cl_grid.w) * _484_fa_cl_grid.z)), 0, int(_484_fa_cl_info.y) - 1) * _565) + clamp(int(floor(((_557.y * 0.5f) + 0.5f) * _484_fa_cl_grid.y)), 0, _565 - 1)) * _561)) + clamp(int(floor(((_557.x * 0.5f) + 0.5f) * _484_fa_cl_grid.x)), 0, _561 - 1);\n    float4 _636 = fa_light_texel(param);\n    return int2(int(_636.x), int(_636.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_484_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2814 = fa_cluster_lookup(param);\n    fa_cl_slot = _2814.x;\n    fa_cl_local = _2814.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2954 = fa_linear_to_srgb(param);\n        c = _2954;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2962 = fa_srgb_to_linear(param_1);\n            c = _2962;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _256;\n    if (i.front_facing)\n    {\n        _256 = i.world_normal;\n    }\n    else\n    {\n        _256 = -i.world_normal;\n    }\n    float3 _280 = normalize(i.world_tangent.xyz - (_256 * dot(_256, i.world_tangent.xyz)));\n    float3 _308 = normalize(((_280 * m.x) + ((cross(_256, _280) * i.world_tangent.w) * m.y)) + (_256 * m.z));\n    float3 _311;\n    if (i.front_facing)\n    {\n        _311 = _308;\n    }\n    else\n    {\n        _311 = -_308;\n    }\n    return _311;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _484_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2993 = fa_tex_fix(param_2, param_3);\n    float4 _4207 = base_t;\n    _4207.x = _2993.x;\n    _4207.y = _2993.y;\n    _4207.z = _2993.z;\n    base_t = _4207;\n    float4 _3007 = (_4207 * _484_fa_base_color) * i.vertex_color;\n    float3 _4109 = i.world_normal;\n    if (_484_fa_maps.z > 0.5f)\n    {\n        float param_4 = _484_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3039 = fa_tex_fix(param_6, param_7);\n        float3 _3042 = (_3039 * 2.0f) - 1.0f.xxx;\n        float2 _3047 = _3042.xy * _484_fa_maps.x;\n        float3 _4215 = _3042;\n        _4215.x = _3047.x;\n        _4215.y = _3047.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4215;\n        _4109 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _484_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3076 = fa_tex_fix(param_12, param_13);\n    float4 _4218 = mrt;\n    _4218.x = _3076.x;\n    _4218.y = _3076.y;\n    _4218.z = _3076.z;\n    mrt = _4218;\n    float4 _3104 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _484_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3104.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3116 = fa_tex_fix(param_16, param_17);\n    float param_18 = _484_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3146 = fa_tex_fix(param_20, param_21);\n    float _4114 = _484_fa_layers_a.x;\n    float _4115 = _484_fa_layers_a.y;\n    float _4118 = _484_fa_layers_a.z;\n    float _4117 = _484_fa_layers_b.w;\n    float _4120 = _484_fa_layers_c.x;\n    if (_484_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_484_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4114 *= _3116.y;\n            _4115 *= _3116.z;\n            _4117 *= _3104.w;\n        }\n        if (_484_fa_layers_c.z > 1.5f)\n        {\n            _4118 *= mrt.x;\n            _4120 *= mrt.w;\n        }\n    }\n    Surface _4139 = { _3007.xyz, _3007.w, _4109, clamp(_484_fa_pbr.x * _3076.z, 0.0f, 1.0f), clamp(_484_fa_pbr.y * _3076.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_484_fa_maps.y * (_3116.x - 1.0f)), _484_fa_emissive.xyz + (_484_fa_model_emissive.xyz * _3146), _4114, _4115, _484_fa_layers_b.xyz, _4117, _4118, _484_fa_layers_a.w, _4120, _484_fa_layers_c.y, _484_fa_layers_d.xyz };\n    return _4139;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1922 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1930 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1933 = int(_1922);\n    int _1936 = int(_1930);\n    float _1946 = _1930 - float(_1936);\n    int _2002 = (_1933 * 9) + _1936;\n    int _2022 = ((_1933 + 1) * 9) + _1936;\n    return lerp(lerp(_1997[_2002], _1997[_2002 + 1], _1946), lerp(_1997[_2022], _1997[_2022 + 1], _1946), _1922 - float(_1933));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _4045 = false;\n    float _4046 = 1.0f;\n    float _4047 = 1.0f;\n    float _4048 = 1.0f;\n    float _4049 = 0.0f;\n    float _4050 = 0.0f;\n    float _4051 = 0.0f;\n    float _4052 = 0.0f;\n    float _4054 = 1.0f;\n    bool _4055 = false;\n    float3 _4056 = 0.0f.xxx;\n    float _4057 = 1.0f;\n    float _4058 = 1.0f;\n    float _4059 = 1.0f;\n    float _4060 = 0.0f;\n    float _4061 = 0.0f;\n    float3 _4062 = float3(1.0f, 0.0f, 0.0f);\n    float3 _4063 = float3(0.0f, 0.0f, 1.0f);\n    float _4064 = 1.0f;\n    float _4065 = 1.0f;\n    float _2075 = clamp(s.specular, 0.0f, 1.0f);\n    float _2079 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2084 = (_2075 != 1.0f) || (_2079 != 1.5f);\n    bool _2094;\n    if (!_2084)\n    {\n        _2094 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2094 = _2084;\n    }\n    if (_2094)\n    {\n        float _2102 = (_2079 - 1.0f) / (_2079 + 1.0f);\n        f0 = lerp(min((_2102 * _2102).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2075, s.albedo, metallic.xxx);\n        _4046 = lerp(_2075, 1.0f, metallic);\n        _4045 = true;\n    }\n    float _2130 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2130 > 0.0f)\n    {\n        float _2138 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _4049 = _2130;\n        _4050 = _2138;\n        float _2145 = _2138 * _2138;\n        _4051 = _2145;\n        _4052 = _2145 * _2145;\n        float _2157 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _4054 = _2157;\n        _4047 = 1.0f - (_2130 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2157, 0.0f, 1.0f), 5.0f))));\n        _4045 = true;\n    }\n    float3 _2177 = max(s.sheen_color, 0.0f.xxx);\n    float _2186 = max(_2177.x, max(_2177.y, _2177.z));\n    if (_2186 > 0.0f)\n    {\n        float _2194 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _4055 = true;\n        _4056 = _2177;\n        _4057 = _2194;\n        _4058 = _2194 * _2194;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2194;\n        float _2211 = fa_sheen_albedo(param, param_1);\n        _4060 = _2211;\n        _4059 = 1.0f - min(_2186 * _2211, 1.0f);\n        _4045 = true;\n    }\n    _4048 = _4047 * _4059;\n    float _2230 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2230 != 0.0f)\n    {\n        float3 _2245 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2245;\n        if (dot(_2245, _2245) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2259 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2259.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2259.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2259.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2263 = t;\n        float3 _2264 = normalize(_2263);\n        t = _2264;\n        float3 _2289 = normalize((_2264 * cos(s.anisotropy_rotation)) + ((cross(n, _2264) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _4062 = _2289;\n        _4063 = cross(n, _2289);\n        float _2299 = roughness * roughness;\n        float _2305 = lerp(_2299, 1.0f, _2230 * _2230);\n        bool _2307 = _2230 > 0.0f;\n        _4064 = _2307 ? _2305 : _2299;\n        _4065 = _2307 ? _2299 : _2305;\n        _4061 = _2230;\n        _4045 = true;\n    }\n    FaLayers _4087 = { _4045, _4046, _4047, _4048, _4049, _4050, _4051, _4052, i.world_normal, _4054, _4055, _4056, _4057, _4058, _4059, _4060, _4061, _4062, _4063, _4064, _4065 };\n    return _4087;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_484_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _484_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_484_fa_cl_info.x) + int(_484_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _356 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _362 = fa_light_texel(param_1);\n    float _365 = _362.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _372 = _365 < 0.5f;\n    float3 l;\n    if (_372)\n    {\n        l = normalize(_356.xyz);\n    }\n    else\n    {\n        float3 _384 = _356.xyz - world_pos;\n        float _386 = length(_384);\n        dist = _386;\n        l = _384 / max(_386, 9.9999997473787516355514526367188e-05f).xxx;\n        float _401 = _386 / max(_356.w, 0.001000000047497451305389404296875f);\n        float _407 = clamp(1.0f - (_401 * _401), 0.0f, 1.0f);\n        atten = _407 * _407;\n        if (_365 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _421 = fa_light_texel(param_2);\n            float _431 = _421.w;\n            int param_3 = (li * 4) + 3;\n            float4 _438 = fa_light_texel(param_3);\n            float _439 = _438.x;\n            float cos_inner = _439;\n            if (_439 > 1.5f)\n            {\n                cos_inner = lerp(_431, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_431, cos_inner, dot(-l, normalize(_421.xyz)));\n        }\n    }\n    int _470;\n    if (_372)\n    {\n        _470 = 0;\n    }\n    else\n    {\n        _470 = (_365 > 1.5f) ? 2 : 1;\n    }\n    LightSample _4044 = { l, _362.xyz * atten, atten, 1.0f, dist, _470 };\n    return _4044;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _710;\n    if (i == 0)\n    {\n        _710 = _720_fa_shadow_split.x;\n    }\n    else\n    {\n        float _726;\n        if (i == 1)\n        {\n            _726 = _720_fa_shadow_split.y;\n        }\n        else\n        {\n            float _734;\n            if (i == 2)\n            {\n                _734 = _720_fa_shadow_split.z;\n            }\n            else\n            {\n                _734 = _720_fa_shadow_split.w;\n            }\n            _726 = _734;\n        }\n        _710 = _726;\n    }\n    return _710;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _767 = fa_shadow_depth(param, param_1);\n    float _771;\n    if (conv.x < 0.5f)\n    {\n        _771 = _767;\n    }\n    else\n    {\n        _771 = (conv.y * conv.z) / (conv.z - (_767 * (conv.z - conv.y)));\n    }\n    return _771;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _698 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_698), sin(_698)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _817 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _831 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _817;\n            float2 _850 = fa_shadow_vogel(param_3, param_4, param_5) * _831;\n            float2 param_6 = uv + (_850 * _720_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _862 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_862 < (zr - (length(_850) * plane)))\n            {\n                sum += _862;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _906 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _906; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _906;\n        float param_11 = _817;\n        float2 _925 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_925 * _720_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_925) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_906);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _967 = max(_720_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _972 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _978 = sqrt(1.0f - (_972 * _972));\n    float _986 = min(_978 / max(_972, 0.20000000298023223876953125f), 4.0f);\n    float _991;\n    if (_720_fa_shadow_bias.y > 0.0f)\n    {\n        _991 = _720_fa_shadow_bias.y;\n    }\n    else\n    {\n        _991 = 1.5f * _720_fa_shadow_info[ci].x;\n    }\n    float4 _1016 = mul(float4(world + (n * (_991 * _978)), 1.0f), _720_fa_shadow_mat[ci]);\n    float _1023 = _1016.x;\n    bool _1026 = _1023 < _720_fa_shadow_rect[ci].x;\n    bool _1035;\n    if (!_1026)\n    {\n        _1035 = _1023 > _720_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1035 = _1026;\n    }\n    bool _1044;\n    if (!_1035)\n    {\n        _1044 = _1016.y < _720_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1044 = _1035;\n    }\n    bool _1053;\n    if (!_1044)\n    {\n        _1053 = _1016.y > _720_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1053 = _1044;\n    }\n    bool _1060;\n    if (!_1053)\n    {\n        _1060 = _1016.z > 1.0f;\n    }\n    else\n    {\n        _1060 = _1053;\n    }\n    if (_1060)\n    {\n        return -1.0f;\n    }\n    float _1069;\n    if (_720_fa_shadow_bias.x > 0.0f)\n    {\n        _1069 = _720_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1069 = 1.5f * _720_fa_shadow_info[ci].x;\n    }\n    float2 param = _1016.xy;\n    float4 param_1 = _720_fa_shadow_rect[ci];\n    float param_2 = _1016.z - ((_1069 * (1.0f + (0.5f * _986))) / _967);\n    float param_3 = _720_fa_shadow_info[ci].x;\n    float param_4 = _967;\n    float param_5 = _967 * 0.25f;\n    float param_6 = ((_720_fa_shadow_info[ci].x * min(_986, 3.0f)) * 0.5f) / _967;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_720_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _720_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_484_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1463 = int(_720_fa_shadow_cfg.x + 0.5f);\n    if (_1463 < 1)\n    {\n        return 1.0f;\n    }\n    float _1479 = dot(world - _720_fa_shadow_eye.xyz, _720_fa_shadow_fwd.xyz);\n    int param = _1463 - 1;\n    if (_1479 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1491 = _1463 > 1;\n    bool _1498;\n    if (_1491)\n    {\n        _1498 = _1479 > _720_fa_shadow_split.x;\n    }\n    else\n    {\n        _1498 = _1491;\n    }\n    if (_1498)\n    {\n        ci = 1;\n    }\n    bool _1502 = _1463 > 2;\n    bool _1509;\n    if (_1502)\n    {\n        _1509 = _1479 > _720_fa_shadow_split.y;\n    }\n    else\n    {\n        _1509 = _1502;\n    }\n    if (_1509)\n    {\n        ci = 2;\n    }\n    bool _1513 = _1463 > 3;\n    bool _1520;\n    if (_1513)\n    {\n        _1520 = _1479 > _720_fa_shadow_split.z;\n    }\n    else\n    {\n        _1520 = _1513;\n    }\n    if (_1520)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1463)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1546 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1546;\n        if (_1546 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_720_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1571;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1571 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1571 = _720_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1590 = _720_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1571, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1601 = clamp((_1479 - (fa_shadow_split_at(param_7) - _1590)) / _1590, 0.0f, 1.0f);\n        if (_1601 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1463)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1622 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1622;\n                if (_1622 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1601);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1128 = _484_fa_pbr.z < 0.5f;\n    bool _1136;\n    if (!_1128)\n    {\n        _1136 = _720_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1136 = _1128;\n    }\n    if (_1136)\n    {\n        return 1.0f;\n    }\n    int param = (int(_720_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1149 = fa_light_texel(param);\n    float _1150 = _1149.x;\n    if (_1150 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1159 = int(_1150 + 0.5f);\n    int param_1 = _1159;\n    float4 _1163 = fa_light_texel(param_1);\n    int param_2 = _1159 + 1;\n    float4 _1168 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1171 = _1163.y;\n    if (_1171 > 0.0f)\n    {\n        float _1188 = 1.0f - smoothstep(0.75f * _1171, _1171, length(world - _720_fa_shadow_eye.xyz));\n        fade = _1188;\n        if (_1188 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1163.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1207 = world - fa_light_texel(param_3).xyz;\n        float3 _1210 = abs(_1207);\n        float _1212 = _1210.x;\n        float _1214 = _1210.y;\n        bool _1215 = _1212 >= _1214;\n        bool _1223;\n        if (_1215)\n        {\n            _1223 = _1212 >= _1210.z;\n        }\n        else\n        {\n            _1223 = _1215;\n        }\n        int _1224;\n        if (_1223)\n        {\n            _1224 = (_1207.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1237;\n            if (_1214 >= _1210.z)\n            {\n                _1237 = (_1207.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1237 = (_1207.z > 0.0f) ? 4 : 5;\n            }\n            _1224 = _1237;\n        }\n        face = _1224;\n    }\n    int _1256 = (_1159 + 2) + (face * 6);\n    int param_4 = _1256;\n    int param_5 = _1256 + 1;\n    int param_6 = _1256 + 3;\n    float4 _1270 = fa_light_texel(param_6);\n    int param_7 = _1256 + 4;\n    float4 _1275 = fa_light_texel(param_7);\n    int param_8 = _1256 + 5;\n    float4 _1280 = fa_light_texel(param_8);\n    float _1292 = _1280.x * max(dot(_1270, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1297 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1303 = sqrt(1.0f - (_1297 * _1297));\n    float _1309 = min(_1303 / max(_1297, 0.20000000298023223876953125f), 4.0f);\n    float _1312 = _1168.y;\n    float _1314;\n    if (_1312 > 0.0f)\n    {\n        _1314 = _1312;\n    }\n    else\n    {\n        _1314 = 1.5f * _1292;\n    }\n    float4 _1334 = float4(world + (n * (_1314 * _1303)), 1.0f);\n    float _1338 = dot(_1270, _1334);\n    float _1341 = _1280.y;\n    if (_1338 < _1341)\n    {\n        return 1.0f;\n    }\n    float2 _1356 = float2(dot(fa_light_texel(param_4), _1334), dot(fa_light_texel(param_5), _1334)) / _1338.xx;\n    float _1358 = _1356.x;\n    bool _1361 = _1358 < _1275.x;\n    bool _1370;\n    if (!_1361)\n    {\n        _1370 = _1358 > _1275.z;\n    }\n    else\n    {\n        _1370 = _1361;\n    }\n    bool _1379;\n    if (!_1370)\n    {\n        _1379 = _1356.y < _1275.y;\n    }\n    else\n    {\n        _1379 = _1370;\n    }\n    bool _1388;\n    if (!_1379)\n    {\n        _1388 = _1356.y > _1275.w;\n    }\n    else\n    {\n        _1388 = _1379;\n    }\n    if (_1388)\n    {\n        return 1.0f;\n    }\n    float _1394 = _1168.x;\n    float _1396;\n    if (_1394 > 0.0f)\n    {\n        _1396 = _1394;\n    }\n    else\n    {\n        _1396 = 1.5f * _1292;\n    }\n    float2 param_9 = _1356;\n    float4 param_10 = _1275;\n    float param_11 = _1338 - (_1396 * (1.0f + (0.5f * _1309)));\n    float param_12 = _1292;\n    float param_13 = 1.0f;\n    float param_14 = _1280.z * 0.25f;\n    float param_15 = (_1292 * min(_1309, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _1341, _1280.z);\n    int param_17 = int(_1163.z + 0.5f);\n    float param_18 = _1163.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2842 = fa_light_sample(param, param_1);\n    float3 _4094 = _2842.direction;\n    float3 _4089 = _2842.color;\n    float _4096 = _2842.attenuation;\n    float _4091 = _2842.shadow;\n    int _4099 = _2842.type;\n    if ((_4099 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _4094;\n        float _2856 = fa_shadow_factor(param_2, param_3);\n        _4091 = _2856;\n        _4089 *= _2856;\n    }\n    else\n    {\n        bool _2867 = _4099 != 0;\n        bool _2873;\n        if (_2867)\n        {\n            _2873 = _4096 > 0.0f;\n        }\n        else\n        {\n            _2873 = _2867;\n        }\n        if (_2873)\n        {\n            int param_4 = li;\n            float3 param_5 = world_pos;\n            float3 param_6 = gn;\n            float3 param_7 = _4094;\n            float _2885 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _4091 = _2885;\n            _4089 *= _2885;\n        }\n    }\n    LightSample _4106 = { _4094, _4089, _4096, _4091, _2842._distance, _4099 };\n    return _4106;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2457 = tdh / at;\n    float _2461 = bdh / ab;\n    float _2473 = ((_2457 * _2457) + (_2461 * _2461)) + (ndh * ndh);\n    return 1.0f / ((((3.1415927410125732421875f * at) * ab) * _2473) * _2473);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5f * (sqrt(1.0f + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09f))) - 1.0f);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0f / ((4.0f * max(ndl * ndv, 9.9999997473787516355514526367188e-05f)) * ((1.0f + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0f, 1.0f);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2554 = 1.0f / alpha;\n    return ((2.0f + _2554) * pow(sqrt(max(1.0f - (ndh * ndh), 9.9999997473787516355514526367188e-05f)), _2554)) * 0.15915493667125701904296875f;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25f / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05f), 0.0f, 1.0f);\n}\n\nfloat3 fa_layers_light(FaLayers L, float3 diffuse_color, float3 f0, float3 n, float3 v, float3 l, float3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2587 = step(9.9999997473787516355514526367188e-05f, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0f)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2666 = ((ndh * ndh) * (a2 - 1.0f)) + 1.0f;\n        d_ggx = a2 / ((3.1415927410125732421875f * _2666) * _2666);\n        vis = 0.5f / max(lerp((2.0f * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05f);\n    }\n    float3 base = diffuse_color + (((f0 + ((L.f90.xxx - f0) * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f))) * ((d_ggx * vis) * 3.1415927410125732421875f)) * _2587);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875f) * _2587));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0f)\n    {\n        float _2739 = max(dot(L.nc, l), 0.0f);\n        float _2745 = max(dot(L.nc, h), 0.0f);\n        float _2754 = ((_2745 * _2745) * (L.coat_a2 - 1.0f)) + 1.0f;\n        result += ((((L.coat * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - vdh, 0.0f, 1.0f), 5.0f)))) * (((L.coat_a2 / ((3.1415927410125732421875f * _2754) * _2754)) * (0.5f / max(lerp((2.0f * _2739) * L.coat_ndv, _2739 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _2739)) * _2739).xxx;\n    }\n    return result;\n}\n\nfloat3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1854 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1857 = _1854.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1857 * _1857, exp2((-9.27999973297119140625f) * ndv)) * _1857) + _1854.y)) + _1854.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_484_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _484_fa_env_horizon.w).xyz;\n    }\n    float _1759 = rough * rough;\n    float _1789 = 0.60000002384185791015625f * _1759;\n    return lerp(lerp(_484_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_484_fa_env_horizon.xyz, _484_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1759)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1789, 0.0500000007450580596923828125f + _1789, d.y).xxx), ((_484_fa_env_sky.xyz + _484_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1759 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2340;\n        if (L.aniso >= 0.0f)\n        {\n            _2340 = L.b;\n        }\n        else\n        {\n            _2340 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2340, v), _2340), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2373 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2373.x) + (L.f90.xxx * _2373.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2428 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2428.x) + _2428.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1896 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1896.x) + _1896.y.xxx);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_720_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1646 = int(_720_fa_shadow_cfg.x + 0.5f);\n    float _1656 = dot(world - _720_fa_shadow_eye.xyz, _720_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1661 = _1646 > 0;\n    bool _1670;\n    if (_1661)\n    {\n        int param = _1646 - 1;\n        _1670 = _1656 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1670 = _1661;\n    }\n    if (_1670)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1677 = _1646 > 1;\n        bool _1684;\n        if (_1677)\n        {\n            _1684 = _1656 > _720_fa_shadow_split.x;\n        }\n        else\n        {\n            _1684 = _1677;\n        }\n        if (_1684)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1690 = _1646 > 2;\n        bool _1697;\n        if (_1690)\n        {\n            _1697 = _1656 > _720_fa_shadow_split.y;\n        }\n        else\n        {\n            _1697 = _1690;\n        }\n        if (_1697)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1703 = _1646 > 3;\n        bool _1710;\n        if (_1703)\n        {\n            _1710 = _1656 > _720_fa_shadow_split.z;\n        }\n        else\n        {\n            _1710 = _1703;\n        }\n        if (_1710)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3824 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3824 = -_3824;\n    }\n    float3 _3267 = normalize(_484_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3837 = { fa_world_pos, _3824, fa_world_tangent, fa_uv, fa_vertex_color, _3267, gl_FrontFacing };\n    SurfaceInput param_1 = _3837;\n    Surface _3275 = fa_standard_surface(param_1);\n    float3 _3855 = _3275.albedo;\n    float _3856 = _3275.alpha;\n    float3 _3857 = _3275.normal;\n    float _3858 = _3275.metallic;\n    float _3859 = _3275.roughness;\n    float _3860 = _3275.occlusion;\n    float3 _3861 = _3275.emission;\n    float _3862 = _3275.clearcoat;\n    float _3863 = _3275.clearcoat_roughness;\n    float3 _3864 = _3275.sheen_color;\n    float _3865 = _3275.sheen_roughness;\n    float _3866 = _3275.anisotropy;\n    float _3867 = _3275.anisotropy_rotation;\n    float _3868 = _3275.specular;\n    float _3869 = _3275.ior;\n    float3 _3870 = _3275.specular_color;\n    SurfaceInput _3845 = { fa_world_pos, _3824, fa_world_tangent, fa_uv, fa_vertex_color, _3267, gl_FrontFacing };\n    SurfaceInput param_2 = _3845;\n    Surface param_3 = _3275;\n    surface(param_2, param_3);\n    _3855 = param_3.albedo;\n    _3856 = param_3.alpha;\n    _3857 = param_3.normal;\n    _3858 = param_3.metallic;\n    _3859 = param_3.roughness;\n    _3860 = param_3.occlusion;\n    _3861 = param_3.emission;\n    _3862 = param_3.clearcoat;\n    _3863 = param_3.clearcoat_roughness;\n    _3864 = param_3.sheen_color;\n    _3865 = param_3.sheen_roughness;\n    _3866 = param_3.anisotropy;\n    _3867 = param_3.anisotropy_rotation;\n    _3868 = param_3.specular;\n    _3869 = param_3.ior;\n    _3870 = param_3.specular_color;\n    if (param_3.alpha < _3286_alphaCutoff)\n    {\n        discard;\n    }\n    float3 result;\n    if (_484_fa_emissive.w > 0.5f)\n    {\n        result = _3855;\n    }\n    else\n    {\n        float3 _3308 = normalize(_3857);\n        float _3315 = clamp(_3858, 0.0f, 1.0f);\n        float _3319 = clamp(_3859, 0.0500000007450580596923828125f, 1.0f);\n        float _3323 = _3319 * _3319;\n        float _3327 = _3323 * _3323;\n        float _3332 = max(dot(_3308, _3267), 9.9999997473787516355514526367188e-05f);\n        float3 _3338 = _3855 * (1.0f - _3315);\n        float3 _3345 = lerp(0.039999999105930328369140625f.xxx, _3855, _3315.xxx);\n        float3 f0 = _3345;\n        SurfaceInput _3853 = { fa_world_pos, _3824, fa_world_tangent, fa_uv, fa_vertex_color, _3267, gl_FrontFacing };\n        SurfaceInput param_4 = _3853;\n        Surface _3936 = { _3855, _3856, _3857, _3858, _3859, _3860, _3861, _3862, _3863, _3864, _3865, _3866, _3867, _3868, _3869, _3870 };\n        Surface param_5 = _3936;\n        float3 param_6 = _3308;\n        float3 param_7 = _3267;\n        float param_8 = _3315;\n        float param_9 = _3319;\n        float3 param_10 = _3345;\n        FaLayers _3361 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _3308;\n        float3 lit = (fa_ambient_light(param_11) * _3338) * _3860;\n        if (_3361.on)\n        {\n            lit *= _3361.base_scale;\n        }\n        int _3383 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3383; ln++)\n        {\n            int param_12 = ln;\n            int _3396 = fa_cl_light(param_12);\n            int param_13 = _3396;\n            float3 param_14 = fa_world_pos;\n            float3 param_15 = _3824;\n            LightSample _3405 = fa_light_shadowed(param_13, param_14, param_15);\n            float3 _4029 = _3405.direction;\n            float _3413 = max(dot(_3308, _4029), 0.0f);\n            float _3419 = _3405.attenuation * _3405.shadow;\n            float3 _3424 = normalize(_4029 + _3267);\n            float _3429 = max(dot(_3308, _3424), 0.0f);\n            float _3434 = max(dot(_3267, _3424), 0.0f);\n            if (_3361.on)\n            {\n                FaLayers param_16 = _3361;\n                float3 param_17 = _3338;\n                float3 param_18 = f0;\n                float3 param_19 = _3308;\n                float3 param_20 = _3267;\n                float3 param_21 = _4029;\n                float3 param_22 = _3424;\n                float param_23 = _3413;\n                float param_24 = _3332;\n                float param_25 = _3429;\n                float param_26 = _3434;\n                float param_27 = _3323;\n                float param_28 = _3327;\n                int param_29 = _3396;\n                lit += (fa_layers_light(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28) * (fa_light_rgb(param_29) * _3419));\n            }\n            else\n            {\n                float _3482 = ((_3429 * _3429) * (_3327 - 1.0f)) + 1.0f;\n                int param_30 = _3396;\n                lit += (((_3338 + (((f0 + ((1.0f.xxx - f0) * pow(1.0f - _3434, 5.0f))) * (((_3327 / ((3.1415927410125732421875f * _3482) * _3482)) * (0.5f / max(lerp((2.0f * _3413) * _3332, _3413 + _3332, _3323), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _3413))) * fa_light_rgb(param_30)) * (_3413 * _3419));\n            }\n        }\n        if (_3361.on)\n        {\n            FaLayers param_31 = _3361;\n            float3 param_32 = _3308;\n            float3 param_33 = _3267;\n            float3 param_34 = f0;\n            float param_35 = _3319;\n            lit += (fa_layers_ibl(param_31, param_32, param_33, param_34, param_35) * _3860);\n        }\n        else\n        {\n            float3 param_36 = _3308;\n            float3 param_37 = _3267;\n            float3 param_38 = f0;\n            float param_39 = _3319;\n            lit += (fa_sky_reflection(param_36, param_37, param_38, param_39) * _3860);\n        }\n        result = lit;\n    }\n    float3 _3575 = result;\n    float3 _3576 = _3575 + _3861;\n    result = _3576;\n    float3 param_40 = _3576;\n    float3 param_41 = fa_world_pos;\n    result = fa_shadow_debug(param_40, param_41);\n    bool _3585 = _484_fa_fog.w > 0.0f;\n    bool _3592;\n    if (!_3585)\n    {\n        _3592 = _484_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3592 = _3585;\n    }\n    if (_3592)\n    {\n        float3 _3601 = fa_world_pos - _484_fa_camera_pos.xyz;\n        float _3607 = dot(_3601, _484_fa_fog_c.xyz);\n        bool _3611 = _484_fa_fog_c.w > 0.5f;\n        float _3612;\n        if (_3611)\n        {\n            _3612 = _3607;\n        }\n        else\n        {\n            _3612 = length(_3601);\n        }\n        float _3624 = _3612 - _484_fa_fog_b.x;\n        if (_3624 > 0.0f)\n        {\n            float _3633 = _484_fa_fog.w * _3624;\n            float tau = _3633 * _3633;\n            if (_484_fa_fog_b.y > 0.0f)\n            {\n                float _3649;\n                if (_3611)\n                {\n                    _3649 = fa_world_pos.y - (_484_fa_fog_c.y * _3607);\n                }\n                else\n                {\n                    _3649 = _484_fa_camera_pos.y;\n                }\n                float _3670 = lerp(_3649, fa_world_pos.y, clamp(_484_fa_fog_b.x / _3612, 0.0f, 1.0f));\n                float _3674 = fa_world_pos.y - _3670;\n                float _3679 = _3670 - _484_fa_fog_b.z;\n                float _3684 = fa_world_pos.y - _484_fa_fog_b.z;\n                bool _3687 = _3679 <= 0.0f;\n                bool _3688 = !_3687;\n                bool _3694;\n                if (_3688)\n                {\n                    _3694 = _484_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3694 = _3687;\n                }\n                float _3695;\n                if (_3694)\n                {\n                    _3695 = _484_fa_fog_b.y;\n                }\n                else\n                {\n                    _3695 = _484_fa_fog_b.y * exp(-min(_484_fa_fog_b.w * _3679, 80.0f));\n                }\n                bool _3722;\n                if (_3688)\n                {\n                    _3722 = _484_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3722 = _3687;\n                }\n                float _3723;\n                if (_3722)\n                {\n                    _3723 = _484_fa_fog_b.y * _3679;\n                }\n                else\n                {\n                    _3723 = (_484_fa_fog_b.y * (1.0f - exp(-min(_484_fa_fog_b.w * _3679, 80.0f)))) / _484_fa_fog_b.w;\n                }\n                bool _3748 = _3684 <= 0.0f;\n                bool _3755;\n                if (!_3748)\n                {\n                    _3755 = _484_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3755 = _3748;\n                }\n                float _3756;\n                if (_3755)\n                {\n                    _3756 = _484_fa_fog_b.y * _3684;\n                }\n                else\n                {\n                    _3756 = (_484_fa_fog_b.y * (1.0f - exp(-min(_484_fa_fog_b.w * _3684, 80.0f)))) / _484_fa_fog_b.w;\n                }\n                float _3783;\n                if (abs(_3674) < 0.001000000047497451305389404296875f)\n                {\n                    _3783 = _3695;\n                }\n                else\n                {\n                    _3783 = (_3756 - _3723) / _3674;\n                }\n                tau += (_3624 * max(_3783, 0.0f));\n            }\n            result = lerp(result, _484_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3856);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_484",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_720",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3286",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 8
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _301 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _301;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _308 = _160.world_pos;\n    float4 _171 = float4(_308, 1.0f);\n    fa_world_pos = _308;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _225_fa_camera_pos : packoffset(c0);\n    float4 _225_fa_ambient : packoffset(c1);\n    float4 _225_fa_base_color : packoffset(c2);\n    float4 _225_fa_emissive : packoffset(c3);\n    float4 _225_fa_model_emissive : packoffset(c4);\n    float4 _225_fa_pbr : packoffset(c5);\n    float4 _225_fa_maps : packoffset(c6);\n    float4 _225_fa_fog : packoffset(c7);\n    float4 _225_fa_fog_b : packoffset(c8);\n    float4 _225_fa_fog_c : packoffset(c9);\n    float4 _225_fa_counts : packoffset(c10);\n    float4 _225_fa_env_sky : packoffset(c11);\n    float4 _225_fa_env_horizon : packoffset(c12);\n    float4 _225_fa_time : packoffset(c13);\n    float4 _225_fa_cl_vpx : packoffset(c14);\n    float4 _225_fa_cl_vpy : packoffset(c15);\n    float4 _225_fa_cl_vpw : packoffset(c16);\n    float4 _225_fa_cl_fwd : packoffset(c17);\n    float4 _225_fa_cl_grid : packoffset(c18);\n    float4 _225_fa_cl_info : packoffset(c19);\n    float4 _225_fa_layers_a : packoffset(c20);\n    float4 _225_fa_layers_b : packoffset(c21);\n    float4 _225_fa_layers_c : packoffset(c22);\n    float4 _225_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _546_alphaCutoff : packoffset(c0);\n    float _546_fa_pad0 : packoffset(c0.y);\n    float _546_fa_pad1 : packoffset(c0.z);\n    float _546_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _225_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _755 = base_t;\n    _755.x = _237.x;\n    _755.y = _237.y;\n    _755.z = _237.z;\n    base_t = _755;\n    float4 _253 = (_755 * _225_fa_base_color) * i.vertex_color;\n    float3 _718 = i.world_normal;\n    if (_225_fa_maps.z > 0.5f)\n    {\n        float param_4 = _225_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _225_fa_maps.x;\n        float3 _763 = _290;\n        _763.x = _295.x;\n        _763.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _763;\n        _718 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _225_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _766 = mrt;\n    _766.x = _324.x;\n    _766.y = _324.y;\n    _766.z = _324.z;\n    mrt = _766;\n    float4 _354 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _225_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _723 = _225_fa_layers_a.x;\n    float _724 = _225_fa_layers_a.y;\n    float _727 = _225_fa_layers_a.z;\n    float _726 = _225_fa_layers_b.w;\n    float _729 = _225_fa_layers_c.x;\n    if (_225_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_225_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _723 *= _366.y;\n            _724 *= _366.z;\n            _726 *= _354.w;\n        }\n        if (_225_fa_layers_c.z > 1.5f)\n        {\n            _727 *= mrt.x;\n            _729 *= mrt.w;\n        }\n    }\n    Surface _748 = { _253.xyz, _253.w, _718, clamp(_225_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_225_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_225_fa_maps.y * (_366.x - 1.0f)), _225_fa_emissive.xyz + (_225_fa_model_emissive.xyz * _396), _723, _724, _225_fa_layers_b.xyz, _726, _727, _225_fa_layers_a.w, _729, _225_fa_layers_c.y, _225_fa_layers_d.xyz };\n    return _748;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _629 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _629 = -_629;\n    }\n    float3 _530 = normalize(_225_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _642 = { fa_world_pos, _629, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param = _642;\n    Surface _535 = fa_standard_surface(param);\n    float3 _653 = _535.normal;\n    SurfaceInput _650 = { fa_world_pos, _629, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param_1 = _650;\n    Surface param_2 = _535;\n    surface(param_1, param_2);\n    _653 = param_2.normal;\n    if (param_2.alpha < _546_alphaCutoff)\n    {\n        discard;\n    }\n    float3 _556 = normalize(_653);\n    float3 _571 = normalize(float3(dot(fa_pre_r0, _556), dot(fa_pre_r1, _556), dot(fa_pre_r2, _556)));\n    float _583 = _571.z;\n    float2 e = _571.xy / ((abs(_571.x) + abs(_571.y)) + abs(_583)).xx;\n    if (_583 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_225",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_546",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _422 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _422;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _429 = _273.world_pos;\n    float4 _284 = float4(_429, 1.0f);\n    fa_world_pos = _429;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _225_fa_camera_pos : packoffset(c0);\n    float4 _225_fa_ambient : packoffset(c1);\n    float4 _225_fa_base_color : packoffset(c2);\n    float4 _225_fa_emissive : packoffset(c3);\n    float4 _225_fa_model_emissive : packoffset(c4);\n    float4 _225_fa_pbr : packoffset(c5);\n    float4 _225_fa_maps : packoffset(c6);\n    float4 _225_fa_fog : packoffset(c7);\n    float4 _225_fa_fog_b : packoffset(c8);\n    float4 _225_fa_fog_c : packoffset(c9);\n    float4 _225_fa_counts : packoffset(c10);\n    float4 _225_fa_env_sky : packoffset(c11);\n    float4 _225_fa_env_horizon : packoffset(c12);\n    float4 _225_fa_time : packoffset(c13);\n    float4 _225_fa_cl_vpx : packoffset(c14);\n    float4 _225_fa_cl_vpy : packoffset(c15);\n    float4 _225_fa_cl_vpw : packoffset(c16);\n    float4 _225_fa_cl_fwd : packoffset(c17);\n    float4 _225_fa_cl_grid : packoffset(c18);\n    float4 _225_fa_cl_info : packoffset(c19);\n    float4 _225_fa_layers_a : packoffset(c20);\n    float4 _225_fa_layers_b : packoffset(c21);\n    float4 _225_fa_layers_c : packoffset(c22);\n    float4 _225_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _546_alphaCutoff : packoffset(c0);\n    float _546_fa_pad0 : packoffset(c0.y);\n    float _546_fa_pad1 : packoffset(c0.z);\n    float _546_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _225_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _755 = base_t;\n    _755.x = _237.x;\n    _755.y = _237.y;\n    _755.z = _237.z;\n    base_t = _755;\n    float4 _253 = (_755 * _225_fa_base_color) * i.vertex_color;\n    float3 _718 = i.world_normal;\n    if (_225_fa_maps.z > 0.5f)\n    {\n        float param_4 = _225_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _225_fa_maps.x;\n        float3 _763 = _290;\n        _763.x = _295.x;\n        _763.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _763;\n        _718 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _225_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _766 = mrt;\n    _766.x = _324.x;\n    _766.y = _324.y;\n    _766.z = _324.z;\n    mrt = _766;\n    float4 _354 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _225_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _723 = _225_fa_layers_a.x;\n    float _724 = _225_fa_layers_a.y;\n    float _727 = _225_fa_layers_a.z;\n    float _726 = _225_fa_layers_b.w;\n    float _729 = _225_fa_layers_c.x;\n    if (_225_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_225_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _723 *= _366.y;\n            _724 *= _366.z;\n            _726 *= _354.w;\n        }\n        if (_225_fa_layers_c.z > 1.5f)\n        {\n            _727 *= mrt.x;\n            _729 *= mrt.w;\n        }\n    }\n    Surface _748 = { _253.xyz, _253.w, _718, clamp(_225_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_225_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_225_fa_maps.y * (_366.x - 1.0f)), _225_fa_emissive.xyz + (_225_fa_model_emissive.xyz * _396), _723, _724, _225_fa_layers_b.xyz, _726, _727, _225_fa_layers_a.w, _729, _225_fa_layers_c.y, _225_fa_layers_d.xyz };\n    return _748;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _629 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _629 = -_629;\n    }\n    float3 _530 = normalize(_225_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _642 = { fa_world_pos, _629, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param = _642;\n    Surface _535 = fa_standard_surface(param);\n    float3 _653 = _535.normal;\n    SurfaceInput _650 = { fa_world_pos, _629, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param_1 = _650;\n    Surface param_2 = _535;\n    surface(param_1, param_2);\n    _653 = param_2.normal;\n    if (param_2.alpha < _546_alphaCutoff)\n    {\n        discard;\n    }\n    float3 _556 = normalize(_653);\n    float3 _571 = normalize(float3(dot(fa_pre_r0, _556), dot(fa_pre_r1, _556), dot(fa_pre_r2, _556)));\n    float _583 = _571.z;\n    float2 e = _571.xy / ((abs(_571.x) + abs(_571.y)) + abs(_583)).xx;\n    if (_583 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_225",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_546",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _122_fa_view_proj : packoffset(c0);\n    row_major float4x4 _122_fa_light_vp : packoffset(c4);\n    float4 _122_fa_uv_scale : packoffset(c8);\n    float4 _122_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _256 = { mul(float4(position, 1.0f), model).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * _122_fa_uv_scale.xy, color, position };\n    return _256;\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _239 = _190.world_pos;\n    fa_world_pos = _239;\n    fa_world_normal = _190.world_normal;\n    fa_world_tangent = _190.world_tangent;\n    fa_uv = _190.uv;\n    fa_vertex_color = _190.color;\n    gl_Position = mul(float4(_239, 1.0f), _122_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _225_fa_camera_pos : packoffset(c0);\n    float4 _225_fa_ambient : packoffset(c1);\n    float4 _225_fa_base_color : packoffset(c2);\n    float4 _225_fa_emissive : packoffset(c3);\n    float4 _225_fa_model_emissive : packoffset(c4);\n    float4 _225_fa_pbr : packoffset(c5);\n    float4 _225_fa_maps : packoffset(c6);\n    float4 _225_fa_fog : packoffset(c7);\n    float4 _225_fa_fog_b : packoffset(c8);\n    float4 _225_fa_fog_c : packoffset(c9);\n    float4 _225_fa_counts : packoffset(c10);\n    float4 _225_fa_env_sky : packoffset(c11);\n    float4 _225_fa_env_horizon : packoffset(c12);\n    float4 _225_fa_time : packoffset(c13);\n    float4 _225_fa_cl_vpx : packoffset(c14);\n    float4 _225_fa_cl_vpy : packoffset(c15);\n    float4 _225_fa_cl_vpw : packoffset(c16);\n    float4 _225_fa_cl_fwd : packoffset(c17);\n    float4 _225_fa_cl_grid : packoffset(c18);\n    float4 _225_fa_cl_info : packoffset(c19);\n    float4 _225_fa_layers_a : packoffset(c20);\n    float4 _225_fa_layers_b : packoffset(c21);\n    float4 _225_fa_layers_c : packoffset(c22);\n    float4 _225_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _546_alphaCutoff : packoffset(c0);\n    float _546_fa_pad0 : packoffset(c0.y);\n    float _546_fa_pad1 : packoffset(c0.z);\n    float _546_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _225_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _689 = base_t;\n    _689.x = _237.x;\n    _689.y = _237.y;\n    _689.z = _237.z;\n    base_t = _689;\n    float4 _253 = (_689 * _225_fa_base_color) * i.vertex_color;\n    float3 _658 = i.world_normal;\n    if (_225_fa_maps.z > 0.5f)\n    {\n        float param_4 = _225_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _225_fa_maps.x;\n        float3 _697 = _290;\n        _697.x = _295.x;\n        _697.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _697;\n        _658 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _225_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _700 = mrt;\n    _700.x = _324.x;\n    _700.y = _324.y;\n    _700.z = _324.z;\n    mrt = _700;\n    float4 _354 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _225_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _663 = _225_fa_layers_a.x;\n    float _664 = _225_fa_layers_a.y;\n    float _667 = _225_fa_layers_a.z;\n    float _666 = _225_fa_layers_b.w;\n    float _669 = _225_fa_layers_c.x;\n    if (_225_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_225_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _663 *= _366.y;\n            _664 *= _366.z;\n            _666 *= _354.w;\n        }\n        if (_225_fa_layers_c.z > 1.5f)\n        {\n            _667 *= mrt.x;\n            _669 *= mrt.w;\n        }\n    }\n    Surface _688 = { _253.xyz, _253.w, _658, clamp(_225_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_225_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_225_fa_maps.y * (_366.x - 1.0f)), _225_fa_emissive.xyz + (_225_fa_model_emissive.xyz * _396), _663, _664, _225_fa_layers_b.xyz, _666, _667, _225_fa_layers_a.w, _669, _225_fa_layers_c.y, _225_fa_layers_d.xyz };\n    return _688;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _569 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _569 = -_569;\n    }\n    float3 _530 = normalize(_225_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _582 = { fa_world_pos, _569, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param = _582;\n    SurfaceInput _590 = { fa_world_pos, _569, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param_1 = _590;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _546_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_225",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_546",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _127_fa_view_proj : packoffset(c0);\n    row_major float4x4 _127_fa_light_vp : packoffset(c4);\n    float4 _127_fa_uv_scale : packoffset(c8);\n    float4 _127_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _174_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _165 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_174_fa_joint_rows[_165] * weights[i]);\n        r1 += (_174_fa_joint_rows[_165 + 1] * weights[i]);\n        r2 += (_174_fa_joint_rows[_165 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _377 = { mul(float4(position, 1.0f), model).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * _127_fa_uv_scale.xy, color, position };\n    return _377;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData _311 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    float3 _360 = _311.world_pos;\n    fa_world_pos = _360;\n    fa_world_normal = _311.world_normal;\n    fa_world_tangent = _311.world_tangent;\n    fa_uv = _311.uv;\n    fa_vertex_color = _311.color;\n    gl_Position = mul(float4(_360, 1.0f), _127_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _225_fa_camera_pos : packoffset(c0);\n    float4 _225_fa_ambient : packoffset(c1);\n    float4 _225_fa_base_color : packoffset(c2);\n    float4 _225_fa_emissive : packoffset(c3);\n    float4 _225_fa_model_emissive : packoffset(c4);\n    float4 _225_fa_pbr : packoffset(c5);\n    float4 _225_fa_maps : packoffset(c6);\n    float4 _225_fa_fog : packoffset(c7);\n    float4 _225_fa_fog_b : packoffset(c8);\n    float4 _225_fa_fog_c : packoffset(c9);\n    float4 _225_fa_counts : packoffset(c10);\n    float4 _225_fa_env_sky : packoffset(c11);\n    float4 _225_fa_env_horizon : packoffset(c12);\n    float4 _225_fa_time : packoffset(c13);\n    float4 _225_fa_cl_vpx : packoffset(c14);\n    float4 _225_fa_cl_vpy : packoffset(c15);\n    float4 _225_fa_cl_vpw : packoffset(c16);\n    float4 _225_fa_cl_fwd : packoffset(c17);\n    float4 _225_fa_cl_grid : packoffset(c18);\n    float4 _225_fa_cl_info : packoffset(c19);\n    float4 _225_fa_layers_a : packoffset(c20);\n    float4 _225_fa_layers_b : packoffset(c21);\n    float4 _225_fa_layers_c : packoffset(c22);\n    float4 _225_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _546_alphaCutoff : packoffset(c0);\n    float _546_fa_pad0 : packoffset(c0.y);\n    float _546_fa_pad1 : packoffset(c0.z);\n    float _546_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> mask : register(t5);\nSamplerState mask_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _225_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _689 = base_t;\n    _689.x = _237.x;\n    _689.y = _237.y;\n    _689.z = _237.z;\n    base_t = _689;\n    float4 _253 = (_689 * _225_fa_base_color) * i.vertex_color;\n    float3 _658 = i.world_normal;\n    if (_225_fa_maps.z > 0.5f)\n    {\n        float param_4 = _225_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0f) - 1.0f.xxx;\n        float2 _295 = _290.xy * _225_fa_maps.x;\n        float3 _697 = _290;\n        _697.x = _295.x;\n        _697.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _697;\n        _658 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _225_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _700 = mrt;\n    _700.x = _324.x;\n    _700.y = _324.y;\n    _700.z = _324.z;\n    mrt = _700;\n    float4 _354 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _225_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _663 = _225_fa_layers_a.x;\n    float _664 = _225_fa_layers_a.y;\n    float _667 = _225_fa_layers_a.z;\n    float _666 = _225_fa_layers_b.w;\n    float _669 = _225_fa_layers_c.x;\n    if (_225_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_225_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _663 *= _366.y;\n            _664 *= _366.z;\n            _666 *= _354.w;\n        }\n        if (_225_fa_layers_c.z > 1.5f)\n        {\n            _667 *= mrt.x;\n            _669 *= mrt.w;\n        }\n    }\n    Surface _688 = { _253.xyz, _253.w, _658, clamp(_225_fa_pbr.x * _324.z, 0.0f, 1.0f), clamp(_225_fa_pbr.y * _324.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_225_fa_maps.y * (_366.x - 1.0f)), _225_fa_emissive.xyz + (_225_fa_model_emissive.xyz * _396), _663, _664, _225_fa_layers_b.xyz, _666, _667, _225_fa_layers_a.w, _669, _225_fa_layers_c.y, _225_fa_layers_d.xyz };\n    return _688;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = mask.Sample(mask_smp, i.uv * 2.0f).x;\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _569 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _569 = -_569;\n    }\n    float3 _530 = normalize(_225_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _582 = { fa_world_pos, _569, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param = _582;\n    SurfaceInput _590 = { fa_world_pos, _569, fa_world_tangent, fa_uv, fa_vertex_color, _530, gl_FrontFacing };\n    SurfaceInput param_1 = _590;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < _546_alphaCutoff)\n    {\n        discard;\n    }\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_225",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_546",
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
