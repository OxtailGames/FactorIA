{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "df130aaeb5c0790af276010723d2798f8fdace693dbde21948e5a037edff24ef",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _2013[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _466_fa_camera_pos : packoffset(c0);\n    float4 _466_fa_ambient : packoffset(c1);\n    float4 _466_fa_base_color : packoffset(c2);\n    float4 _466_fa_emissive : packoffset(c3);\n    float4 _466_fa_model_emissive : packoffset(c4);\n    float4 _466_fa_pbr : packoffset(c5);\n    float4 _466_fa_maps : packoffset(c6);\n    float4 _466_fa_fog : packoffset(c7);\n    float4 _466_fa_fog_b : packoffset(c8);\n    float4 _466_fa_fog_c : packoffset(c9);\n    float4 _466_fa_counts : packoffset(c10);\n    float4 _466_fa_env_sky : packoffset(c11);\n    float4 _466_fa_env_horizon : packoffset(c12);\n    float4 _466_fa_time : packoffset(c13);\n    float4 _466_fa_cl_vpx : packoffset(c14);\n    float4 _466_fa_cl_vpy : packoffset(c15);\n    float4 _466_fa_cl_vpw : packoffset(c16);\n    float4 _466_fa_cl_fwd : packoffset(c17);\n    float4 _466_fa_cl_grid : packoffset(c18);\n    float4 _466_fa_cl_info : packoffset(c19);\n    float4 _466_fa_layers_a : packoffset(c20);\n    float4 _466_fa_layers_b : packoffset(c21);\n    float4 _466_fa_layers_c : packoffset(c22);\n    float4 _466_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _702_fa_shadow_mat[4] : packoffset(c0);\n    float4 _702_fa_shadow_rect[4] : packoffset(c16);\n    float4 _702_fa_shadow_info[4] : packoffset(c20);\n    float4 _702_fa_shadow_split : packoffset(c24);\n    float4 _702_fa_shadow_cfg : packoffset(c25);\n    float4 _702_fa_shadow_bias : packoffset(c26);\n    float4 _702_fa_shadow_eye : packoffset(c27);\n    float4 _702_fa_shadow_fwd : packoffset(c28);\n    float4 _702_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _471 = _466_fa_cl_info.x < 0.0f;\n    bool _478;\n    if (!_471)\n    {\n        _478 = _466_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _478 = _471;\n    }\n    bool _486;\n    if (!_478)\n    {\n        _486 = _466_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _486 = _478;\n    }\n    bool _493;\n    if (!_486)\n    {\n        _493 = _466_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _493 = _486;\n    }\n    bool _500;\n    if (!_493)\n    {\n        _500 = _466_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _500 = _493;\n    }\n    if (_500)\n    {\n        return int2(0, 0);\n    }\n    float4 _510 = float4(world_pos, 1.0f);\n    float _517 = dot(_466_fa_cl_vpw, _510);\n    if (!(_517 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _539 = float2(dot(_466_fa_cl_vpx, _510), dot(_466_fa_cl_vpy, _510)) / _517.xx;\n    int _543 = int(_466_fa_cl_grid.x);\n    int _547 = int(_466_fa_cl_grid.y);\n    int param = (int(_466_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_466_fa_cl_fwd.xyz, world_pos) + _466_fa_cl_fwd.w, _466_fa_cl_grid.w) / _466_fa_cl_grid.w) * _466_fa_cl_grid.z)), 0, int(_466_fa_cl_info.y) - 1) * _547) + clamp(int(floor(((_539.y * 0.5f) + 0.5f) * _466_fa_cl_grid.y)), 0, _547 - 1)) * _543)) + clamp(int(floor(((_539.x * 0.5f) + 0.5f) * _466_fa_cl_grid.x)), 0, _543 - 1);\n    float4 _618 = fa_light_texel(param);\n    return int2(int(_618.x), int(_618.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_466_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2551 = fa_cluster_lookup(param);\n    fa_cl_slot = _2551.x;\n    fa_cl_local = _2551.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2716 = fa_linear_to_srgb(param);\n        c = _2716;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2724 = fa_srgb_to_linear(param_1);\n            c = _2724;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _230;\n    if (i.front_facing)\n    {\n        _230 = i.world_normal;\n    }\n    else\n    {\n        _230 = -i.world_normal;\n    }\n    float3 _254 = normalize(i.world_tangent.xyz - (_230 * dot(_230, i.world_tangent.xyz)));\n    float3 _282 = normalize(((_254 * m.x) + ((cross(_230, _254) * i.world_tangent.w) * m.y)) + (_230 * m.z));\n    float3 _285;\n    if (i.front_facing)\n    {\n        _285 = _282;\n    }\n    else\n    {\n        _285 = -_282;\n    }\n    return _285;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _466_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2755 = fa_tex_fix(param_2, param_3);\n    float4 _3806 = base_t;\n    _3806.x = _2755.x;\n    _3806.y = _2755.y;\n    _3806.z = _2755.z;\n    base_t = _3806;\n    float4 _2769 = (_3806 * _466_fa_base_color) * i.vertex_color;\n    float3 _3708 = i.world_normal;\n    if (_466_fa_maps.z > 0.5f)\n    {\n        float param_4 = _466_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2801 = fa_tex_fix(param_6, param_7);\n        float3 _2805 = (_2801 * 2.0f) - 1.0f.xxx;\n        float2 _2810 = _2805.xy * _466_fa_maps.x;\n        float3 _3814 = _2805;\n        _3814.x = _2810.x;\n        _3814.y = _2810.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3814;\n        _3708 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _466_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2839 = fa_tex_fix(param_12, param_13);\n    float4 _3817 = mrt;\n    _3817.x = _2839.x;\n    _3817.y = _2839.y;\n    _3817.z = _2839.z;\n    mrt = _3817;\n    float4 _2867 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _466_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2867.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2879 = fa_tex_fix(param_16, param_17);\n    float param_18 = _466_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2909 = fa_tex_fix(param_20, param_21);\n    float _3713 = _466_fa_layers_a.x;\n    float _3714 = _466_fa_layers_a.y;\n    float _3717 = _466_fa_layers_a.z;\n    float _3716 = _466_fa_layers_b.w;\n    float _3719 = _466_fa_layers_c.x;\n    if (_466_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_466_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3713 *= _2879.y;\n            _3714 *= _2879.z;\n            _3716 *= _2867.w;\n        }\n        if (_466_fa_layers_c.z > 1.5f)\n        {\n            _3717 *= mrt.x;\n            _3719 *= mrt.w;\n        }\n    }\n    Surface _3738 = { _2769.xyz, _2769.w, _3708, clamp(_466_fa_pbr.x * _2839.z, 0.0f, 1.0f), clamp(_466_fa_pbr.y * _2839.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_466_fa_maps.y * (_2879.x - 1.0f)), _466_fa_emissive.xyz + (_466_fa_model_emissive.xyz * _2909), _3713, _3714, _466_fa_layers_b.xyz, _3716, _3717, _466_fa_layers_a.w, _3719, _466_fa_layers_c.y, _466_fa_layers_d.xyz };\n    return _3738;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_466_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _466_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1938 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1946 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1949 = int(_1938);\n    int _1952 = int(_1946);\n    float _1962 = _1946 - float(_1952);\n    int _2018 = (_1949 * 9) + _1952;\n    int _2038 = ((_1949 + 1) * 9) + _1952;\n    return lerp(lerp(_2013[_2018], _2013[_2018 + 1], _1962), lerp(_2013[_2038], _2013[_2038 + 1], _1962), _1938 - float(_1949));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3567 = false;\n    float _3568 = 1.0f;\n    float _3569 = 1.0f;\n    float _3570 = 1.0f;\n    float _3571 = 0.0f;\n    float _3572 = 0.0f;\n    float _3573 = 0.0f;\n    float _3574 = 0.0f;\n    float _3576 = 1.0f;\n    bool _3577 = false;\n    float3 _3578 = 0.0f.xxx;\n    float _3579 = 1.0f;\n    float _3580 = 1.0f;\n    float _3581 = 1.0f;\n    float _3582 = 0.0f;\n    float _3583 = 0.0f;\n    float3 _3584 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3585 = float3(0.0f, 0.0f, 1.0f);\n    float _3586 = 1.0f;\n    float _3587 = 1.0f;\n    float _2091 = clamp(s.specular, 0.0f, 1.0f);\n    float _2095 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2100 = (_2091 != 1.0f) || (_2095 != 1.5f);\n    bool _2110;\n    if (!_2100)\n    {\n        _2110 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2110 = _2100;\n    }\n    if (_2110)\n    {\n        float _2118 = (_2095 - 1.0f) / (_2095 + 1.0f);\n        f0 = lerp(min((_2118 * _2118).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2091, s.albedo, metallic.xxx);\n        _3568 = lerp(_2091, 1.0f, metallic);\n        _3567 = true;\n    }\n    float _2146 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2146 > 0.0f)\n    {\n        float _2154 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3571 = _2146;\n        _3572 = _2154;\n        float _2161 = _2154 * _2154;\n        _3573 = _2161;\n        _3574 = _2161 * _2161;\n        float _2173 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3576 = _2173;\n        _3569 = 1.0f - (_2146 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2173, 0.0f, 1.0f), 5.0f))));\n        _3567 = true;\n    }\n    float3 _2193 = max(s.sheen_color, 0.0f.xxx);\n    float _2202 = max(_2193.x, max(_2193.y, _2193.z));\n    if (_2202 > 0.0f)\n    {\n        float _2210 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3577 = true;\n        _3578 = _2193;\n        _3579 = _2210;\n        _3580 = _2210 * _2210;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2210;\n        float _2227 = fa_sheen_albedo(param, param_1);\n        _3582 = _2227;\n        _3581 = 1.0f - min(_2202 * _2227, 1.0f);\n        _3567 = true;\n    }\n    _3570 = _3569 * _3581;\n    float _2246 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2246 != 0.0f)\n    {\n        float3 _2261 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2261;\n        if (dot(_2261, _2261) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2275 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2275.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2275.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2275.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2279 = t;\n        float3 _2280 = normalize(_2279);\n        t = _2280;\n        float3 _2305 = normalize((_2280 * cos(s.anisotropy_rotation)) + ((cross(n, _2280) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3584 = _2305;\n        _3585 = cross(n, _2305);\n        float _2315 = roughness * roughness;\n        float _2321 = lerp(_2315, 1.0f, _2246 * _2246);\n        bool _2323 = _2246 > 0.0f;\n        _3586 = _2323 ? _2321 : _2315;\n        _3587 = _2323 ? _2315 : _2321;\n        _3583 = _2246;\n        _3567 = true;\n    }\n    FaLayers _3609 = { _3567, _3568, _3569, _3570, _3571, _3572, _3573, _3574, i.world_normal, _3576, _3577, _3578, _3579, _3580, _3581, _3582, _3583, _3584, _3585, _3586, _3587 };\n    return _3609;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1870 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1873 = _1870.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1873 * _1873, exp2((-9.27999973297119140625f) * ndv)) * _1873) + _1870.y)) + _1870.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_466_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _466_fa_env_horizon.w).xyz;\n    }\n    float _1775 = rough * rough;\n    float _1805 = 0.60000002384185791015625f * _1775;\n    return lerp(lerp(_466_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_466_fa_env_horizon.xyz, _466_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1775)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1805, 0.0500000007450580596923828125f + _1805, d.y).xxx), ((_466_fa_env_sky.xyz + _466_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1775 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2356;\n        if (L.aniso >= 0.0f)\n        {\n            _2356 = L.b;\n        }\n        else\n        {\n            _2356 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2356, v), _2356), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2389 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2389.x) + (L.f90.xxx * _2389.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2444 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2444.x) + _2444.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1912 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1912.x) + _1912.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2473 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2477 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2484 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2473.xxx);\n    float3 f0 = _2484;\n    float3 _2488 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2488;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2473;\n    float param_5 = _2477;\n    float3 param_6 = _2484;\n    FaLayers _2505 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2505.on)\n    {\n        FaLayers param_7 = _2505;\n        float3 param_8 = _2488;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2477;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2488;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2477;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_466_fa_cl_info.x) + int(_466_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _341 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _347 = fa_light_texel(param_1);\n    float _350 = _347.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _356 = _350 < 0.5f;\n    float3 l;\n    if (_356)\n    {\n        l = normalize(_341.xyz);\n    }\n    else\n    {\n        float3 _368 = _341.xyz - world_pos;\n        float _370 = length(_368);\n        dist = _370;\n        l = _368 / max(_370, 9.9999997473787516355514526367188e-05f).xxx;\n        float _385 = _370 / max(_341.w, 0.001000000047497451305389404296875f);\n        float _391 = clamp(1.0f - (_385 * _385), 0.0f, 1.0f);\n        atten = _391 * _391;\n        if (_350 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _405 = fa_light_texel(param_2);\n            float _415 = _405.w;\n            int param_3 = (li * 4) + 3;\n            float4 _421 = fa_light_texel(param_3);\n            float _422 = _421.x;\n            float cos_inner = _422;\n            if (_422 > 1.5f)\n            {\n                cos_inner = lerp(_415, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_415, cos_inner, dot(-l, normalize(_405.xyz)));\n        }\n    }\n    int _452;\n    if (_356)\n    {\n        _452 = 0;\n    }\n    else\n    {\n        _452 = (_350 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3566 = { l, _347.xyz * atten, atten, 1.0f, dist, _452 };\n    return _3566;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _692;\n    if (i == 0)\n    {\n        _692 = _702_fa_shadow_split.x;\n    }\n    else\n    {\n        float _708;\n        if (i == 1)\n        {\n            _708 = _702_fa_shadow_split.y;\n        }\n        else\n        {\n            float _716;\n            if (i == 2)\n            {\n                _716 = _702_fa_shadow_split.z;\n            }\n            else\n            {\n                _716 = _702_fa_shadow_split.w;\n            }\n            _708 = _716;\n        }\n        _692 = _708;\n    }\n    return _692;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _749 = fa_shadow_depth(param, param_1);\n    float _753;\n    if (conv.x < 0.5f)\n    {\n        _753 = _749;\n    }\n    else\n    {\n        _753 = (conv.y * conv.z) / (conv.z - (_749 * (conv.z - conv.y)));\n    }\n    return _753;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _680 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_680), sin(_680)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _799 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _813 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _799;\n            float2 _832 = fa_shadow_vogel(param_3, param_4, param_5) * _813;\n            float2 param_6 = uv + (_832 * _702_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _844 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_844 < (zr - (length(_832) * plane)))\n            {\n                sum += _844;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _888 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _888; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _888;\n        float param_11 = _799;\n        float2 _907 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_907 * _702_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_907) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_888);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _949 = max(_702_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _954 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _960 = sqrt(1.0f - (_954 * _954));\n    float _968 = min(_960 / max(_954, 0.20000000298023223876953125f), 4.0f);\n    float _973;\n    if (_702_fa_shadow_bias.y > 0.0f)\n    {\n        _973 = _702_fa_shadow_bias.y;\n    }\n    else\n    {\n        _973 = 1.5f * _702_fa_shadow_info[ci].x;\n    }\n    float4 _998 = mul(float4(world + (n * (_973 * _960)), 1.0f), _702_fa_shadow_mat[ci]);\n    float _1005 = _998.x;\n    bool _1008 = _1005 < _702_fa_shadow_rect[ci].x;\n    bool _1017;\n    if (!_1008)\n    {\n        _1017 = _1005 > _702_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1017 = _1008;\n    }\n    bool _1026;\n    if (!_1017)\n    {\n        _1026 = _998.y < _702_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1026 = _1017;\n    }\n    bool _1035;\n    if (!_1026)\n    {\n        _1035 = _998.y > _702_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1035 = _1026;\n    }\n    bool _1042;\n    if (!_1035)\n    {\n        _1042 = _998.z > 1.0f;\n    }\n    else\n    {\n        _1042 = _1035;\n    }\n    if (_1042)\n    {\n        return -1.0f;\n    }\n    float _1051;\n    if (_702_fa_shadow_bias.x > 0.0f)\n    {\n        _1051 = _702_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1051 = 1.5f * _702_fa_shadow_info[ci].x;\n    }\n    float2 param = _998.xy;\n    float4 param_1 = _702_fa_shadow_rect[ci];\n    float param_2 = _998.z - ((_1051 * (1.0f + (0.5f * _968))) / _949);\n    float param_3 = _702_fa_shadow_info[ci].x;\n    float param_4 = _949;\n    float param_5 = _949 * 0.25f;\n    float param_6 = ((_702_fa_shadow_info[ci].x * min(_968, 3.0f)) * 0.5f) / _949;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_702_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _702_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_466_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1479 = int(_702_fa_shadow_cfg.x + 0.5f);\n    if (_1479 < 1)\n    {\n        return 1.0f;\n    }\n    float _1495 = dot(world - _702_fa_shadow_eye.xyz, _702_fa_shadow_fwd.xyz);\n    int param = _1479 - 1;\n    if (_1495 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1507 = _1479 > 1;\n    bool _1514;\n    if (_1507)\n    {\n        _1514 = _1495 > _702_fa_shadow_split.x;\n    }\n    else\n    {\n        _1514 = _1507;\n    }\n    if (_1514)\n    {\n        ci = 1;\n    }\n    bool _1518 = _1479 > 2;\n    bool _1525;\n    if (_1518)\n    {\n        _1525 = _1495 > _702_fa_shadow_split.y;\n    }\n    else\n    {\n        _1525 = _1518;\n    }\n    if (_1525)\n    {\n        ci = 2;\n    }\n    bool _1529 = _1479 > 3;\n    bool _1536;\n    if (_1529)\n    {\n        _1536 = _1495 > _702_fa_shadow_split.z;\n    }\n    else\n    {\n        _1536 = _1529;\n    }\n    if (_1536)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1479)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1562 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1562;\n        if (_1562 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_702_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1587;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1587 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1587 = _702_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1606 = _702_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1587, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1617 = clamp((_1495 - (fa_shadow_split_at(param_7) - _1606)) / _1606, 0.0f, 1.0f);\n        if (_1617 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1479)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1638 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1638;\n                if (_1638 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1617);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1110 = _466_fa_pbr.z < 0.5f;\n    bool _1118;\n    if (!_1110)\n    {\n        _1118 = _702_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1118 = _1110;\n    }\n    if (_1118)\n    {\n        return 1.0f;\n    }\n    int param = (int(_702_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1131 = fa_light_texel(param);\n    float _1132 = _1131.x;\n    if (_1132 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1141 = int(_1132 + 0.5f);\n    int param_1 = _1141;\n    float4 _1145 = fa_light_texel(param_1);\n    int param_2 = _1141 + 1;\n    float4 _1150 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1153 = _1145.y;\n    if (_1153 > 0.0f)\n    {\n        float _1170 = 1.0f - smoothstep(0.75f * _1153, _1153, length(world - _702_fa_shadow_eye.xyz));\n        fade = _1170;\n        if (_1170 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1145.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1189 = world - fa_light_texel(param_3).xyz;\n        float3 _1192 = abs(_1189);\n        float _1194 = _1192.x;\n        float _1196 = _1192.y;\n        bool _1197 = _1194 >= _1196;\n        bool _1205;\n        if (_1197)\n        {\n            _1205 = _1194 >= _1192.z;\n        }\n        else\n        {\n            _1205 = _1197;\n        }\n        int _1206;\n        if (_1205)\n        {\n            _1206 = (_1189.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1219;\n            if (_1196 >= _1192.z)\n            {\n                _1219 = (_1189.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1219 = (_1189.z > 0.0f) ? 4 : 5;\n            }\n            _1206 = _1219;\n        }\n        face = _1206;\n    }\n    int _1238 = (_1141 + 2) + (face * 6);\n    int param_4 = _1238;\n    int param_5 = _1238 + 1;\n    int param_6 = _1238 + 3;\n    float4 _1252 = fa_light_texel(param_6);\n    int param_7 = _1238 + 4;\n    float4 _1257 = fa_light_texel(param_7);\n    int param_8 = _1238 + 5;\n    float4 _1262 = fa_light_texel(param_8);\n    float _1274 = _1262.x * max(dot(_1252, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1279 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1302 = clamp(dot(n, _1252.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1325 = min(sqrt(1.0f - (_1302 * _1302)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1252, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1328 = _1150.y;\n    float _1330;\n    if (_1328 > 0.0f)\n    {\n        _1330 = _1328;\n    }\n    else\n    {\n        _1330 = 1.5f * _1274;\n    }\n    float4 _1350 = float4(world + (n * (_1330 * sqrt(1.0f - (_1279 * _1279)))), 1.0f);\n    float _1354 = dot(_1252, _1350);\n    float _1357 = _1262.y;\n    if (_1354 < _1357)\n    {\n        return 1.0f;\n    }\n    float2 _1372 = float2(dot(fa_light_texel(param_4), _1350), dot(fa_light_texel(param_5), _1350)) / _1354.xx;\n    float _1374 = _1372.x;\n    bool _1377 = _1374 < _1257.x;\n    bool _1386;\n    if (!_1377)\n    {\n        _1386 = _1374 > _1257.z;\n    }\n    else\n    {\n        _1386 = _1377;\n    }\n    bool _1395;\n    if (!_1386)\n    {\n        _1395 = _1372.y < _1257.y;\n    }\n    else\n    {\n        _1395 = _1386;\n    }\n    bool _1404;\n    if (!_1395)\n    {\n        _1404 = _1372.y > _1257.w;\n    }\n    else\n    {\n        _1404 = _1395;\n    }\n    if (_1404)\n    {\n        return 1.0f;\n    }\n    float _1410 = _1150.x;\n    float _1412;\n    if (_1410 > 0.0f)\n    {\n        _1412 = _1410;\n    }\n    else\n    {\n        _1412 = 1.5f * _1274;\n    }\n    float2 param_10 = _1372;\n    float4 param_11 = _1257;\n    float param_12 = _1354 - (_1412 * (1.0f + (0.5f * _1325)));\n    float param_13 = _1274;\n    float param_14 = 1.0f;\n    float param_15 = _1262.z * 0.25f;\n    float param_16 = (_1274 * min(_1325, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1357, _1262.z);\n    int param_18 = int(_1145.z + 0.5f);\n    float param_19 = _1145.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2578 = fa_lm.z > 0.5f;\n    bool _2584;\n    if (_2578)\n    {\n        int param = li;\n        _2584 = fa_light_baked(param);\n    }\n    else\n    {\n        _2584 = _2578;\n    }\n    if (_2584)\n    {\n        int param_1 = li;\n        LightSample _3686 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _3686;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2606 = fa_light_sample(param_2, param_3);\n    float3 _3693 = _2606.direction;\n    float3 _3688 = _2606.color;\n    float _3695 = _2606.attenuation;\n    float _3690 = _2606.shadow;\n    int _3698 = _2606.type;\n    if ((_3698 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3693;\n        float _2620 = fa_shadow_factor(param_4, param_5);\n        _3690 = _2620;\n        _3688 *= _2620;\n    }\n    else\n    {\n        bool _2631 = _3698 != 0;\n        bool _2637;\n        if (_2631)\n        {\n            _2637 = _3695 > 0.0f;\n        }\n        else\n        {\n            _2637 = _2631;\n        }\n        if (_2637)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3693;\n            float _2649 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3690 = _2649;\n            _3688 *= _2649;\n        }\n    }\n    LightSample _3705 = { _3693, _3688, _3695, _3690, _2606._distance, _3698 };\n    return _3705;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_702_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1662 = int(_702_fa_shadow_cfg.x + 0.5f);\n    float _1672 = dot(world - _702_fa_shadow_eye.xyz, _702_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1677 = _1662 > 0;\n    bool _1686;\n    if (_1677)\n    {\n        int param = _1662 - 1;\n        _1686 = _1672 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1686 = _1677;\n    }\n    if (_1686)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1693 = _1662 > 1;\n        bool _1700;\n        if (_1693)\n        {\n            _1700 = _1672 > _702_fa_shadow_split.x;\n        }\n        else\n        {\n            _1700 = _1693;\n        }\n        if (_1700)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1706 = _1662 > 2;\n        bool _1713;\n        if (_1706)\n        {\n            _1713 = _1672 > _702_fa_shadow_split.y;\n        }\n        else\n        {\n            _1713 = _1706;\n        }\n        if (_1713)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1719 = _1662 > 3;\n        bool _1726;\n        if (_1719)\n        {\n            _1726 = _1672 > _702_fa_shadow_split.z;\n        }\n        else\n        {\n            _1726 = _1719;\n        }\n        if (_1726)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3397 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3397 = -_3397;\n    }\n    float3 _3049 = normalize(_466_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3410 = { fa_world_pos, _3397, fa_world_tangent, fa_uv, fa_vertex_color, _3049, gl_FrontFacing };\n    SurfaceInput param_1 = _3410;\n    Surface _3057 = fa_standard_surface(param_1);\n    float3 _3436 = _3057.albedo;\n    float _3437 = _3057.alpha;\n    float3 _3438 = _3057.normal;\n    float _3439 = _3057.metallic;\n    float _3440 = _3057.roughness;\n    float _3441 = _3057.occlusion;\n    float3 _3442 = _3057.emission;\n    float _3443 = _3057.clearcoat;\n    float _3444 = _3057.clearcoat_roughness;\n    float3 _3445 = _3057.sheen_color;\n    float _3446 = _3057.sheen_roughness;\n    float _3447 = _3057.anisotropy;\n    float _3448 = _3057.anisotropy_rotation;\n    float _3449 = _3057.specular;\n    float _3450 = _3057.ior;\n    float3 _3451 = _3057.specular_color;\n    SurfaceInput _3418 = { fa_world_pos, _3397, fa_world_tangent, fa_uv, fa_vertex_color, _3049, gl_FrontFacing };\n    SurfaceInput param_2 = _3418;\n    Surface param_3 = _3057;\n    surface(param_2, param_3);\n    _3436 = param_3.albedo;\n    _3437 = param_3.alpha;\n    _3438 = param_3.normal;\n    _3439 = param_3.metallic;\n    _3440 = param_3.roughness;\n    _3441 = param_3.occlusion;\n    _3442 = param_3.emission;\n    _3443 = param_3.clearcoat;\n    _3444 = param_3.clearcoat_roughness;\n    _3445 = param_3.sheen_color;\n    _3446 = param_3.sheen_roughness;\n    _3447 = param_3.anisotropy;\n    _3448 = param_3.anisotropy_rotation;\n    _3449 = param_3.specular;\n    _3450 = param_3.ior;\n    _3451 = param_3.specular_color;\n    float3 result;\n    if (_466_fa_emissive.w > 0.5f)\n    {\n        result = _3436;\n    }\n    else\n    {\n        float3 _3078 = _3438;\n        float3 _3079 = normalize(_3078);\n        _3438 = _3079;\n        float3 param_4 = _3079;\n        SurfaceInput _3426 = { fa_world_pos, _3397, fa_world_tangent, fa_uv, fa_vertex_color, _3049, gl_FrontFacing };\n        SurfaceInput param_5 = _3426;\n        Surface _3517 = { _3436, _3437, _3438, _3439, _3440, _3441, _3442, _3443, _3444, _3445, _3446, _3447, _3448, _3449, _3450, _3451 };\n        Surface param_6 = _3517;\n        float3 param_7 = fa_indirect_diffuse(param_4);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _3098 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3098; ln++)\n        {\n            int param_8 = ln;\n            int _3111 = fa_cl_light(param_8);\n            bool _3114 = fa_lm.z > 0.5f;\n            bool _3120;\n            if (_3114)\n            {\n                int param_9 = _3111;\n                _3120 = fa_light_baked(param_9);\n            }\n            else\n            {\n                _3120 = _3114;\n            }\n            if (_3120)\n            {\n                continue;\n            }\n            int param_10 = _3111;\n            float3 param_11 = fa_world_pos;\n            float3 param_12 = _3397;\n            SurfaceInput _3434 = { fa_world_pos, _3397, fa_world_tangent, fa_uv, fa_vertex_color, _3049, gl_FrontFacing };\n            SurfaceInput param_13 = _3434;\n            Surface _3534 = { _3436, _3437, _3438, _3439, _3440, _3441, _3442, _3443, _3444, _3445, _3446, _3447, _3448, _3449, _3450, _3451 };\n            Surface param_14 = _3534;\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    float3 _3147 = result;\n    float3 _3148 = _3147 + _3442;\n    result = _3148;\n    float3 param_16 = _3148;\n    float3 param_17 = fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17);\n    bool _3157 = _466_fa_fog.w > 0.0f;\n    bool _3164;\n    if (!_3157)\n    {\n        _3164 = _466_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3164 = _3157;\n    }\n    if (_3164)\n    {\n        float3 _3173 = fa_world_pos - _466_fa_camera_pos.xyz;\n        float _3179 = dot(_3173, _466_fa_fog_c.xyz);\n        bool _3183 = _466_fa_fog_c.w > 0.5f;\n        float _3184;\n        if (_3183)\n        {\n            _3184 = _3179;\n        }\n        else\n        {\n            _3184 = length(_3173);\n        }\n        float _3196 = _3184 - _466_fa_fog_b.x;\n        if (_3196 > 0.0f)\n        {\n            float _3205 = _466_fa_fog.w * _3196;\n            float tau = _3205 * _3205;\n            if (_466_fa_fog_b.y > 0.0f)\n            {\n                float _3221;\n                if (_3183)\n                {\n                    _3221 = fa_world_pos.y - (_466_fa_fog_c.y * _3179);\n                }\n                else\n                {\n                    _3221 = _466_fa_camera_pos.y;\n                }\n                float _3242 = lerp(_3221, fa_world_pos.y, clamp(_466_fa_fog_b.x / _3184, 0.0f, 1.0f));\n                float _3246 = fa_world_pos.y - _3242;\n                float _3251 = _3242 - _466_fa_fog_b.z;\n                float _3256 = fa_world_pos.y - _466_fa_fog_b.z;\n                bool _3259 = _3251 <= 0.0f;\n                bool _3260 = !_3259;\n                bool _3266;\n                if (_3260)\n                {\n                    _3266 = _466_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3266 = _3259;\n                }\n                float _3267;\n                if (_3266)\n                {\n                    _3267 = _466_fa_fog_b.y;\n                }\n                else\n                {\n                    _3267 = _466_fa_fog_b.y * exp(-min(_466_fa_fog_b.w * _3251, 80.0f));\n                }\n                bool _3294;\n                if (_3260)\n                {\n                    _3294 = _466_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3294 = _3259;\n                }\n                float _3295;\n                if (_3294)\n                {\n                    _3295 = _466_fa_fog_b.y * _3251;\n                }\n                else\n                {\n                    _3295 = (_466_fa_fog_b.y * (1.0f - exp(-min(_466_fa_fog_b.w * _3251, 80.0f)))) / _466_fa_fog_b.w;\n                }\n                bool _3320 = _3256 <= 0.0f;\n                bool _3327;\n                if (!_3320)\n                {\n                    _3327 = _466_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3327 = _3320;\n                }\n                float _3328;\n                if (_3327)\n                {\n                    _3328 = _466_fa_fog_b.y * _3256;\n                }\n                else\n                {\n                    _3328 = (_466_fa_fog_b.y * (1.0f - exp(-min(_466_fa_fog_b.w * _3256, 80.0f)))) / _466_fa_fog_b.w;\n                }\n                float _3355;\n                if (abs(_3246) < 0.001000000047497451305389404296875f)\n                {\n                    _3355 = _3267;\n                }\n                else\n                {\n                    _3355 = (_3328 - _3295) / _3246;\n                }\n                tau += (_3196 * max(_3355, 0.0f));\n            }\n            result = lerp(result, _466_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3437);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_466",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_702",
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_388, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _2013[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _466_fa_camera_pos : packoffset(c0);\n    float4 _466_fa_ambient : packoffset(c1);\n    float4 _466_fa_base_color : packoffset(c2);\n    float4 _466_fa_emissive : packoffset(c3);\n    float4 _466_fa_model_emissive : packoffset(c4);\n    float4 _466_fa_pbr : packoffset(c5);\n    float4 _466_fa_maps : packoffset(c6);\n    float4 _466_fa_fog : packoffset(c7);\n    float4 _466_fa_fog_b : packoffset(c8);\n    float4 _466_fa_fog_c : packoffset(c9);\n    float4 _466_fa_counts : packoffset(c10);\n    float4 _466_fa_env_sky : packoffset(c11);\n    float4 _466_fa_env_horizon : packoffset(c12);\n    float4 _466_fa_time : packoffset(c13);\n    float4 _466_fa_cl_vpx : packoffset(c14);\n    float4 _466_fa_cl_vpy : packoffset(c15);\n    float4 _466_fa_cl_vpw : packoffset(c16);\n    float4 _466_fa_cl_fwd : packoffset(c17);\n    float4 _466_fa_cl_grid : packoffset(c18);\n    float4 _466_fa_cl_info : packoffset(c19);\n    float4 _466_fa_layers_a : packoffset(c20);\n    float4 _466_fa_layers_b : packoffset(c21);\n    float4 _466_fa_layers_c : packoffset(c22);\n    float4 _466_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _702_fa_shadow_mat[4] : packoffset(c0);\n    float4 _702_fa_shadow_rect[4] : packoffset(c16);\n    float4 _702_fa_shadow_info[4] : packoffset(c20);\n    float4 _702_fa_shadow_split : packoffset(c24);\n    float4 _702_fa_shadow_cfg : packoffset(c25);\n    float4 _702_fa_shadow_bias : packoffset(c26);\n    float4 _702_fa_shadow_eye : packoffset(c27);\n    float4 _702_fa_shadow_fwd : packoffset(c28);\n    float4 _702_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t8);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t7);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _471 = _466_fa_cl_info.x < 0.0f;\n    bool _478;\n    if (!_471)\n    {\n        _478 = _466_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _478 = _471;\n    }\n    bool _486;\n    if (!_478)\n    {\n        _486 = _466_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _486 = _478;\n    }\n    bool _493;\n    if (!_486)\n    {\n        _493 = _466_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _493 = _486;\n    }\n    bool _500;\n    if (!_493)\n    {\n        _500 = _466_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _500 = _493;\n    }\n    if (_500)\n    {\n        return int2(0, 0);\n    }\n    float4 _510 = float4(world_pos, 1.0f);\n    float _517 = dot(_466_fa_cl_vpw, _510);\n    if (!(_517 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _539 = float2(dot(_466_fa_cl_vpx, _510), dot(_466_fa_cl_vpy, _510)) / _517.xx;\n    int _543 = int(_466_fa_cl_grid.x);\n    int _547 = int(_466_fa_cl_grid.y);\n    int param = (int(_466_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_466_fa_cl_fwd.xyz, world_pos) + _466_fa_cl_fwd.w, _466_fa_cl_grid.w) / _466_fa_cl_grid.w) * _466_fa_cl_grid.z)), 0, int(_466_fa_cl_info.y) - 1) * _547) + clamp(int(floor(((_539.y * 0.5f) + 0.5f) * _466_fa_cl_grid.y)), 0, _547 - 1)) * _543)) + clamp(int(floor(((_539.x * 0.5f) + 0.5f) * _466_fa_cl_grid.x)), 0, _543 - 1);\n    float4 _618 = fa_light_texel(param);\n    return int2(int(_618.x), int(_618.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_466_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2551 = fa_cluster_lookup(param);\n    fa_cl_slot = _2551.x;\n    fa_cl_local = _2551.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _2716 = fa_linear_to_srgb(param);\n        c = _2716;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _2724 = fa_srgb_to_linear(param_1);\n            c = _2724;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _230;\n    if (i.front_facing)\n    {\n        _230 = i.world_normal;\n    }\n    else\n    {\n        _230 = -i.world_normal;\n    }\n    float3 _254 = normalize(i.world_tangent.xyz - (_230 * dot(_230, i.world_tangent.xyz)));\n    float3 _282 = normalize(((_254 * m.x) + ((cross(_230, _254) * i.world_tangent.w) * m.y)) + (_230 * m.z));\n    float3 _285;\n    if (i.front_facing)\n    {\n        _285 = _282;\n    }\n    else\n    {\n        _285 = -_282;\n    }\n    return _285;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _466_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2755 = fa_tex_fix(param_2, param_3);\n    float4 _3806 = base_t;\n    _3806.x = _2755.x;\n    _3806.y = _2755.y;\n    _3806.z = _2755.z;\n    base_t = _3806;\n    float4 _2769 = (_3806 * _466_fa_base_color) * i.vertex_color;\n    float3 _3708 = i.world_normal;\n    if (_466_fa_maps.z > 0.5f)\n    {\n        float param_4 = _466_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2801 = fa_tex_fix(param_6, param_7);\n        float3 _2805 = (_2801 * 2.0f) - 1.0f.xxx;\n        float2 _2810 = _2805.xy * _466_fa_maps.x;\n        float3 _3814 = _2805;\n        _3814.x = _2810.x;\n        _3814.y = _2810.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3814;\n        _3708 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _466_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2839 = fa_tex_fix(param_12, param_13);\n    float4 _3817 = mrt;\n    _3817.x = _2839.x;\n    _3817.y = _2839.y;\n    _3817.z = _2839.z;\n    mrt = _3817;\n    float4 _2867 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _466_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2867.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2879 = fa_tex_fix(param_16, param_17);\n    float param_18 = _466_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2909 = fa_tex_fix(param_20, param_21);\n    float _3713 = _466_fa_layers_a.x;\n    float _3714 = _466_fa_layers_a.y;\n    float _3717 = _466_fa_layers_a.z;\n    float _3716 = _466_fa_layers_b.w;\n    float _3719 = _466_fa_layers_c.x;\n    if (_466_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_466_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _3713 *= _2879.y;\n            _3714 *= _2879.z;\n            _3716 *= _2867.w;\n        }\n        if (_466_fa_layers_c.z > 1.5f)\n        {\n            _3717 *= mrt.x;\n            _3719 *= mrt.w;\n        }\n    }\n    Surface _3738 = { _2769.xyz, _2769.w, _3708, clamp(_466_fa_pbr.x * _2839.z, 0.0f, 1.0f), clamp(_466_fa_pbr.y * _2839.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_466_fa_maps.y * (_2879.x - 1.0f)), _466_fa_emissive.xyz + (_466_fa_model_emissive.xyz * _2909), _3713, _3714, _466_fa_layers_b.xyz, _3716, _3717, _466_fa_layers_a.w, _3719, _466_fa_layers_c.y, _466_fa_layers_d.xyz };\n    return _3738;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_466_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _466_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1938 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _1946 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _1949 = int(_1938);\n    int _1952 = int(_1946);\n    float _1962 = _1946 - float(_1952);\n    int _2018 = (_1949 * 9) + _1952;\n    int _2038 = ((_1949 + 1) * 9) + _1952;\n    return lerp(lerp(_2013[_2018], _2013[_2018 + 1], _1962), lerp(_2013[_2038], _2013[_2038 + 1], _1962), _1938 - float(_1949));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _3567 = false;\n    float _3568 = 1.0f;\n    float _3569 = 1.0f;\n    float _3570 = 1.0f;\n    float _3571 = 0.0f;\n    float _3572 = 0.0f;\n    float _3573 = 0.0f;\n    float _3574 = 0.0f;\n    float _3576 = 1.0f;\n    bool _3577 = false;\n    float3 _3578 = 0.0f.xxx;\n    float _3579 = 1.0f;\n    float _3580 = 1.0f;\n    float _3581 = 1.0f;\n    float _3582 = 0.0f;\n    float _3583 = 0.0f;\n    float3 _3584 = float3(1.0f, 0.0f, 0.0f);\n    float3 _3585 = float3(0.0f, 0.0f, 1.0f);\n    float _3586 = 1.0f;\n    float _3587 = 1.0f;\n    float _2091 = clamp(s.specular, 0.0f, 1.0f);\n    float _2095 = clamp(s.ior, 1.0f, 3.0f);\n    bool _2100 = (_2091 != 1.0f) || (_2095 != 1.5f);\n    bool _2110;\n    if (!_2100)\n    {\n        _2110 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _2110 = _2100;\n    }\n    if (_2110)\n    {\n        float _2118 = (_2095 - 1.0f) / (_2095 + 1.0f);\n        f0 = lerp(min((_2118 * _2118).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _2091, s.albedo, metallic.xxx);\n        _3568 = lerp(_2091, 1.0f, metallic);\n        _3567 = true;\n    }\n    float _2146 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_2146 > 0.0f)\n    {\n        float _2154 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _3571 = _2146;\n        _3572 = _2154;\n        float _2161 = _2154 * _2154;\n        _3573 = _2161;\n        _3574 = _2161 * _2161;\n        float _2173 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _3576 = _2173;\n        _3569 = 1.0f - (_2146 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _2173, 0.0f, 1.0f), 5.0f))));\n        _3567 = true;\n    }\n    float3 _2193 = max(s.sheen_color, 0.0f.xxx);\n    float _2202 = max(_2193.x, max(_2193.y, _2193.z));\n    if (_2202 > 0.0f)\n    {\n        float _2210 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _3577 = true;\n        _3578 = _2193;\n        _3579 = _2210;\n        _3580 = _2210 * _2210;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _2210;\n        float _2227 = fa_sheen_albedo(param, param_1);\n        _3582 = _2227;\n        _3581 = 1.0f - min(_2202 * _2227, 1.0f);\n        _3567 = true;\n    }\n    _3570 = _3569 * _3581;\n    float _2246 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_2246 != 0.0f)\n    {\n        float3 _2261 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2261;\n        if (dot(_2261, _2261) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _2275 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_2275.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _2275.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _2275.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _2279 = t;\n        float3 _2280 = normalize(_2279);\n        t = _2280;\n        float3 _2305 = normalize((_2280 * cos(s.anisotropy_rotation)) + ((cross(n, _2280) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _3584 = _2305;\n        _3585 = cross(n, _2305);\n        float _2315 = roughness * roughness;\n        float _2321 = lerp(_2315, 1.0f, _2246 * _2246);\n        bool _2323 = _2246 > 0.0f;\n        _3586 = _2323 ? _2321 : _2315;\n        _3587 = _2323 ? _2315 : _2321;\n        _3583 = _2246;\n        _3567 = true;\n    }\n    FaLayers _3609 = { _3567, _3568, _3569, _3570, _3571, _3572, _3573, _3574, i.world_normal, _3576, _3577, _3578, _3579, _3580, _3581, _3582, _3583, _3584, _3585, _3586, _3587 };\n    return _3609;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1870 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1873 = _1870.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1873 * _1873, exp2((-9.27999973297119140625f) * ndv)) * _1873) + _1870.y)) + _1870.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_466_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _466_fa_env_horizon.w).xyz;\n    }\n    float _1775 = rough * rough;\n    float _1805 = 0.60000002384185791015625f * _1775;\n    return lerp(lerp(_466_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_466_fa_env_horizon.xyz, _466_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1775)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1805, 0.0500000007450580596923828125f + _1805, d.y).xxx), ((_466_fa_env_sky.xyz + _466_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1775 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _2356;\n        if (L.aniso >= 0.0f)\n        {\n            _2356 = L.b;\n        }\n        else\n        {\n            _2356 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_2356, v), _2356), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _2389 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _2389.x) + (L.f90.xxx * _2389.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2444 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _2444.x) + _2444.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1912 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1912.x) + _1912.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2473 = clamp(s.metallic, 0.0f, 1.0f);\n    float _2477 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _2484 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _2473.xxx);\n    float3 f0 = _2484;\n    float3 _2488 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2488;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2473;\n    float param_5 = _2477;\n    float3 param_6 = _2484;\n    FaLayers _2505 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2505.on)\n    {\n        FaLayers param_7 = _2505;\n        float3 param_8 = _2488;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2477;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _2488;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2477;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_466_fa_cl_info.x) + int(_466_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _341 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _347 = fa_light_texel(param_1);\n    float _350 = _347.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _356 = _350 < 0.5f;\n    float3 l;\n    if (_356)\n    {\n        l = normalize(_341.xyz);\n    }\n    else\n    {\n        float3 _368 = _341.xyz - world_pos;\n        float _370 = length(_368);\n        dist = _370;\n        l = _368 / max(_370, 9.9999997473787516355514526367188e-05f).xxx;\n        float _385 = _370 / max(_341.w, 0.001000000047497451305389404296875f);\n        float _391 = clamp(1.0f - (_385 * _385), 0.0f, 1.0f);\n        atten = _391 * _391;\n        if (_350 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _405 = fa_light_texel(param_2);\n            float _415 = _405.w;\n            int param_3 = (li * 4) + 3;\n            float4 _421 = fa_light_texel(param_3);\n            float _422 = _421.x;\n            float cos_inner = _422;\n            if (_422 > 1.5f)\n            {\n                cos_inner = lerp(_415, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_415, cos_inner, dot(-l, normalize(_405.xyz)));\n        }\n    }\n    int _452;\n    if (_356)\n    {\n        _452 = 0;\n    }\n    else\n    {\n        _452 = (_350 > 1.5f) ? 2 : 1;\n    }\n    LightSample _3566 = { l, _347.xyz * atten, atten, 1.0f, dist, _452 };\n    return _3566;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _692;\n    if (i == 0)\n    {\n        _692 = _702_fa_shadow_split.x;\n    }\n    else\n    {\n        float _708;\n        if (i == 1)\n        {\n            _708 = _702_fa_shadow_split.y;\n        }\n        else\n        {\n            float _716;\n            if (i == 2)\n            {\n                _716 = _702_fa_shadow_split.z;\n            }\n            else\n            {\n                _716 = _702_fa_shadow_split.w;\n            }\n            _708 = _716;\n        }\n        _692 = _708;\n    }\n    return _692;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _749 = fa_shadow_depth(param, param_1);\n    float _753;\n    if (conv.x < 0.5f)\n    {\n        _753 = _749;\n    }\n    else\n    {\n        _753 = (conv.y * conv.z) / (conv.z - (_749 * (conv.z - conv.y)));\n    }\n    return _753;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _680 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_680), sin(_680)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _799 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _813 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _799;\n            float2 _832 = fa_shadow_vogel(param_3, param_4, param_5) * _813;\n            float2 param_6 = uv + (_832 * _702_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _844 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_844 < (zr - (length(_832) * plane)))\n            {\n                sum += _844;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _888 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _888; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _888;\n        float param_11 = _799;\n        float2 _907 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_907 * _702_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_907) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_888);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _949 = max(_702_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _954 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _960 = sqrt(1.0f - (_954 * _954));\n    float _968 = min(_960 / max(_954, 0.20000000298023223876953125f), 4.0f);\n    float _973;\n    if (_702_fa_shadow_bias.y > 0.0f)\n    {\n        _973 = _702_fa_shadow_bias.y;\n    }\n    else\n    {\n        _973 = 1.5f * _702_fa_shadow_info[ci].x;\n    }\n    float4 _998 = mul(float4(world + (n * (_973 * _960)), 1.0f), _702_fa_shadow_mat[ci]);\n    float _1005 = _998.x;\n    bool _1008 = _1005 < _702_fa_shadow_rect[ci].x;\n    bool _1017;\n    if (!_1008)\n    {\n        _1017 = _1005 > _702_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1017 = _1008;\n    }\n    bool _1026;\n    if (!_1017)\n    {\n        _1026 = _998.y < _702_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1026 = _1017;\n    }\n    bool _1035;\n    if (!_1026)\n    {\n        _1035 = _998.y > _702_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1035 = _1026;\n    }\n    bool _1042;\n    if (!_1035)\n    {\n        _1042 = _998.z > 1.0f;\n    }\n    else\n    {\n        _1042 = _1035;\n    }\n    if (_1042)\n    {\n        return -1.0f;\n    }\n    float _1051;\n    if (_702_fa_shadow_bias.x > 0.0f)\n    {\n        _1051 = _702_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1051 = 1.5f * _702_fa_shadow_info[ci].x;\n    }\n    float2 param = _998.xy;\n    float4 param_1 = _702_fa_shadow_rect[ci];\n    float param_2 = _998.z - ((_1051 * (1.0f + (0.5f * _968))) / _949);\n    float param_3 = _702_fa_shadow_info[ci].x;\n    float param_4 = _949;\n    float param_5 = _949 * 0.25f;\n    float param_6 = ((_702_fa_shadow_info[ci].x * min(_968, 3.0f)) * 0.5f) / _949;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_702_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _702_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_466_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1479 = int(_702_fa_shadow_cfg.x + 0.5f);\n    if (_1479 < 1)\n    {\n        return 1.0f;\n    }\n    float _1495 = dot(world - _702_fa_shadow_eye.xyz, _702_fa_shadow_fwd.xyz);\n    int param = _1479 - 1;\n    if (_1495 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1507 = _1479 > 1;\n    bool _1514;\n    if (_1507)\n    {\n        _1514 = _1495 > _702_fa_shadow_split.x;\n    }\n    else\n    {\n        _1514 = _1507;\n    }\n    if (_1514)\n    {\n        ci = 1;\n    }\n    bool _1518 = _1479 > 2;\n    bool _1525;\n    if (_1518)\n    {\n        _1525 = _1495 > _702_fa_shadow_split.y;\n    }\n    else\n    {\n        _1525 = _1518;\n    }\n    if (_1525)\n    {\n        ci = 2;\n    }\n    bool _1529 = _1479 > 3;\n    bool _1536;\n    if (_1529)\n    {\n        _1536 = _1495 > _702_fa_shadow_split.z;\n    }\n    else\n    {\n        _1536 = _1529;\n    }\n    if (_1536)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1479)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1562 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1562;\n        if (_1562 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_702_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1587;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1587 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1587 = _702_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1606 = _702_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1587, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1617 = clamp((_1495 - (fa_shadow_split_at(param_7) - _1606)) / _1606, 0.0f, 1.0f);\n        if (_1617 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1479)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1638 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1638;\n                if (_1638 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1617);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1110 = _466_fa_pbr.z < 0.5f;\n    bool _1118;\n    if (!_1110)\n    {\n        _1118 = _702_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1118 = _1110;\n    }\n    if (_1118)\n    {\n        return 1.0f;\n    }\n    int param = (int(_702_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1131 = fa_light_texel(param);\n    float _1132 = _1131.x;\n    if (_1132 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1141 = int(_1132 + 0.5f);\n    int param_1 = _1141;\n    float4 _1145 = fa_light_texel(param_1);\n    int param_2 = _1141 + 1;\n    float4 _1150 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1153 = _1145.y;\n    if (_1153 > 0.0f)\n    {\n        float _1170 = 1.0f - smoothstep(0.75f * _1153, _1153, length(world - _702_fa_shadow_eye.xyz));\n        fade = _1170;\n        if (_1170 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1145.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1189 = world - fa_light_texel(param_3).xyz;\n        float3 _1192 = abs(_1189);\n        float _1194 = _1192.x;\n        float _1196 = _1192.y;\n        bool _1197 = _1194 >= _1196;\n        bool _1205;\n        if (_1197)\n        {\n            _1205 = _1194 >= _1192.z;\n        }\n        else\n        {\n            _1205 = _1197;\n        }\n        int _1206;\n        if (_1205)\n        {\n            _1206 = (_1189.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1219;\n            if (_1196 >= _1192.z)\n            {\n                _1219 = (_1189.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1219 = (_1189.z > 0.0f) ? 4 : 5;\n            }\n            _1206 = _1219;\n        }\n        face = _1206;\n    }\n    int _1238 = (_1141 + 2) + (face * 6);\n    int param_4 = _1238;\n    int param_5 = _1238 + 1;\n    int param_6 = _1238 + 3;\n    float4 _1252 = fa_light_texel(param_6);\n    int param_7 = _1238 + 4;\n    float4 _1257 = fa_light_texel(param_7);\n    int param_8 = _1238 + 5;\n    float4 _1262 = fa_light_texel(param_8);\n    float _1274 = _1262.x * max(dot(_1252, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1279 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1302 = clamp(dot(n, _1252.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1325 = min(sqrt(1.0f - (_1302 * _1302)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1252, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1328 = _1150.y;\n    float _1330;\n    if (_1328 > 0.0f)\n    {\n        _1330 = _1328;\n    }\n    else\n    {\n        _1330 = 1.5f * _1274;\n    }\n    float4 _1350 = float4(world + (n * (_1330 * sqrt(1.0f - (_1279 * _1279)))), 1.0f);\n    float _1354 = dot(_1252, _1350);\n    float _1357 = _1262.y;\n    if (_1354 < _1357)\n    {\n        return 1.0f;\n    }\n    float2 _1372 = float2(dot(fa_light_texel(param_4), _1350), dot(fa_light_texel(param_5), _1350)) / _1354.xx;\n    float _1374 = _1372.x;\n    bool _1377 = _1374 < _1257.x;\n    bool _1386;\n    if (!_1377)\n    {\n        _1386 = _1374 > _1257.z;\n    }\n    else\n    {\n        _1386 = _1377;\n    }\n    bool _1395;\n    if (!_1386)\n    {\n        _1395 = _1372.y < _1257.y;\n    }\n    else\n    {\n        _1395 = _1386;\n    }\n    bool _1404;\n    if (!_1395)\n    {\n        _1404 = _1372.y > _1257.w;\n    }\n    else\n    {\n        _1404 = _1395;\n    }\n    if (_1404)\n    {\n        return 1.0f;\n    }\n    float _1410 = _1150.x;\n    float _1412;\n    if (_1410 > 0.0f)\n    {\n        _1412 = _1410;\n    }\n    else\n    {\n        _1412 = 1.5f * _1274;\n    }\n    float2 param_10 = _1372;\n    float4 param_11 = _1257;\n    float param_12 = _1354 - (_1412 * (1.0f + (0.5f * _1325)));\n    float param_13 = _1274;\n    float param_14 = 1.0f;\n    float param_15 = _1262.z * 0.25f;\n    float param_16 = (_1274 * min(_1325, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1357, _1262.z);\n    int param_18 = int(_1145.z + 0.5f);\n    float param_19 = _1145.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _2578 = fa_lm.z > 0.5f;\n    bool _2584;\n    if (_2578)\n    {\n        int param = li;\n        _2584 = fa_light_baked(param);\n    }\n    else\n    {\n        _2584 = _2578;\n    }\n    if (_2584)\n    {\n        int param_1 = li;\n        LightSample _3686 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _3686;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _2606 = fa_light_sample(param_2, param_3);\n    float3 _3693 = _2606.direction;\n    float3 _3688 = _2606.color;\n    float _3695 = _2606.attenuation;\n    float _3690 = _2606.shadow;\n    int _3698 = _2606.type;\n    if ((_3698 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _3693;\n        float _2620 = fa_shadow_factor(param_4, param_5);\n        _3690 = _2620;\n        _3688 *= _2620;\n    }\n    else\n    {\n        bool _2631 = _3698 != 0;\n        bool _2637;\n        if (_2631)\n        {\n            _2637 = _3695 > 0.0f;\n        }\n        else\n        {\n            _2637 = _2631;\n        }\n        if (_2637)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _3693;\n            float _2649 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3690 = _2649;\n            _3688 *= _2649;\n        }\n    }\n    LightSample _3705 = { _3693, _3688, _3695, _3690, _2606._distance, _3698 };\n    return _3705;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_702_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1662 = int(_702_fa_shadow_cfg.x + 0.5f);\n    float _1672 = dot(world - _702_fa_shadow_eye.xyz, _702_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1677 = _1662 > 0;\n    bool _1686;\n    if (_1677)\n    {\n        int param = _1662 - 1;\n        _1686 = _1672 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1686 = _1677;\n    }\n    if (_1686)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1693 = _1662 > 1;\n        bool _1700;\n        if (_1693)\n        {\n            _1700 = _1672 > _702_fa_shadow_split.x;\n        }\n        else\n        {\n            _1700 = _1693;\n        }\n        if (_1700)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1706 = _1662 > 2;\n        bool _1713;\n        if (_1706)\n        {\n            _1713 = _1672 > _702_fa_shadow_split.y;\n        }\n        else\n        {\n            _1713 = _1706;\n        }\n        if (_1713)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1719 = _1662 > 3;\n        bool _1726;\n        if (_1719)\n        {\n            _1726 = _1672 > _702_fa_shadow_split.z;\n        }\n        else\n        {\n            _1726 = _1719;\n        }\n        if (_1726)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _3397 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3397 = -_3397;\n    }\n    float3 _3049 = normalize(_466_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _3410 = { fa_world_pos, _3397, fa_world_tangent, fa_uv, fa_vertex_color, _3049, gl_FrontFacing };\n    SurfaceInput param_1 = _3410;\n    Surface _3057 = fa_standard_surface(param_1);\n    float3 _3436 = _3057.albedo;\n    float _3437 = _3057.alpha;\n    float3 _3438 = _3057.normal;\n    float _3439 = _3057.metallic;\n    float _3440 = _3057.roughness;\n    float _3441 = _3057.occlusion;\n    float3 _3442 = _3057.emission;\n    float _3443 = _3057.clearcoat;\n    float _3444 = _3057.clearcoat_roughness;\n    float3 _3445 = _3057.sheen_color;\n    float _3446 = _3057.sheen_roughness;\n    float _3447 = _3057.anisotropy;\n    float _3448 = _3057.anisotropy_rotation;\n    float _3449 = _3057.specular;\n    float _3450 = _3057.ior;\n    float3 _3451 = _3057.specular_color;\n    SurfaceInput _3418 = { fa_world_pos, _3397, fa_world_tangent, fa_uv, fa_vertex_color, _3049, gl_FrontFacing };\n    SurfaceInput param_2 = _3418;\n    Surface param_3 = _3057;\n    surface(param_2, param_3);\n    _3436 = param_3.albedo;\n    _3437 = param_3.alpha;\n    _3438 = param_3.normal;\n    _3439 = param_3.metallic;\n    _3440 = param_3.roughness;\n    _3441 = param_3.occlusion;\n    _3442 = param_3.emission;\n    _3443 = param_3.clearcoat;\n    _3444 = param_3.clearcoat_roughness;\n    _3445 = param_3.sheen_color;\n    _3446 = param_3.sheen_roughness;\n    _3447 = param_3.anisotropy;\n    _3448 = param_3.anisotropy_rotation;\n    _3449 = param_3.specular;\n    _3450 = param_3.ior;\n    _3451 = param_3.specular_color;\n    float3 result;\n    if (_466_fa_emissive.w > 0.5f)\n    {\n        result = _3436;\n    }\n    else\n    {\n        float3 _3078 = _3438;\n        float3 _3079 = normalize(_3078);\n        _3438 = _3079;\n        float3 param_4 = _3079;\n        SurfaceInput _3426 = { fa_world_pos, _3397, fa_world_tangent, fa_uv, fa_vertex_color, _3049, gl_FrontFacing };\n        SurfaceInput param_5 = _3426;\n        Surface _3517 = { _3436, _3437, _3438, _3439, _3440, _3441, _3442, _3443, _3444, _3445, _3446, _3447, _3448, _3449, _3450, _3451 };\n        Surface param_6 = _3517;\n        float3 param_7 = fa_indirect_diffuse(param_4);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _3098 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3098; ln++)\n        {\n            int param_8 = ln;\n            int _3111 = fa_cl_light(param_8);\n            bool _3114 = fa_lm.z > 0.5f;\n            bool _3120;\n            if (_3114)\n            {\n                int param_9 = _3111;\n                _3120 = fa_light_baked(param_9);\n            }\n            else\n            {\n                _3120 = _3114;\n            }\n            if (_3120)\n            {\n                continue;\n            }\n            int param_10 = _3111;\n            float3 param_11 = fa_world_pos;\n            float3 param_12 = _3397;\n            SurfaceInput _3434 = { fa_world_pos, _3397, fa_world_tangent, fa_uv, fa_vertex_color, _3049, gl_FrontFacing };\n            SurfaceInput param_13 = _3434;\n            Surface _3534 = { _3436, _3437, _3438, _3439, _3440, _3441, _3442, _3443, _3444, _3445, _3446, _3447, _3448, _3449, _3450, _3451 };\n            Surface param_14 = _3534;\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    float3 _3147 = result;\n    float3 _3148 = _3147 + _3442;\n    result = _3148;\n    float3 param_16 = _3148;\n    float3 param_17 = fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17);\n    bool _3157 = _466_fa_fog.w > 0.0f;\n    bool _3164;\n    if (!_3157)\n    {\n        _3164 = _466_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3164 = _3157;\n    }\n    if (_3164)\n    {\n        float3 _3173 = fa_world_pos - _466_fa_camera_pos.xyz;\n        float _3179 = dot(_3173, _466_fa_fog_c.xyz);\n        bool _3183 = _466_fa_fog_c.w > 0.5f;\n        float _3184;\n        if (_3183)\n        {\n            _3184 = _3179;\n        }\n        else\n        {\n            _3184 = length(_3173);\n        }\n        float _3196 = _3184 - _466_fa_fog_b.x;\n        if (_3196 > 0.0f)\n        {\n            float _3205 = _466_fa_fog.w * _3196;\n            float tau = _3205 * _3205;\n            if (_466_fa_fog_b.y > 0.0f)\n            {\n                float _3221;\n                if (_3183)\n                {\n                    _3221 = fa_world_pos.y - (_466_fa_fog_c.y * _3179);\n                }\n                else\n                {\n                    _3221 = _466_fa_camera_pos.y;\n                }\n                float _3242 = lerp(_3221, fa_world_pos.y, clamp(_466_fa_fog_b.x / _3184, 0.0f, 1.0f));\n                float _3246 = fa_world_pos.y - _3242;\n                float _3251 = _3242 - _466_fa_fog_b.z;\n                float _3256 = fa_world_pos.y - _466_fa_fog_b.z;\n                bool _3259 = _3251 <= 0.0f;\n                bool _3260 = !_3259;\n                bool _3266;\n                if (_3260)\n                {\n                    _3266 = _466_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3266 = _3259;\n                }\n                float _3267;\n                if (_3266)\n                {\n                    _3267 = _466_fa_fog_b.y;\n                }\n                else\n                {\n                    _3267 = _466_fa_fog_b.y * exp(-min(_466_fa_fog_b.w * _3251, 80.0f));\n                }\n                bool _3294;\n                if (_3260)\n                {\n                    _3294 = _466_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3294 = _3259;\n                }\n                float _3295;\n                if (_3294)\n                {\n                    _3295 = _466_fa_fog_b.y * _3251;\n                }\n                else\n                {\n                    _3295 = (_466_fa_fog_b.y * (1.0f - exp(-min(_466_fa_fog_b.w * _3251, 80.0f)))) / _466_fa_fog_b.w;\n                }\n                bool _3320 = _3256 <= 0.0f;\n                bool _3327;\n                if (!_3320)\n                {\n                    _3327 = _466_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3327 = _3320;\n                }\n                float _3328;\n                if (_3327)\n                {\n                    _3328 = _466_fa_fog_b.y * _3256;\n                }\n                else\n                {\n                    _3328 = (_466_fa_fog_b.y * (1.0f - exp(-min(_466_fa_fog_b.w * _3256, 80.0f)))) / _466_fa_fog_b.w;\n                }\n                float _3355;\n                if (abs(_3246) < 0.001000000047497451305389404296875f)\n                {\n                    _3355 = _3267;\n                }\n                else\n                {\n                    _3355 = (_3328 - _3295) / _3246;\n                }\n                tau += (_3196 * max(_3355, 0.0f));\n            }\n            result = lerp(result, _466_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _3437);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_466",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_702",
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213_fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213_fa_layers_a.x;\n    float _752 = _213_fa_layers_a.y;\n    float _755 = _213_fa_layers_a.z;\n    float _754 = _213_fa_layers_b.w;\n    float _757 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    Surface _776 = { _241.xyz, _241.w, _746, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _751, _752, _213_fa_layers_b.xyz, _754, _755, _213_fa_layers_a.w, _757, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _776;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _670 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _670;\n    SurfaceInput _678 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _678;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _413 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _413;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0f);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213_fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213_fa_layers_a.x;\n    float _752 = _213_fa_layers_a.y;\n    float _755 = _213_fa_layers_a.z;\n    float _754 = _213_fa_layers_b.w;\n    float _757 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    Surface _776 = { _241.xyz, _241.w, _746, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _751, _752, _213_fa_layers_b.xyz, _754, _755, _213_fa_layers_a.w, _757, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _776;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _670 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _670;\n    SurfaceInput _678 = { fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _678;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
