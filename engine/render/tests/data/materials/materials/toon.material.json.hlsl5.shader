{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b9137a7fd5249b4222bedebb6ca5e740fb7c4a348474dd42da5706fae9a2d4c0",
  "slang": "hlsl5",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _261 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _261;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_268, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _363_fa_camera_pos : packoffset(c0);\n    float4 _363_fa_ambient : packoffset(c1);\n    float4 _363_fa_base_color : packoffset(c2);\n    float4 _363_fa_emissive : packoffset(c3);\n    float4 _363_fa_model_emissive : packoffset(c4);\n    float4 _363_fa_pbr : packoffset(c5);\n    float4 _363_fa_maps : packoffset(c6);\n    float4 _363_fa_fog : packoffset(c7);\n    float4 _363_fa_fog_b : packoffset(c8);\n    float4 _363_fa_fog_c : packoffset(c9);\n    float4 _363_fa_counts : packoffset(c10);\n    float4 _363_fa_env_sky : packoffset(c11);\n    float4 _363_fa_env_horizon : packoffset(c12);\n    float4 _363_fa_time : packoffset(c13);\n    float4 _363_fa_cl_vpx : packoffset(c14);\n    float4 _363_fa_cl_vpy : packoffset(c15);\n    float4 _363_fa_cl_vpw : packoffset(c16);\n    float4 _363_fa_cl_fwd : packoffset(c17);\n    float4 _363_fa_cl_grid : packoffset(c18);\n    float4 _363_fa_cl_info : packoffset(c19);\n    float4 _363_fa_layers_a : packoffset(c20);\n    float4 _363_fa_layers_b : packoffset(c21);\n    float4 _363_fa_layers_c : packoffset(c22);\n    float4 _363_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _599_fa_shadow_mat[4] : packoffset(c0);\n    float4 _599_fa_shadow_rect[4] : packoffset(c16);\n    float4 _599_fa_shadow_info[4] : packoffset(c20);\n    float4 _599_fa_shadow_split : packoffset(c24);\n    float4 _599_fa_shadow_cfg : packoffset(c25);\n    float4 _599_fa_shadow_bias : packoffset(c26);\n    float4 _599_fa_shadow_eye : packoffset(c27);\n    float4 _599_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _1328_dark : packoffset(c0);\n    float _1328_fa_pad0 : packoffset(c0.y);\n    float _1328_fa_pad1 : packoffset(c0.z);\n    float _1328_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _368 = _363_fa_cl_info.x < 0.0f;\n    bool _375;\n    if (!_368)\n    {\n        _375 = _363_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _375 = _368;\n    }\n    bool _383;\n    if (!_375)\n    {\n        _383 = _363_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _383 = _375;\n    }\n    bool _390;\n    if (!_383)\n    {\n        _390 = _363_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _390 = _383;\n    }\n    bool _397;\n    if (!_390)\n    {\n        _397 = _363_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    if (_397)\n    {\n        return int2(0, 0);\n    }\n    float4 _407 = float4(world_pos, 1.0f);\n    float _414 = dot(_363_fa_cl_vpw, _407);\n    if (!(_414 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _436 = float2(dot(_363_fa_cl_vpx, _407), dot(_363_fa_cl_vpy, _407)) / _414.xx;\n    int _440 = int(_363_fa_cl_grid.x);\n    int _444 = int(_363_fa_cl_grid.y);\n    int param = (int(_363_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_363_fa_cl_fwd.xyz, world_pos) + _363_fa_cl_fwd.w, _363_fa_cl_grid.w) / _363_fa_cl_grid.w) * _363_fa_cl_grid.z)), 0, int(_363_fa_cl_info.y) - 1) * _444) + clamp(int(floor(((_436.y * 0.5f) + 0.5f) * _363_fa_cl_grid.y)), 0, _444 - 1)) * _440)) + clamp(int(floor(((_436.x * 0.5f) + 0.5f) * _363_fa_cl_grid.x)), 0, _440 - 1);\n    float4 _515 = fa_light_texel(param);\n    return int2(int(_515.x), int(_515.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_363_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1260 = fa_cluster_lookup(param);\n    fa_cl_slot = _1260.x;\n    fa_cl_local = _1260.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1389 = fa_linear_to_srgb(param);\n        c = _1389;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1397 = fa_srgb_to_linear(param_1);\n            c = _1397;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _144;\n    if (i.front_facing)\n    {\n        _144 = i.world_normal;\n    }\n    else\n    {\n        _144 = -i.world_normal;\n    }\n    float3 _168 = normalize(i.world_tangent.xyz - (_144 * dot(_144, i.world_tangent.xyz)));\n    float3 _196 = normalize(((_168 * m.x) + ((cross(_144, _168) * i.world_tangent.w) * m.y)) + (_144 * m.z));\n    float3 _199;\n    if (i.front_facing)\n    {\n        _199 = _196;\n    }\n    else\n    {\n        _199 = -_196;\n    }\n    return _199;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _363_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1428 = fa_tex_fix(param_2, param_3);\n    float4 _2315 = base_t;\n    _2315.x = _1428.x;\n    _2315.y = _1428.y;\n    _2315.z = _1428.z;\n    base_t = _2315;\n    float4 _1442 = (_2315 * _363_fa_base_color) * i.vertex_color;\n    float3 _2262 = i.world_normal;\n    if (_363_fa_maps.z > 0.5f)\n    {\n        float param_4 = _363_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1474 = fa_tex_fix(param_6, param_7);\n        float3 _1478 = (_1474 * 2.0f) - 1.0f.xxx;\n        float2 _1483 = _1478.xy * _363_fa_maps.x;\n        float3 _2323 = _1478;\n        _2323.x = _1483.x;\n        _2323.y = _1483.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2323;\n        _2262 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _363_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1512 = fa_tex_fix(param_12, param_13);\n    float4 _2326 = mrt;\n    _2326.x = _1512.x;\n    _2326.y = _1512.y;\n    _2326.z = _1512.z;\n    mrt = _2326;\n    float4 _1541 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _363_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _1541.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1553 = fa_tex_fix(param_16, param_17);\n    float param_18 = _363_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1583 = fa_tex_fix(param_20, param_21);\n    float _2267 = _363_fa_layers_a.x;\n    float _2268 = _363_fa_layers_a.y;\n    float _2271 = _363_fa_layers_a.z;\n    float _2270 = _363_fa_layers_b.w;\n    float _2273 = _363_fa_layers_c.x;\n    if (_363_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_363_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _2267 *= _1553.y;\n            _2268 *= _1553.z;\n            _2270 *= _1541.w;\n        }\n        if (_363_fa_layers_c.z > 1.5f)\n        {\n            _2271 *= mrt.x;\n            _2273 *= mrt.w;\n        }\n    }\n    Surface _2292 = { _1442.xyz, _1442.w, _2262, clamp(_363_fa_pbr.x * _1512.z, 0.0f, 1.0f), clamp(_363_fa_pbr.y * _1512.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_363_fa_maps.y * (_1553.x - 1.0f)), _363_fa_emissive.xyz + (_363_fa_model_emissive.xyz * _1583), _2267, _2268, _363_fa_layers_b.xyz, _2270, _2271, _363_fa_layers_a.w, _2273, _363_fa_layers_c.y, _363_fa_layers_d.xyz };\n    return _2292;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_363_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _363_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_363_fa_cl_info.x) + int(_363_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _236 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _242 = fa_light_texel(param_1);\n    float _245 = _242.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _252 = _245 < 0.5f;\n    float3 l;\n    if (_252)\n    {\n        l = normalize(_236.xyz);\n    }\n    else\n    {\n        float3 _264 = _236.xyz - world_pos;\n        float _266 = length(_264);\n        dist = _266;\n        l = _264 / max(_266, 9.9999997473787516355514526367188e-05f).xxx;\n        float _281 = _266 / max(_236.w, 0.001000000047497451305389404296875f);\n        float _287 = clamp(1.0f - (_281 * _281), 0.0f, 1.0f);\n        atten = _287 * _287;\n        if (_245 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _301 = fa_light_texel(param_2);\n            float _311 = _301.w;\n            int param_3 = (li * 4) + 3;\n            float4 _318 = fa_light_texel(param_3);\n            float _319 = _318.x;\n            float cos_inner = _319;\n            if (_319 > 1.5f)\n            {\n                cos_inner = lerp(_311, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_311, cos_inner, dot(-l, normalize(_301.xyz)));\n        }\n    }\n    int _349;\n    if (_252)\n    {\n        _349 = 0;\n    }\n    else\n    {\n        _349 = (_245 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2240 = { l, _242.xyz * atten, atten, 1.0f, dist, _349 };\n    return _2240;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _589;\n    if (i == 0)\n    {\n        _589 = _599_fa_shadow_split.x;\n    }\n    else\n    {\n        float _605;\n        if (i == 1)\n        {\n            _605 = _599_fa_shadow_split.y;\n        }\n        else\n        {\n            float _613;\n            if (i == 2)\n            {\n                _613 = _599_fa_shadow_split.z;\n            }\n            else\n            {\n                _613 = _599_fa_shadow_split.w;\n            }\n            _605 = _613;\n        }\n        _589 = _605;\n    }\n    return _589;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _577 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_577), sin(_577)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _651 = max(_599_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _656 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _662 = sqrt(1.0f - (_656 * _656));\n    float _670 = min(_662 / max(_656, 0.20000000298023223876953125f), 4.0f);\n    float _675;\n    if (_599_fa_shadow_bias.y > 0.0f)\n    {\n        _675 = _599_fa_shadow_bias.y;\n    }\n    else\n    {\n        _675 = 1.5f * _599_fa_shadow_info[ci].x;\n    }\n    float4 _700 = mul(float4(world + (n * (_675 * _662)), 1.0f), _599_fa_shadow_mat[ci]);\n    float _707 = _700.x;\n    bool _710 = _707 < _599_fa_shadow_rect[ci].x;\n    bool _719;\n    if (!_710)\n    {\n        _719 = _707 > _599_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _719 = _710;\n    }\n    bool _728;\n    if (!_719)\n    {\n        _728 = _700.y < _599_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _728 = _719;\n    }\n    bool _737;\n    if (!_728)\n    {\n        _737 = _700.y > _599_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _737 = _728;\n    }\n    bool _744;\n    if (!_737)\n    {\n        _744 = _700.z > 1.0f;\n    }\n    else\n    {\n        _744 = _737;\n    }\n    if (_744)\n    {\n        return -1.0f;\n    }\n    float _753;\n    if (_599_fa_shadow_bias.x > 0.0f)\n    {\n        _753 = _599_fa_shadow_bias.x;\n    }\n    else\n    {\n        _753 = 1.5f * _599_fa_shadow_info[ci].x;\n    }\n    float _772 = _700.z - ((_753 * (1.0f + (0.5f * _670))) / _651);\n    float _781 = ((_599_fa_shadow_info[ci].x * min(_670, 3.0f)) * 0.5f) / _651;\n    int _790 = int(_599_fa_shadow_cfg.z + 0.5f);\n    if (_790 == 1)\n    {\n        float2 param = _700.xy;\n        float4 param_1 = _599_fa_shadow_rect[ci];\n        float _801 = fa_shadow_depth(param, param_1);\n        return float(_772 <= _801);\n    }\n    float _808 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _811 = _790 == 2;\n    if (_811)\n    {\n        float _825 = clamp(((_599_fa_shadow_cfg.w * _651) * 0.25f) / _599_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _808;\n            float2 _844 = fa_shadow_vogel(param_2, param_3, param_4) * _825;\n            float2 param_5 = _700.xy + (_844 * _599_fa_shadow_bias.zw);\n            float4 param_6 = _599_fa_shadow_rect[ci];\n            float _855 = fa_shadow_depth(param_5, param_6);\n            if (_855 < (_772 - (length(_844) * _781)))\n            {\n                sum += _855;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_772 - (sum / cnt), 0.0f) * _651) * _599_fa_shadow_cfg.w) / _599_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _899 = _811 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _899; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _899;\n        float param_9 = _808;\n        float2 _918 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _700.xy + (_918 * _599_fa_shadow_bias.zw);\n        float4 param_11 = _599_fa_shadow_rect[ci];\n        float _929 = fa_shadow_depth(param_10, param_11);\n        lit += float((_772 - (length(_918) * _781)) <= _929);\n    }\n    return lit / float(_899);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_363_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _959 = int(_599_fa_shadow_cfg.x + 0.5f);\n    if (_959 < 1)\n    {\n        return 1.0f;\n    }\n    float _975 = dot(world - _599_fa_shadow_eye.xyz, _599_fa_shadow_fwd.xyz);\n    int param = _959 - 1;\n    if (_975 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _987 = _959 > 1;\n    bool _994;\n    if (_987)\n    {\n        _994 = _975 > _599_fa_shadow_split.x;\n    }\n    else\n    {\n        _994 = _987;\n    }\n    if (_994)\n    {\n        ci = 1;\n    }\n    bool _998 = _959 > 2;\n    bool _1005;\n    if (_998)\n    {\n        _1005 = _975 > _599_fa_shadow_split.y;\n    }\n    else\n    {\n        _1005 = _998;\n    }\n    if (_1005)\n    {\n        ci = 2;\n    }\n    bool _1009 = _959 > 3;\n    bool _1016;\n    if (_1009)\n    {\n        _1016 = _975 > _599_fa_shadow_split.z;\n    }\n    else\n    {\n        _1016 = _1009;\n    }\n    if (_1016)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _959)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1042 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1042;\n        if (_1042 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_599_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1067;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1067 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1067 = _599_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1086 = _599_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1067, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1097 = clamp((_975 - (fa_shadow_split_at(param_7) - _1086)) / _1086, 0.0f, 1.0f);\n        if (_1097 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _959)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1118 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1118;\n                if (_1118 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1097);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1288 = fa_light_sample(param, param_1);\n    float3 _2247 = _1288.direction;\n    float3 _2242 = _1288.color;\n    float _2244 = _1288.shadow;\n    int _2252 = _1288.type;\n    if ((_2252 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2247;\n        float _1302 = fa_shadow_factor(param_2, param_3);\n        _2244 = _1302;\n        _2242 *= _1302;\n    }\n    LightSample _2259 = { _2247, _2242, _1288.attenuation, _2244, _1288._distance, _2252 };\n    return _2259;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _1322;\n    if (dot(s.normal, l.direction) > 0.5f)\n    {\n        _1322 = 1.0f;\n    }\n    else\n    {\n        _1322 = _1328_dark;\n    }\n    return (s.albedo * l.color) * _1322;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_599_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1142 = int(_599_fa_shadow_cfg.x + 0.5f);\n    float _1152 = dot(world - _599_fa_shadow_eye.xyz, _599_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1157 = _1142 > 0;\n    bool _1166;\n    if (_1157)\n    {\n        int param = _1142 - 1;\n        _1166 = _1152 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1166 = _1157;\n    }\n    if (_1166)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1173 = _1142 > 1;\n        bool _1180;\n        if (_1173)\n        {\n            _1180 = _1152 > _599_fa_shadow_split.x;\n        }\n        else\n        {\n            _1180 = _1173;\n        }\n        if (_1180)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1186 = _1142 > 2;\n        bool _1193;\n        if (_1186)\n        {\n            _1193 = _1152 > _599_fa_shadow_split.y;\n        }\n        else\n        {\n            _1193 = _1186;\n        }\n        if (_1193)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1199 = _1142 > 3;\n        bool _1206;\n        if (_1199)\n        {\n            _1206 = _1152 > _599_fa_shadow_split.z;\n        }\n        else\n        {\n            _1206 = _1199;\n        }\n        if (_1206)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2096 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2096 = -_2096;\n    }\n    float3 _1709 = normalize(_363_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2109 = { fa_world_pos, _2096, fa_world_tangent, fa_uv, fa_vertex_color, _1709, gl_FrontFacing };\n    SurfaceInput param_1 = _2109;\n    Surface _1717 = fa_standard_surface(param_1);\n    float3 _2127 = _1717.albedo;\n    float _2128 = _1717.alpha;\n    float3 _2129 = _1717.normal;\n    float _2130 = _1717.metallic;\n    float _2131 = _1717.roughness;\n    float _2132 = _1717.occlusion;\n    float3 _2133 = _1717.emission;\n    float _2134 = _1717.clearcoat;\n    float _2135 = _1717.clearcoat_roughness;\n    float3 _2136 = _1717.sheen_color;\n    float _2137 = _1717.sheen_roughness;\n    float _2138 = _1717.anisotropy;\n    float _2139 = _1717.anisotropy_rotation;\n    float _2140 = _1717.specular;\n    float _2141 = _1717.ior;\n    float3 _2142 = _1717.specular_color;\n    SurfaceInput _2117 = { fa_world_pos, _2096, fa_world_tangent, fa_uv, fa_vertex_color, _1709, gl_FrontFacing };\n    SurfaceInput param_2 = _2117;\n    Surface param_3 = _1717;\n    surface(param_2, param_3);\n    _2127 = param_3.albedo;\n    _2128 = param_3.alpha;\n    _2129 = param_3.normal;\n    _2130 = param_3.metallic;\n    _2131 = param_3.roughness;\n    _2132 = param_3.occlusion;\n    _2133 = param_3.emission;\n    _2134 = param_3.clearcoat;\n    _2135 = param_3.clearcoat_roughness;\n    _2136 = param_3.sheen_color;\n    _2137 = param_3.sheen_roughness;\n    _2138 = param_3.anisotropy;\n    _2139 = param_3.anisotropy_rotation;\n    _2140 = param_3.specular;\n    _2141 = param_3.ior;\n    _2142 = param_3.specular_color;\n    float3 result;\n    if (_363_fa_emissive.w > 0.5f)\n    {\n        result = _2127;\n    }\n    else\n    {\n        float3 _1738 = _2129;\n        float3 _1739 = normalize(_1738);\n        _2129 = _1739;\n        float3 param_4 = _1739;\n        float3 lit = (fa_ambient_light(param_4) * _2127) * _2132;\n        int _1758 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1758; ln++)\n        {\n            int param_5 = ln;\n            int param_6 = fa_cl_light(param_5);\n            float3 param_7 = fa_world_pos;\n            float3 param_8 = _2096;\n            SurfaceInput _2125 = { fa_world_pos, _2096, fa_world_tangent, fa_uv, fa_vertex_color, _1709, gl_FrontFacing };\n            SurfaceInput param_9 = _2125;\n            Surface _2208 = { _2127, _2128, _2129, _2130, _2131, _2132, _2133, _2134, _2135, _2136, _2137, _2138, _2139, _2140, _2141, _2142 };\n            Surface param_10 = _2208;\n            LightSample param_11 = fa_light_shadowed(param_6, param_7, param_8);\n            lit += light(param_9, param_10, param_11);\n        }\n        result = lit;\n    }\n    float3 _1795 = result;\n    float3 _1796 = _1795 + _2133;\n    result = _1796;\n    float3 param_12 = _1796;\n    float3 param_13 = fa_world_pos;\n    result = fa_shadow_debug(param_12, param_13);\n    bool _1805 = _363_fa_fog.w > 0.0f;\n    bool _1812;\n    if (!_1805)\n    {\n        _1812 = _363_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1812 = _1805;\n    }\n    if (_1812)\n    {\n        float3 _1821 = fa_world_pos - _363_fa_camera_pos.xyz;\n        float _1827 = dot(_1821, _363_fa_fog_c.xyz);\n        bool _1831 = _363_fa_fog_c.w > 0.5f;\n        float _1832;\n        if (_1831)\n        {\n            _1832 = _1827;\n        }\n        else\n        {\n            _1832 = length(_1821);\n        }\n        float _1844 = _1832 - _363_fa_fog_b.x;\n        if (_1844 > 0.0f)\n        {\n            float _1853 = _363_fa_fog.w * _1844;\n            float tau = _1853 * _1853;\n            if (_363_fa_fog_b.y > 0.0f)\n            {\n                float _1869;\n                if (_1831)\n                {\n                    _1869 = fa_world_pos.y - (_363_fa_fog_c.y * _1827);\n                }\n                else\n                {\n                    _1869 = _363_fa_camera_pos.y;\n                }\n                float _1890 = lerp(_1869, fa_world_pos.y, clamp(_363_fa_fog_b.x / _1832, 0.0f, 1.0f));\n                float _1894 = fa_world_pos.y - _1890;\n                float _1899 = _1890 - _363_fa_fog_b.z;\n                float _1904 = fa_world_pos.y - _363_fa_fog_b.z;\n                bool _1907 = _1899 <= 0.0f;\n                bool _1908 = !_1907;\n                bool _1914;\n                if (_1908)\n                {\n                    _1914 = _363_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1914 = _1907;\n                }\n                float _1915;\n                if (_1914)\n                {\n                    _1915 = _363_fa_fog_b.y;\n                }\n                else\n                {\n                    _1915 = _363_fa_fog_b.y * exp(-min(_363_fa_fog_b.w * _1899, 80.0f));\n                }\n                bool _1942;\n                if (_1908)\n                {\n                    _1942 = _363_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1942 = _1907;\n                }\n                float _1943;\n                if (_1942)\n                {\n                    _1943 = _363_fa_fog_b.y * _1899;\n                }\n                else\n                {\n                    _1943 = (_363_fa_fog_b.y * (1.0f - exp(-min(_363_fa_fog_b.w * _1899, 80.0f)))) / _363_fa_fog_b.w;\n                }\n                bool _1968 = _1904 <= 0.0f;\n                bool _1975;\n                if (!_1968)\n                {\n                    _1975 = _363_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1975 = _1968;\n                }\n                float _1976;\n                if (_1975)\n                {\n                    _1976 = _363_fa_fog_b.y * _1904;\n                }\n                else\n                {\n                    _1976 = (_363_fa_fog_b.y * (1.0f - exp(-min(_363_fa_fog_b.w * _1904, 80.0f)))) / _363_fa_fog_b.w;\n                }\n                float _2003;\n                if (abs(_1894) < 0.001000000047497451305389404296875f)\n                {\n                    _2003 = _1915;\n                }\n                else\n                {\n                    _2003 = (_1976 - _1943) / _1894;\n                }\n                tau += (_1844 * max(_2003, 0.0f));\n            }\n            result = lerp(result, _363_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2128);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_363",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_599",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1328",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _382 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _382;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_389, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _363_fa_camera_pos : packoffset(c0);\n    float4 _363_fa_ambient : packoffset(c1);\n    float4 _363_fa_base_color : packoffset(c2);\n    float4 _363_fa_emissive : packoffset(c3);\n    float4 _363_fa_model_emissive : packoffset(c4);\n    float4 _363_fa_pbr : packoffset(c5);\n    float4 _363_fa_maps : packoffset(c6);\n    float4 _363_fa_fog : packoffset(c7);\n    float4 _363_fa_fog_b : packoffset(c8);\n    float4 _363_fa_fog_c : packoffset(c9);\n    float4 _363_fa_counts : packoffset(c10);\n    float4 _363_fa_env_sky : packoffset(c11);\n    float4 _363_fa_env_horizon : packoffset(c12);\n    float4 _363_fa_time : packoffset(c13);\n    float4 _363_fa_cl_vpx : packoffset(c14);\n    float4 _363_fa_cl_vpy : packoffset(c15);\n    float4 _363_fa_cl_vpw : packoffset(c16);\n    float4 _363_fa_cl_fwd : packoffset(c17);\n    float4 _363_fa_cl_grid : packoffset(c18);\n    float4 _363_fa_cl_info : packoffset(c19);\n    float4 _363_fa_layers_a : packoffset(c20);\n    float4 _363_fa_layers_b : packoffset(c21);\n    float4 _363_fa_layers_c : packoffset(c22);\n    float4 _363_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _599_fa_shadow_mat[4] : packoffset(c0);\n    float4 _599_fa_shadow_rect[4] : packoffset(c16);\n    float4 _599_fa_shadow_info[4] : packoffset(c20);\n    float4 _599_fa_shadow_split : packoffset(c24);\n    float4 _599_fa_shadow_cfg : packoffset(c25);\n    float4 _599_fa_shadow_bias : packoffset(c26);\n    float4 _599_fa_shadow_eye : packoffset(c27);\n    float4 _599_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _1328_dark : packoffset(c0);\n    float _1328_fa_pad0 : packoffset(c0.y);\n    float _1328_fa_pad1 : packoffset(c0.z);\n    float _1328_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _368 = _363_fa_cl_info.x < 0.0f;\n    bool _375;\n    if (!_368)\n    {\n        _375 = _363_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _375 = _368;\n    }\n    bool _383;\n    if (!_375)\n    {\n        _383 = _363_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _383 = _375;\n    }\n    bool _390;\n    if (!_383)\n    {\n        _390 = _363_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _390 = _383;\n    }\n    bool _397;\n    if (!_390)\n    {\n        _397 = _363_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    if (_397)\n    {\n        return int2(0, 0);\n    }\n    float4 _407 = float4(world_pos, 1.0f);\n    float _414 = dot(_363_fa_cl_vpw, _407);\n    if (!(_414 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _436 = float2(dot(_363_fa_cl_vpx, _407), dot(_363_fa_cl_vpy, _407)) / _414.xx;\n    int _440 = int(_363_fa_cl_grid.x);\n    int _444 = int(_363_fa_cl_grid.y);\n    int param = (int(_363_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_363_fa_cl_fwd.xyz, world_pos) + _363_fa_cl_fwd.w, _363_fa_cl_grid.w) / _363_fa_cl_grid.w) * _363_fa_cl_grid.z)), 0, int(_363_fa_cl_info.y) - 1) * _444) + clamp(int(floor(((_436.y * 0.5f) + 0.5f) * _363_fa_cl_grid.y)), 0, _444 - 1)) * _440)) + clamp(int(floor(((_436.x * 0.5f) + 0.5f) * _363_fa_cl_grid.x)), 0, _440 - 1);\n    float4 _515 = fa_light_texel(param);\n    return int2(int(_515.x), int(_515.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_363_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1260 = fa_cluster_lookup(param);\n    fa_cl_slot = _1260.x;\n    fa_cl_local = _1260.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1389 = fa_linear_to_srgb(param);\n        c = _1389;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1397 = fa_srgb_to_linear(param_1);\n            c = _1397;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _144;\n    if (i.front_facing)\n    {\n        _144 = i.world_normal;\n    }\n    else\n    {\n        _144 = -i.world_normal;\n    }\n    float3 _168 = normalize(i.world_tangent.xyz - (_144 * dot(_144, i.world_tangent.xyz)));\n    float3 _196 = normalize(((_168 * m.x) + ((cross(_144, _168) * i.world_tangent.w) * m.y)) + (_144 * m.z));\n    float3 _199;\n    if (i.front_facing)\n    {\n        _199 = _196;\n    }\n    else\n    {\n        _199 = -_196;\n    }\n    return _199;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _363_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1428 = fa_tex_fix(param_2, param_3);\n    float4 _2315 = base_t;\n    _2315.x = _1428.x;\n    _2315.y = _1428.y;\n    _2315.z = _1428.z;\n    base_t = _2315;\n    float4 _1442 = (_2315 * _363_fa_base_color) * i.vertex_color;\n    float3 _2262 = i.world_normal;\n    if (_363_fa_maps.z > 0.5f)\n    {\n        float param_4 = _363_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1474 = fa_tex_fix(param_6, param_7);\n        float3 _1478 = (_1474 * 2.0f) - 1.0f.xxx;\n        float2 _1483 = _1478.xy * _363_fa_maps.x;\n        float3 _2323 = _1478;\n        _2323.x = _1483.x;\n        _2323.y = _1483.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2323;\n        _2262 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _363_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1512 = fa_tex_fix(param_12, param_13);\n    float4 _2326 = mrt;\n    _2326.x = _1512.x;\n    _2326.y = _1512.y;\n    _2326.z = _1512.z;\n    mrt = _2326;\n    float4 _1541 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _363_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _1541.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1553 = fa_tex_fix(param_16, param_17);\n    float param_18 = _363_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1583 = fa_tex_fix(param_20, param_21);\n    float _2267 = _363_fa_layers_a.x;\n    float _2268 = _363_fa_layers_a.y;\n    float _2271 = _363_fa_layers_a.z;\n    float _2270 = _363_fa_layers_b.w;\n    float _2273 = _363_fa_layers_c.x;\n    if (_363_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_363_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _2267 *= _1553.y;\n            _2268 *= _1553.z;\n            _2270 *= _1541.w;\n        }\n        if (_363_fa_layers_c.z > 1.5f)\n        {\n            _2271 *= mrt.x;\n            _2273 *= mrt.w;\n        }\n    }\n    Surface _2292 = { _1442.xyz, _1442.w, _2262, clamp(_363_fa_pbr.x * _1512.z, 0.0f, 1.0f), clamp(_363_fa_pbr.y * _1512.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_363_fa_maps.y * (_1553.x - 1.0f)), _363_fa_emissive.xyz + (_363_fa_model_emissive.xyz * _1583), _2267, _2268, _363_fa_layers_b.xyz, _2270, _2271, _363_fa_layers_a.w, _2273, _363_fa_layers_c.y, _363_fa_layers_d.xyz };\n    return _2292;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_363_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _363_fa_ambient.xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_363_fa_cl_info.x) + int(_363_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _236 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _242 = fa_light_texel(param_1);\n    float _245 = _242.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _252 = _245 < 0.5f;\n    float3 l;\n    if (_252)\n    {\n        l = normalize(_236.xyz);\n    }\n    else\n    {\n        float3 _264 = _236.xyz - world_pos;\n        float _266 = length(_264);\n        dist = _266;\n        l = _264 / max(_266, 9.9999997473787516355514526367188e-05f).xxx;\n        float _281 = _266 / max(_236.w, 0.001000000047497451305389404296875f);\n        float _287 = clamp(1.0f - (_281 * _281), 0.0f, 1.0f);\n        atten = _287 * _287;\n        if (_245 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _301 = fa_light_texel(param_2);\n            float _311 = _301.w;\n            int param_3 = (li * 4) + 3;\n            float4 _318 = fa_light_texel(param_3);\n            float _319 = _318.x;\n            float cos_inner = _319;\n            if (_319 > 1.5f)\n            {\n                cos_inner = lerp(_311, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_311, cos_inner, dot(-l, normalize(_301.xyz)));\n        }\n    }\n    int _349;\n    if (_252)\n    {\n        _349 = 0;\n    }\n    else\n    {\n        _349 = (_245 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2240 = { l, _242.xyz * atten, atten, 1.0f, dist, _349 };\n    return _2240;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _589;\n    if (i == 0)\n    {\n        _589 = _599_fa_shadow_split.x;\n    }\n    else\n    {\n        float _605;\n        if (i == 1)\n        {\n            _605 = _599_fa_shadow_split.y;\n        }\n        else\n        {\n            float _613;\n            if (i == 2)\n            {\n                _613 = _599_fa_shadow_split.z;\n            }\n            else\n            {\n                _613 = _599_fa_shadow_split.w;\n            }\n            _605 = _613;\n        }\n        _589 = _605;\n    }\n    return _589;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _577 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_577), sin(_577)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _651 = max(_599_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _656 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _662 = sqrt(1.0f - (_656 * _656));\n    float _670 = min(_662 / max(_656, 0.20000000298023223876953125f), 4.0f);\n    float _675;\n    if (_599_fa_shadow_bias.y > 0.0f)\n    {\n        _675 = _599_fa_shadow_bias.y;\n    }\n    else\n    {\n        _675 = 1.5f * _599_fa_shadow_info[ci].x;\n    }\n    float4 _700 = mul(float4(world + (n * (_675 * _662)), 1.0f), _599_fa_shadow_mat[ci]);\n    float _707 = _700.x;\n    bool _710 = _707 < _599_fa_shadow_rect[ci].x;\n    bool _719;\n    if (!_710)\n    {\n        _719 = _707 > _599_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _719 = _710;\n    }\n    bool _728;\n    if (!_719)\n    {\n        _728 = _700.y < _599_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _728 = _719;\n    }\n    bool _737;\n    if (!_728)\n    {\n        _737 = _700.y > _599_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _737 = _728;\n    }\n    bool _744;\n    if (!_737)\n    {\n        _744 = _700.z > 1.0f;\n    }\n    else\n    {\n        _744 = _737;\n    }\n    if (_744)\n    {\n        return -1.0f;\n    }\n    float _753;\n    if (_599_fa_shadow_bias.x > 0.0f)\n    {\n        _753 = _599_fa_shadow_bias.x;\n    }\n    else\n    {\n        _753 = 1.5f * _599_fa_shadow_info[ci].x;\n    }\n    float _772 = _700.z - ((_753 * (1.0f + (0.5f * _670))) / _651);\n    float _781 = ((_599_fa_shadow_info[ci].x * min(_670, 3.0f)) * 0.5f) / _651;\n    int _790 = int(_599_fa_shadow_cfg.z + 0.5f);\n    if (_790 == 1)\n    {\n        float2 param = _700.xy;\n        float4 param_1 = _599_fa_shadow_rect[ci];\n        float _801 = fa_shadow_depth(param, param_1);\n        return float(_772 <= _801);\n    }\n    float _808 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _811 = _790 == 2;\n    if (_811)\n    {\n        float _825 = clamp(((_599_fa_shadow_cfg.w * _651) * 0.25f) / _599_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _808;\n            float2 _844 = fa_shadow_vogel(param_2, param_3, param_4) * _825;\n            float2 param_5 = _700.xy + (_844 * _599_fa_shadow_bias.zw);\n            float4 param_6 = _599_fa_shadow_rect[ci];\n            float _855 = fa_shadow_depth(param_5, param_6);\n            if (_855 < (_772 - (length(_844) * _781)))\n            {\n                sum += _855;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_772 - (sum / cnt), 0.0f) * _651) * _599_fa_shadow_cfg.w) / _599_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _899 = _811 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _899; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _899;\n        float param_9 = _808;\n        float2 _918 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _700.xy + (_918 * _599_fa_shadow_bias.zw);\n        float4 param_11 = _599_fa_shadow_rect[ci];\n        float _929 = fa_shadow_depth(param_10, param_11);\n        lit += float((_772 - (length(_918) * _781)) <= _929);\n    }\n    return lit / float(_899);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_363_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _959 = int(_599_fa_shadow_cfg.x + 0.5f);\n    if (_959 < 1)\n    {\n        return 1.0f;\n    }\n    float _975 = dot(world - _599_fa_shadow_eye.xyz, _599_fa_shadow_fwd.xyz);\n    int param = _959 - 1;\n    if (_975 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _987 = _959 > 1;\n    bool _994;\n    if (_987)\n    {\n        _994 = _975 > _599_fa_shadow_split.x;\n    }\n    else\n    {\n        _994 = _987;\n    }\n    if (_994)\n    {\n        ci = 1;\n    }\n    bool _998 = _959 > 2;\n    bool _1005;\n    if (_998)\n    {\n        _1005 = _975 > _599_fa_shadow_split.y;\n    }\n    else\n    {\n        _1005 = _998;\n    }\n    if (_1005)\n    {\n        ci = 2;\n    }\n    bool _1009 = _959 > 3;\n    bool _1016;\n    if (_1009)\n    {\n        _1016 = _975 > _599_fa_shadow_split.z;\n    }\n    else\n    {\n        _1016 = _1009;\n    }\n    if (_1016)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _959)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1042 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1042;\n        if (_1042 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_599_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1067;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1067 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1067 = _599_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1086 = _599_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1067, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1097 = clamp((_975 - (fa_shadow_split_at(param_7) - _1086)) / _1086, 0.0f, 1.0f);\n        if (_1097 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _959)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1118 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1118;\n                if (_1118 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1097);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1288 = fa_light_sample(param, param_1);\n    float3 _2247 = _1288.direction;\n    float3 _2242 = _1288.color;\n    float _2244 = _1288.shadow;\n    int _2252 = _1288.type;\n    if ((_2252 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2247;\n        float _1302 = fa_shadow_factor(param_2, param_3);\n        _2244 = _1302;\n        _2242 *= _1302;\n    }\n    LightSample _2259 = { _2247, _2242, _1288.attenuation, _2244, _1288._distance, _2252 };\n    return _2259;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _1322;\n    if (dot(s.normal, l.direction) > 0.5f)\n    {\n        _1322 = 1.0f;\n    }\n    else\n    {\n        _1322 = _1328_dark;\n    }\n    return (s.albedo * l.color) * _1322;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_599_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1142 = int(_599_fa_shadow_cfg.x + 0.5f);\n    float _1152 = dot(world - _599_fa_shadow_eye.xyz, _599_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1157 = _1142 > 0;\n    bool _1166;\n    if (_1157)\n    {\n        int param = _1142 - 1;\n        _1166 = _1152 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1166 = _1157;\n    }\n    if (_1166)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1173 = _1142 > 1;\n        bool _1180;\n        if (_1173)\n        {\n            _1180 = _1152 > _599_fa_shadow_split.x;\n        }\n        else\n        {\n            _1180 = _1173;\n        }\n        if (_1180)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1186 = _1142 > 2;\n        bool _1193;\n        if (_1186)\n        {\n            _1193 = _1152 > _599_fa_shadow_split.y;\n        }\n        else\n        {\n            _1193 = _1186;\n        }\n        if (_1193)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1199 = _1142 > 3;\n        bool _1206;\n        if (_1199)\n        {\n            _1206 = _1152 > _599_fa_shadow_split.z;\n        }\n        else\n        {\n            _1206 = _1199;\n        }\n        if (_1206)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2096 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2096 = -_2096;\n    }\n    float3 _1709 = normalize(_363_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2109 = { fa_world_pos, _2096, fa_world_tangent, fa_uv, fa_vertex_color, _1709, gl_FrontFacing };\n    SurfaceInput param_1 = _2109;\n    Surface _1717 = fa_standard_surface(param_1);\n    float3 _2127 = _1717.albedo;\n    float _2128 = _1717.alpha;\n    float3 _2129 = _1717.normal;\n    float _2130 = _1717.metallic;\n    float _2131 = _1717.roughness;\n    float _2132 = _1717.occlusion;\n    float3 _2133 = _1717.emission;\n    float _2134 = _1717.clearcoat;\n    float _2135 = _1717.clearcoat_roughness;\n    float3 _2136 = _1717.sheen_color;\n    float _2137 = _1717.sheen_roughness;\n    float _2138 = _1717.anisotropy;\n    float _2139 = _1717.anisotropy_rotation;\n    float _2140 = _1717.specular;\n    float _2141 = _1717.ior;\n    float3 _2142 = _1717.specular_color;\n    SurfaceInput _2117 = { fa_world_pos, _2096, fa_world_tangent, fa_uv, fa_vertex_color, _1709, gl_FrontFacing };\n    SurfaceInput param_2 = _2117;\n    Surface param_3 = _1717;\n    surface(param_2, param_3);\n    _2127 = param_3.albedo;\n    _2128 = param_3.alpha;\n    _2129 = param_3.normal;\n    _2130 = param_3.metallic;\n    _2131 = param_3.roughness;\n    _2132 = param_3.occlusion;\n    _2133 = param_3.emission;\n    _2134 = param_3.clearcoat;\n    _2135 = param_3.clearcoat_roughness;\n    _2136 = param_3.sheen_color;\n    _2137 = param_3.sheen_roughness;\n    _2138 = param_3.anisotropy;\n    _2139 = param_3.anisotropy_rotation;\n    _2140 = param_3.specular;\n    _2141 = param_3.ior;\n    _2142 = param_3.specular_color;\n    float3 result;\n    if (_363_fa_emissive.w > 0.5f)\n    {\n        result = _2127;\n    }\n    else\n    {\n        float3 _1738 = _2129;\n        float3 _1739 = normalize(_1738);\n        _2129 = _1739;\n        float3 param_4 = _1739;\n        float3 lit = (fa_ambient_light(param_4) * _2127) * _2132;\n        int _1758 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1758; ln++)\n        {\n            int param_5 = ln;\n            int param_6 = fa_cl_light(param_5);\n            float3 param_7 = fa_world_pos;\n            float3 param_8 = _2096;\n            SurfaceInput _2125 = { fa_world_pos, _2096, fa_world_tangent, fa_uv, fa_vertex_color, _1709, gl_FrontFacing };\n            SurfaceInput param_9 = _2125;\n            Surface _2208 = { _2127, _2128, _2129, _2130, _2131, _2132, _2133, _2134, _2135, _2136, _2137, _2138, _2139, _2140, _2141, _2142 };\n            Surface param_10 = _2208;\n            LightSample param_11 = fa_light_shadowed(param_6, param_7, param_8);\n            lit += light(param_9, param_10, param_11);\n        }\n        result = lit;\n    }\n    float3 _1795 = result;\n    float3 _1796 = _1795 + _2133;\n    result = _1796;\n    float3 param_12 = _1796;\n    float3 param_13 = fa_world_pos;\n    result = fa_shadow_debug(param_12, param_13);\n    bool _1805 = _363_fa_fog.w > 0.0f;\n    bool _1812;\n    if (!_1805)\n    {\n        _1812 = _363_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1812 = _1805;\n    }\n    if (_1812)\n    {\n        float3 _1821 = fa_world_pos - _363_fa_camera_pos.xyz;\n        float _1827 = dot(_1821, _363_fa_fog_c.xyz);\n        bool _1831 = _363_fa_fog_c.w > 0.5f;\n        float _1832;\n        if (_1831)\n        {\n            _1832 = _1827;\n        }\n        else\n        {\n            _1832 = length(_1821);\n        }\n        float _1844 = _1832 - _363_fa_fog_b.x;\n        if (_1844 > 0.0f)\n        {\n            float _1853 = _363_fa_fog.w * _1844;\n            float tau = _1853 * _1853;\n            if (_363_fa_fog_b.y > 0.0f)\n            {\n                float _1869;\n                if (_1831)\n                {\n                    _1869 = fa_world_pos.y - (_363_fa_fog_c.y * _1827);\n                }\n                else\n                {\n                    _1869 = _363_fa_camera_pos.y;\n                }\n                float _1890 = lerp(_1869, fa_world_pos.y, clamp(_363_fa_fog_b.x / _1832, 0.0f, 1.0f));\n                float _1894 = fa_world_pos.y - _1890;\n                float _1899 = _1890 - _363_fa_fog_b.z;\n                float _1904 = fa_world_pos.y - _363_fa_fog_b.z;\n                bool _1907 = _1899 <= 0.0f;\n                bool _1908 = !_1907;\n                bool _1914;\n                if (_1908)\n                {\n                    _1914 = _363_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1914 = _1907;\n                }\n                float _1915;\n                if (_1914)\n                {\n                    _1915 = _363_fa_fog_b.y;\n                }\n                else\n                {\n                    _1915 = _363_fa_fog_b.y * exp(-min(_363_fa_fog_b.w * _1899, 80.0f));\n                }\n                bool _1942;\n                if (_1908)\n                {\n                    _1942 = _363_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1942 = _1907;\n                }\n                float _1943;\n                if (_1942)\n                {\n                    _1943 = _363_fa_fog_b.y * _1899;\n                }\n                else\n                {\n                    _1943 = (_363_fa_fog_b.y * (1.0f - exp(-min(_363_fa_fog_b.w * _1899, 80.0f)))) / _363_fa_fog_b.w;\n                }\n                bool _1968 = _1904 <= 0.0f;\n                bool _1975;\n                if (!_1968)\n                {\n                    _1975 = _363_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1975 = _1968;\n                }\n                float _1976;\n                if (_1975)\n                {\n                    _1976 = _363_fa_fog_b.y * _1904;\n                }\n                else\n                {\n                    _1976 = (_363_fa_fog_b.y * (1.0f - exp(-min(_363_fa_fog_b.w * _1904, 80.0f)))) / _363_fa_fog_b.w;\n                }\n                float _2003;\n                if (abs(_1894) < 0.001000000047497451305389404296875f)\n                {\n                    _2003 = _1915;\n                }\n                else\n                {\n                    _2003 = (_1976 - _1943) / _1894;\n                }\n                tau += (_1844 * max(_2003, 0.0f));\n            }\n            result = lerp(result, _363_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2128);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_363",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_599",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1328",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _295 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _295;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0f);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _416 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _416;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0f);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
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
