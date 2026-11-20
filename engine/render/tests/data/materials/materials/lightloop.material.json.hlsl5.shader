{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "d7c968bc92bb9c3058c9e4a79ae24422666c878168002734a2aaf374dcac2b6e",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _261 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _261;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_268, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstatic const LightSample _2439 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _394_fa_camera_pos : packoffset(c0);\n    float4 _394_fa_ambient : packoffset(c1);\n    float4 _394_fa_base_color : packoffset(c2);\n    float4 _394_fa_emissive : packoffset(c3);\n    float4 _394_fa_model_emissive : packoffset(c4);\n    float4 _394_fa_pbr : packoffset(c5);\n    float4 _394_fa_maps : packoffset(c6);\n    float4 _394_fa_fog : packoffset(c7);\n    float4 _394_fa_fog_b : packoffset(c8);\n    float4 _394_fa_fog_c : packoffset(c9);\n    float4 _394_fa_counts : packoffset(c10);\n    float4 _394_fa_env_sky : packoffset(c11);\n    float4 _394_fa_env_horizon : packoffset(c12);\n    float4 _394_fa_time : packoffset(c13);\n    float4 _394_fa_cl_vpx : packoffset(c14);\n    float4 _394_fa_cl_vpy : packoffset(c15);\n    float4 _394_fa_cl_vpw : packoffset(c16);\n    float4 _394_fa_cl_fwd : packoffset(c17);\n    float4 _394_fa_cl_grid : packoffset(c18);\n    float4 _394_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _630_fa_shadow_mat[4] : packoffset(c0);\n    float4 _630_fa_shadow_rect[4] : packoffset(c16);\n    float4 _630_fa_shadow_info[4] : packoffset(c20);\n    float4 _630_fa_shadow_split : packoffset(c24);\n    float4 _630_fa_shadow_cfg : packoffset(c25);\n    float4 _630_fa_shadow_bias : packoffset(c26);\n    float4 _630_fa_shadow_eye : packoffset(c27);\n    float4 _630_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _1651_dark : packoffset(c0);\n    float _1651_fa_pad0 : packoffset(c0.y);\n    float _1651_fa_pad1 : packoffset(c0.z);\n    float _1651_fa_pad2 : packoffset(c0.w);\n    float _1651_skyAmount : packoffset(c1);\n    float _1651_fa_pad3 : packoffset(c1.y);\n    float _1651_fa_pad4 : packoffset(c1.z);\n    float _1651_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _399 = _394_fa_cl_info.x < 0.0f;\n    bool _406;\n    if (!_399)\n    {\n        _406 = _394_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = _394_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = _394_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = _394_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return int2(0, 0);\n    }\n    float4 _438 = float4(world_pos, 1.0f);\n    float _445 = dot(_394_fa_cl_vpw, _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _467 = float2(dot(_394_fa_cl_vpx, _438), dot(_394_fa_cl_vpy, _438)) / _445.xx;\n    int _471 = int(_394_fa_cl_grid.x);\n    int _475 = int(_394_fa_cl_grid.y);\n    int param = (int(_394_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_394_fa_cl_fwd.xyz, world_pos) + _394_fa_cl_fwd.w, _394_fa_cl_grid.w) / _394_fa_cl_grid.w) * _394_fa_cl_grid.z)), 0, int(_394_fa_cl_info.y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5f) + 0.5f) * _394_fa_cl_grid.y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5f) + 0.5f) * _394_fa_cl_grid.x)), 0, _471 - 1);\n    float4 _546 = fa_light_texel(param);\n    return int2(int(_546.x), int(_546.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_394_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1476 = fa_cluster_lookup(param);\n    fa_cl_slot = _1476.x;\n    fa_cl_local = _1476.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1723 = fa_linear_to_srgb(param);\n        c = _1723;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1731 = fa_srgb_to_linear(param_1);\n            c = _1731;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _174;\n    if (i.front_facing)\n    {\n        _174 = i.world_normal;\n    }\n    else\n    {\n        _174 = -i.world_normal;\n    }\n    float3 _198 = normalize(i.world_tangent.xyz - (_174 * dot(_174, i.world_tangent.xyz)));\n    float3 _226 = normalize(((_198 * m.x) + ((cross(_174, _198) * i.world_tangent.w) * m.y)) + (_174 * m.z));\n    float3 _229;\n    if (i.front_facing)\n    {\n        _229 = _226;\n    }\n    else\n    {\n        _229 = -_226;\n    }\n    return _229;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _394_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1762 = fa_tex_fix(param_2, param_3);\n    float4 _2418 = base_t;\n    _2418.x = _1762.x;\n    _2418.y = _1762.y;\n    _2418.z = _1762.z;\n    base_t = _2418;\n    float4 _1776 = (_2418 * _394_fa_base_color) * i.vertex_color;\n    float3 _2377 = i.world_normal;\n    if (_394_fa_maps.z > 0.5f)\n    {\n        float param_4 = _394_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1808 = fa_tex_fix(param_6, param_7);\n        float3 _1812 = (_1808 * 2.0f) - 1.0f.xxx;\n        float2 _1817 = _1812.xy * _394_fa_maps.x;\n        float3 _2426 = _1812;\n        _2426.x = _1817.x;\n        _2426.y = _1817.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2426;\n        _2377 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _394_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1846 = fa_tex_fix(param_12, param_13);\n    float4 _2429 = mrt;\n    _2429.x = _1846.x;\n    _2429.y = _1846.y;\n    _2429.z = _1846.z;\n    mrt = _2429;\n    float param_14 = _394_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1885 = fa_tex_fix(param_16, param_17);\n    float param_18 = _394_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1912 = fa_tex_fix(param_20, param_21);\n    Surface _2389 = { _1776.xyz, _1776.w, _2377, clamp(_394_fa_pbr.x * _1846.z, 0.0f, 1.0f), clamp(_394_fa_pbr.y * _1846.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_394_fa_maps.y * (_1885.x - 1.0f)), _394_fa_emissive.xyz + (_394_fa_model_emissive.xyz * _1912) };\n    return _2389;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _2439;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_394_fa_cl_info.x) + int(_394_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _266 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _272 = fa_light_texel(param_1);\n    float _275 = _272.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _282 = _275 < 0.5f;\n    float3 l;\n    if (_282)\n    {\n        l = normalize(_266.xyz);\n    }\n    else\n    {\n        float3 _294 = _266.xyz - world_pos;\n        float _296 = length(_294);\n        dist = _296;\n        l = _294 / max(_296, 9.9999997473787516355514526367188e-05f).xxx;\n        float _311 = _296 / max(_266.w, 0.001000000047497451305389404296875f);\n        float _317 = clamp(1.0f - (_311 * _311), 0.0f, 1.0f);\n        atten = _317 * _317;\n        if (_275 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _331 = fa_light_texel(param_2);\n            float _341 = _331.w;\n            int param_3 = (li * 4) + 3;\n            float4 _348 = fa_light_texel(param_3);\n            float _349 = _348.x;\n            float cos_inner = _349;\n            if (_349 > 1.5f)\n            {\n                cos_inner = lerp(_341, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_341, cos_inner, dot(-l, normalize(_331.xyz)));\n        }\n    }\n    int _380;\n    if (_282)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_275 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2333 = { l, _272.xyz * atten, atten, 1.0f, dist, _380 };\n    return _2333;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _1561 = n < 0;\n    bool _1568;\n    if (!_1561)\n    {\n        _1568 = n >= fa_light_count();\n    }\n    else\n    {\n        _1568 = _1561;\n    }\n    if (_1568)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _620;\n    if (i == 0)\n    {\n        _620 = _630_fa_shadow_split.x;\n    }\n    else\n    {\n        float _636;\n        if (i == 1)\n        {\n            _636 = _630_fa_shadow_split.y;\n        }\n        else\n        {\n            float _644;\n            if (i == 2)\n            {\n                _644 = _630_fa_shadow_split.z;\n            }\n            else\n            {\n                _644 = _630_fa_shadow_split.w;\n            }\n            _636 = _644;\n        }\n        _620 = _636;\n    }\n    return _620;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _608 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_608), sin(_608)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _682 = max(_630_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _687 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _693 = sqrt(1.0f - (_687 * _687));\n    float _701 = min(_693 / max(_687, 0.20000000298023223876953125f), 4.0f);\n    float _706;\n    if (_630_fa_shadow_bias.y > 0.0f)\n    {\n        _706 = _630_fa_shadow_bias.y;\n    }\n    else\n    {\n        _706 = 1.5f * _630_fa_shadow_info[ci].x;\n    }\n    float4 _731 = mul(float4(world + (n * (_706 * _693)), 1.0f), _630_fa_shadow_mat[ci]);\n    float _738 = _731.x;\n    bool _741 = _738 < _630_fa_shadow_rect[ci].x;\n    bool _750;\n    if (!_741)\n    {\n        _750 = _738 > _630_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _750 = _741;\n    }\n    bool _759;\n    if (!_750)\n    {\n        _759 = _731.y < _630_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _759 = _750;\n    }\n    bool _768;\n    if (!_759)\n    {\n        _768 = _731.y > _630_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _768 = _759;\n    }\n    bool _775;\n    if (!_768)\n    {\n        _775 = _731.z > 1.0f;\n    }\n    else\n    {\n        _775 = _768;\n    }\n    if (_775)\n    {\n        return -1.0f;\n    }\n    float _784;\n    if (_630_fa_shadow_bias.x > 0.0f)\n    {\n        _784 = _630_fa_shadow_bias.x;\n    }\n    else\n    {\n        _784 = 1.5f * _630_fa_shadow_info[ci].x;\n    }\n    float _803 = _731.z - ((_784 * (1.0f + (0.5f * _701))) / _682);\n    float _812 = ((_630_fa_shadow_info[ci].x * min(_701, 3.0f)) * 0.5f) / _682;\n    int _821 = int(_630_fa_shadow_cfg.z + 0.5f);\n    if (_821 == 1)\n    {\n        float2 param = _731.xy;\n        float4 param_1 = _630_fa_shadow_rect[ci];\n        float _832 = fa_shadow_depth(param, param_1);\n        return float(_803 <= _832);\n    }\n    float _839 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _842 = _821 == 2;\n    if (_842)\n    {\n        float _856 = clamp(((_630_fa_shadow_cfg.w * _682) * 0.25f) / _630_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _839;\n            float2 _875 = fa_shadow_vogel(param_2, param_3, param_4) * _856;\n            float2 param_5 = _731.xy + (_875 * _630_fa_shadow_bias.zw);\n            float4 param_6 = _630_fa_shadow_rect[ci];\n            float _886 = fa_shadow_depth(param_5, param_6);\n            if (_886 < (_803 - (length(_875) * _812)))\n            {\n                sum += _886;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_803 - (sum / cnt), 0.0f) * _682) * _630_fa_shadow_cfg.w) / _630_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _930 = _842 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _930; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _930;\n        float param_9 = _839;\n        float2 _949 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _731.xy + (_949 * _630_fa_shadow_bias.zw);\n        float4 param_11 = _630_fa_shadow_rect[ci];\n        float _960 = fa_shadow_depth(param_10, param_11);\n        lit += float((_803 - (length(_949) * _812)) <= _960);\n    }\n    return lit / float(_930);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_394_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _990 = int(_630_fa_shadow_cfg.x + 0.5f);\n    if (_990 < 1)\n    {\n        return 1.0f;\n    }\n    float _1006 = dot(world - _630_fa_shadow_eye.xyz, _630_fa_shadow_fwd.xyz);\n    int param = _990 - 1;\n    if (_1006 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1018 = _990 > 1;\n    bool _1025;\n    if (_1018)\n    {\n        _1025 = _1006 > _630_fa_shadow_split.x;\n    }\n    else\n    {\n        _1025 = _1018;\n    }\n    if (_1025)\n    {\n        ci = 1;\n    }\n    bool _1029 = _990 > 2;\n    bool _1036;\n    if (_1029)\n    {\n        _1036 = _1006 > _630_fa_shadow_split.y;\n    }\n    else\n    {\n        _1036 = _1029;\n    }\n    if (_1036)\n    {\n        ci = 2;\n    }\n    bool _1040 = _990 > 3;\n    bool _1047;\n    if (_1040)\n    {\n        _1047 = _1006 > _630_fa_shadow_split.z;\n    }\n    else\n    {\n        _1047 = _1040;\n    }\n    if (_1047)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _990)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1073 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1073;\n        if (_1073 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_630_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1098;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1098 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1098 = _630_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1117 = _630_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1098, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1128 = clamp((_1006 - (fa_shadow_split_at(param_7) - _1117)) / _1117, 0.0f, 1.0f);\n        if (_1128 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _990)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1149 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1149;\n                if (_1149 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1128);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1504 = fa_light_sample(param, param_1);\n    float3 _2353 = _1504.direction;\n    float3 _2348 = _1504.color;\n    float _2350 = _1504.shadow;\n    int _2358 = _1504.type;\n    if ((_2358 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2353;\n        float _1518 = fa_shadow_factor(param_2, param_3);\n        _2350 = _1518;\n        _2348 *= _1518;\n    }\n    LightSample _2365 = { _2353, _2348, _1504.attenuation, _2350, _1504._distance, _2358 };\n    return _2365;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _1535 = n < 0;\n    bool _1542;\n    if (!_1535)\n    {\n        _1542 = n >= fa_light_count();\n    }\n    else\n    {\n        _1542 = _1535;\n    }\n    if (_1542)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1363 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1366 = _1363.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1366 * _1366, exp2((-9.27999973297119140625f) * ndv)) * _1366) + _1363.y)) + _1363.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_394_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _394_fa_env_horizon.w).xyz;\n    }\n    float _1286 = rough * rough;\n    float _1316 = 0.60000002384185791015625f * _1286;\n    return lerp(lerp(_394_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_394_fa_env_horizon.xyz, _394_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1286)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1316, 0.0500000007450580596923828125f + _1316, d.y).xxx), ((_394_fa_env_sky.xyz + _394_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1286 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1405 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1405.x) + _1405.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float3 param = normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = lerp(0.039999999105930328369140625f.xxx, s.albedo, clamp(s.metallic, 0.0f, 1.0f).xxx);\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1608 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_1608 > bestPower)\n        {\n            bestPower = _1608;\n            best = n;\n        }\n    }\n    float3 lit = (_394_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1637 = fa_light(param_2, param_3);\n        float _1645;\n        if (dot(s.normal, _1637.direction) > 0.5f)\n        {\n            _1645 = 1.0f;\n        }\n        else\n        {\n            _1645 = _1651_dark;\n        }\n        lit += ((s.albedo * _1637.color) * _1645);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _1651_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_630_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1173 = int(_630_fa_shadow_cfg.x + 0.5f);\n    float _1183 = dot(world - _630_fa_shadow_eye.xyz, _630_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1188 = _1173 > 0;\n    bool _1197;\n    if (_1188)\n    {\n        int param = _1173 - 1;\n        _1197 = _1183 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1197 = _1188;\n    }\n    if (_1197)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1204 = _1173 > 1;\n        bool _1211;\n        if (_1204)\n        {\n            _1211 = _1183 > _630_fa_shadow_split.x;\n        }\n        else\n        {\n            _1211 = _1204;\n        }\n        if (_1211)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1217 = _1173 > 2;\n        bool _1224;\n        if (_1217)\n        {\n            _1224 = _1183 > _630_fa_shadow_split.y;\n        }\n        else\n        {\n            _1224 = _1217;\n        }\n        if (_1224)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1230 = _1173 > 3;\n        bool _1237;\n        if (_1230)\n        {\n            _1237 = _1183 > _630_fa_shadow_split.z;\n        }\n        else\n        {\n            _1237 = _1230;\n        }\n        if (_1237)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2253 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2253 = -_2253;\n    }\n    float3 _1955 = normalize(_394_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2266 = { fa_world_pos, _2253, fa_world_tangent, fa_uv, fa_vertex_color, _1955, gl_FrontFacing };\n    SurfaceInput param_1 = _2266;\n    Surface _1963 = fa_standard_surface(param_1);\n    float3 _2284 = _1963.albedo;\n    float _2285 = _1963.alpha;\n    float3 _2286 = _1963.normal;\n    float _2287 = _1963.metallic;\n    float _2288 = _1963.roughness;\n    float _2289 = _1963.occlusion;\n    float3 _2290 = _1963.emission;\n    SurfaceInput _2274 = { fa_world_pos, _2253, fa_world_tangent, fa_uv, fa_vertex_color, _1955, gl_FrontFacing };\n    SurfaceInput param_2 = _2274;\n    Surface param_3 = _1963;\n    surface(param_2, param_3);\n    _2284 = param_3.albedo;\n    _2285 = param_3.alpha;\n    _2286 = param_3.normal;\n    _2287 = param_3.metallic;\n    _2288 = param_3.roughness;\n    _2289 = param_3.occlusion;\n    _2290 = param_3.emission;\n    float3 result;\n    if (_394_fa_emissive.w > 0.5f)\n    {\n        result = _2284;\n    }\n    else\n    {\n        float3 _1984 = _2286;\n        float3 _1985 = normalize(_1984);\n        _2286 = _1985;\n        SurfaceInput _2282 = { fa_world_pos, _2253, fa_world_tangent, fa_uv, fa_vertex_color, _1955, gl_FrontFacing };\n        SurfaceInput param_4 = _2282;\n        Surface _2320 = { _2284, _2285, _1985, _2287, _2288, _2289, _2290 };\n        Surface param_5 = _2320;\n        result = lighting(param_4, param_5);\n    }\n    float3 _2000 = result;\n    float3 _2001 = _2000 + _2290;\n    result = _2001;\n    float3 param_6 = _2001;\n    float3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _2010 = _394_fa_fog.w > 0.0f;\n    bool _2018;\n    if (!_2010)\n    {\n        _2018 = _394_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2018 = _2010;\n    }\n    if (_2018)\n    {\n        float3 _2027 = fa_world_pos - _394_fa_camera_pos.xyz;\n        float _2034 = dot(_2027, _394_fa_fog_c.xyz);\n        bool _2038 = _394_fa_fog_c.w > 0.5f;\n        float _2039;\n        if (_2038)\n        {\n            _2039 = _2034;\n        }\n        else\n        {\n            _2039 = length(_2027);\n        }\n        float _2051 = _2039 - _394_fa_fog_b.x;\n        if (_2051 > 0.0f)\n        {\n            float _2060 = _394_fa_fog.w * _2051;\n            float tau = _2060 * _2060;\n            if (_394_fa_fog_b.y > 0.0f)\n            {\n                float _2076;\n                if (_2038)\n                {\n                    _2076 = fa_world_pos.y - (_394_fa_fog_c.y * _2034);\n                }\n                else\n                {\n                    _2076 = _394_fa_camera_pos.y;\n                }\n                float _2097 = lerp(_2076, fa_world_pos.y, clamp(_394_fa_fog_b.x / _2039, 0.0f, 1.0f));\n                float _2101 = fa_world_pos.y - _2097;\n                float _2106 = _2097 - _394_fa_fog_b.z;\n                float _2111 = fa_world_pos.y - _394_fa_fog_b.z;\n                bool _2114 = _2106 <= 0.0f;\n                bool _2115 = !_2114;\n                bool _2121;\n                if (_2115)\n                {\n                    _2121 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2121 = _2114;\n                }\n                float _2122;\n                if (_2121)\n                {\n                    _2122 = _394_fa_fog_b.y;\n                }\n                else\n                {\n                    _2122 = _394_fa_fog_b.y * exp(-min(_394_fa_fog_b.w * _2106, 80.0f));\n                }\n                bool _2149;\n                if (_2115)\n                {\n                    _2149 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2149 = _2114;\n                }\n                float _2150;\n                if (_2149)\n                {\n                    _2150 = _394_fa_fog_b.y * _2106;\n                }\n                else\n                {\n                    _2150 = (_394_fa_fog_b.y * (1.0f - exp(-min(_394_fa_fog_b.w * _2106, 80.0f)))) / _394_fa_fog_b.w;\n                }\n                bool _2175 = _2111 <= 0.0f;\n                bool _2182;\n                if (!_2175)\n                {\n                    _2182 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2182 = _2175;\n                }\n                float _2183;\n                if (_2182)\n                {\n                    _2183 = _394_fa_fog_b.y * _2111;\n                }\n                else\n                {\n                    _2183 = (_394_fa_fog_b.y * (1.0f - exp(-min(_394_fa_fog_b.w * _2111, 80.0f)))) / _394_fa_fog_b.w;\n                }\n                float _2210;\n                if (abs(_2101) < 0.001000000047497451305389404296875f)\n                {\n                    _2210 = _2122;\n                }\n                else\n                {\n                    _2210 = (_2183 - _2150) / _2101;\n                }\n                tau += (_2051 * max(_2210, 0.0f));\n            }\n            result = lerp(result, _394_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2285);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_394",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_630",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1651",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _382 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _382;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_389, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstatic const LightSample _2439 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _394_fa_camera_pos : packoffset(c0);\n    float4 _394_fa_ambient : packoffset(c1);\n    float4 _394_fa_base_color : packoffset(c2);\n    float4 _394_fa_emissive : packoffset(c3);\n    float4 _394_fa_model_emissive : packoffset(c4);\n    float4 _394_fa_pbr : packoffset(c5);\n    float4 _394_fa_maps : packoffset(c6);\n    float4 _394_fa_fog : packoffset(c7);\n    float4 _394_fa_fog_b : packoffset(c8);\n    float4 _394_fa_fog_c : packoffset(c9);\n    float4 _394_fa_counts : packoffset(c10);\n    float4 _394_fa_env_sky : packoffset(c11);\n    float4 _394_fa_env_horizon : packoffset(c12);\n    float4 _394_fa_time : packoffset(c13);\n    float4 _394_fa_cl_vpx : packoffset(c14);\n    float4 _394_fa_cl_vpy : packoffset(c15);\n    float4 _394_fa_cl_vpw : packoffset(c16);\n    float4 _394_fa_cl_fwd : packoffset(c17);\n    float4 _394_fa_cl_grid : packoffset(c18);\n    float4 _394_fa_cl_info : packoffset(c19);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _630_fa_shadow_mat[4] : packoffset(c0);\n    float4 _630_fa_shadow_rect[4] : packoffset(c16);\n    float4 _630_fa_shadow_info[4] : packoffset(c20);\n    float4 _630_fa_shadow_split : packoffset(c24);\n    float4 _630_fa_shadow_cfg : packoffset(c25);\n    float4 _630_fa_shadow_bias : packoffset(c26);\n    float4 _630_fa_shadow_eye : packoffset(c27);\n    float4 _630_fa_shadow_fwd : packoffset(c28);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _1651_dark : packoffset(c0);\n    float _1651_fa_pad0 : packoffset(c0.y);\n    float _1651_fa_pad1 : packoffset(c0.z);\n    float _1651_fa_pad2 : packoffset(c0.w);\n    float _1651_skyAmount : packoffset(c1);\n    float _1651_fa_pad3 : packoffset(c1.y);\n    float _1651_fa_pad4 : packoffset(c1.z);\n    float _1651_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _399 = _394_fa_cl_info.x < 0.0f;\n    bool _406;\n    if (!_399)\n    {\n        _406 = _394_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = _394_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = _394_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = _394_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return int2(0, 0);\n    }\n    float4 _438 = float4(world_pos, 1.0f);\n    float _445 = dot(_394_fa_cl_vpw, _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _467 = float2(dot(_394_fa_cl_vpx, _438), dot(_394_fa_cl_vpy, _438)) / _445.xx;\n    int _471 = int(_394_fa_cl_grid.x);\n    int _475 = int(_394_fa_cl_grid.y);\n    int param = (int(_394_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_394_fa_cl_fwd.xyz, world_pos) + _394_fa_cl_fwd.w, _394_fa_cl_grid.w) / _394_fa_cl_grid.w) * _394_fa_cl_grid.z)), 0, int(_394_fa_cl_info.y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5f) + 0.5f) * _394_fa_cl_grid.y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5f) + 0.5f) * _394_fa_cl_grid.x)), 0, _471 - 1);\n    float4 _546 = fa_light_texel(param);\n    return int2(int(_546.x), int(_546.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_394_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1476 = fa_cluster_lookup(param);\n    fa_cl_slot = _1476.x;\n    fa_cl_local = _1476.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1723 = fa_linear_to_srgb(param);\n        c = _1723;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1731 = fa_srgb_to_linear(param_1);\n            c = _1731;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _174;\n    if (i.front_facing)\n    {\n        _174 = i.world_normal;\n    }\n    else\n    {\n        _174 = -i.world_normal;\n    }\n    float3 _198 = normalize(i.world_tangent.xyz - (_174 * dot(_174, i.world_tangent.xyz)));\n    float3 _226 = normalize(((_198 * m.x) + ((cross(_174, _198) * i.world_tangent.w) * m.y)) + (_174 * m.z));\n    float3 _229;\n    if (i.front_facing)\n    {\n        _229 = _226;\n    }\n    else\n    {\n        _229 = -_226;\n    }\n    return _229;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _394_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1762 = fa_tex_fix(param_2, param_3);\n    float4 _2418 = base_t;\n    _2418.x = _1762.x;\n    _2418.y = _1762.y;\n    _2418.z = _1762.z;\n    base_t = _2418;\n    float4 _1776 = (_2418 * _394_fa_base_color) * i.vertex_color;\n    float3 _2377 = i.world_normal;\n    if (_394_fa_maps.z > 0.5f)\n    {\n        float param_4 = _394_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1808 = fa_tex_fix(param_6, param_7);\n        float3 _1812 = (_1808 * 2.0f) - 1.0f.xxx;\n        float2 _1817 = _1812.xy * _394_fa_maps.x;\n        float3 _2426 = _1812;\n        _2426.x = _1817.x;\n        _2426.y = _1817.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2426;\n        _2377 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _394_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1846 = fa_tex_fix(param_12, param_13);\n    float4 _2429 = mrt;\n    _2429.x = _1846.x;\n    _2429.y = _1846.y;\n    _2429.z = _1846.z;\n    mrt = _2429;\n    float param_14 = _394_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1885 = fa_tex_fix(param_16, param_17);\n    float param_18 = _394_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1912 = fa_tex_fix(param_20, param_21);\n    Surface _2389 = { _1776.xyz, _1776.w, _2377, clamp(_394_fa_pbr.x * _1846.z, 0.0f, 1.0f), clamp(_394_fa_pbr.y * _1846.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_394_fa_maps.y * (_1885.x - 1.0f)), _394_fa_emissive.xyz + (_394_fa_model_emissive.xyz * _1912) };\n    return _2389;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _2439;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_394_fa_cl_info.x) + int(_394_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _266 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _272 = fa_light_texel(param_1);\n    float _275 = _272.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _282 = _275 < 0.5f;\n    float3 l;\n    if (_282)\n    {\n        l = normalize(_266.xyz);\n    }\n    else\n    {\n        float3 _294 = _266.xyz - world_pos;\n        float _296 = length(_294);\n        dist = _296;\n        l = _294 / max(_296, 9.9999997473787516355514526367188e-05f).xxx;\n        float _311 = _296 / max(_266.w, 0.001000000047497451305389404296875f);\n        float _317 = clamp(1.0f - (_311 * _311), 0.0f, 1.0f);\n        atten = _317 * _317;\n        if (_275 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _331 = fa_light_texel(param_2);\n            float _341 = _331.w;\n            int param_3 = (li * 4) + 3;\n            float4 _348 = fa_light_texel(param_3);\n            float _349 = _348.x;\n            float cos_inner = _349;\n            if (_349 > 1.5f)\n            {\n                cos_inner = lerp(_341, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_341, cos_inner, dot(-l, normalize(_331.xyz)));\n        }\n    }\n    int _380;\n    if (_282)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_275 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2333 = { l, _272.xyz * atten, atten, 1.0f, dist, _380 };\n    return _2333;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _1561 = n < 0;\n    bool _1568;\n    if (!_1561)\n    {\n        _1568 = n >= fa_light_count();\n    }\n    else\n    {\n        _1568 = _1561;\n    }\n    if (_1568)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _620;\n    if (i == 0)\n    {\n        _620 = _630_fa_shadow_split.x;\n    }\n    else\n    {\n        float _636;\n        if (i == 1)\n        {\n            _636 = _630_fa_shadow_split.y;\n        }\n        else\n        {\n            float _644;\n            if (i == 2)\n            {\n                _644 = _630_fa_shadow_split.z;\n            }\n            else\n            {\n                _644 = _630_fa_shadow_split.w;\n            }\n            _636 = _644;\n        }\n        _620 = _636;\n    }\n    return _620;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _608 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_608), sin(_608)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _682 = max(_630_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _687 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _693 = sqrt(1.0f - (_687 * _687));\n    float _701 = min(_693 / max(_687, 0.20000000298023223876953125f), 4.0f);\n    float _706;\n    if (_630_fa_shadow_bias.y > 0.0f)\n    {\n        _706 = _630_fa_shadow_bias.y;\n    }\n    else\n    {\n        _706 = 1.5f * _630_fa_shadow_info[ci].x;\n    }\n    float4 _731 = mul(float4(world + (n * (_706 * _693)), 1.0f), _630_fa_shadow_mat[ci]);\n    float _738 = _731.x;\n    bool _741 = _738 < _630_fa_shadow_rect[ci].x;\n    bool _750;\n    if (!_741)\n    {\n        _750 = _738 > _630_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _750 = _741;\n    }\n    bool _759;\n    if (!_750)\n    {\n        _759 = _731.y < _630_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _759 = _750;\n    }\n    bool _768;\n    if (!_759)\n    {\n        _768 = _731.y > _630_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _768 = _759;\n    }\n    bool _775;\n    if (!_768)\n    {\n        _775 = _731.z > 1.0f;\n    }\n    else\n    {\n        _775 = _768;\n    }\n    if (_775)\n    {\n        return -1.0f;\n    }\n    float _784;\n    if (_630_fa_shadow_bias.x > 0.0f)\n    {\n        _784 = _630_fa_shadow_bias.x;\n    }\n    else\n    {\n        _784 = 1.5f * _630_fa_shadow_info[ci].x;\n    }\n    float _803 = _731.z - ((_784 * (1.0f + (0.5f * _701))) / _682);\n    float _812 = ((_630_fa_shadow_info[ci].x * min(_701, 3.0f)) * 0.5f) / _682;\n    int _821 = int(_630_fa_shadow_cfg.z + 0.5f);\n    if (_821 == 1)\n    {\n        float2 param = _731.xy;\n        float4 param_1 = _630_fa_shadow_rect[ci];\n        float _832 = fa_shadow_depth(param, param_1);\n        return float(_803 <= _832);\n    }\n    float _839 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    bool _842 = _821 == 2;\n    if (_842)\n    {\n        float _856 = clamp(((_630_fa_shadow_cfg.w * _682) * 0.25f) / _630_fa_shadow_info[ci].x, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _839;\n            float2 _875 = fa_shadow_vogel(param_2, param_3, param_4) * _856;\n            float2 param_5 = _731.xy + (_875 * _630_fa_shadow_bias.zw);\n            float4 param_6 = _630_fa_shadow_rect[ci];\n            float _886 = fa_shadow_depth(param_5, param_6);\n            if (_886 < (_803 - (length(_875) * _812)))\n            {\n                sum += _886;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(_803 - (sum / cnt), 0.0f) * _682) * _630_fa_shadow_cfg.w) / _630_fa_shadow_info[ci].x, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _930 = _842 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _930; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _930;\n        float param_9 = _839;\n        float2 _949 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _731.xy + (_949 * _630_fa_shadow_bias.zw);\n        float4 param_11 = _630_fa_shadow_rect[ci];\n        float _960 = fa_shadow_depth(param_10, param_11);\n        lit += float((_803 - (length(_949) * _812)) <= _960);\n    }\n    return lit / float(_930);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_394_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _990 = int(_630_fa_shadow_cfg.x + 0.5f);\n    if (_990 < 1)\n    {\n        return 1.0f;\n    }\n    float _1006 = dot(world - _630_fa_shadow_eye.xyz, _630_fa_shadow_fwd.xyz);\n    int param = _990 - 1;\n    if (_1006 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1018 = _990 > 1;\n    bool _1025;\n    if (_1018)\n    {\n        _1025 = _1006 > _630_fa_shadow_split.x;\n    }\n    else\n    {\n        _1025 = _1018;\n    }\n    if (_1025)\n    {\n        ci = 1;\n    }\n    bool _1029 = _990 > 2;\n    bool _1036;\n    if (_1029)\n    {\n        _1036 = _1006 > _630_fa_shadow_split.y;\n    }\n    else\n    {\n        _1036 = _1029;\n    }\n    if (_1036)\n    {\n        ci = 2;\n    }\n    bool _1040 = _990 > 3;\n    bool _1047;\n    if (_1040)\n    {\n        _1047 = _1006 > _630_fa_shadow_split.z;\n    }\n    else\n    {\n        _1047 = _1040;\n    }\n    if (_1047)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _990)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1073 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1073;\n        if (_1073 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_630_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1098;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1098 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1098 = _630_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1117 = _630_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1098, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1128 = clamp((_1006 - (fa_shadow_split_at(param_7) - _1117)) / _1117, 0.0f, 1.0f);\n        if (_1128 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _990)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1149 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1149;\n                if (_1149 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1128);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1504 = fa_light_sample(param, param_1);\n    float3 _2353 = _1504.direction;\n    float3 _2348 = _1504.color;\n    float _2350 = _1504.shadow;\n    int _2358 = _1504.type;\n    if ((_2358 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2353;\n        float _1518 = fa_shadow_factor(param_2, param_3);\n        _2350 = _1518;\n        _2348 *= _1518;\n    }\n    LightSample _2365 = { _2353, _2348, _1504.attenuation, _2350, _1504._distance, _2358 };\n    return _2365;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _1535 = n < 0;\n    bool _1542;\n    if (!_1535)\n    {\n        _1542 = n >= fa_light_count();\n    }\n    else\n    {\n        _1542 = _1535;\n    }\n    if (_1542)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _1363 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _1366 = _1363.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_1366 * _1366, exp2((-9.27999973297119140625f) * ndv)) * _1366) + _1363.y)) + _1363.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_394_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _394_fa_env_horizon.w).xyz;\n    }\n    float _1286 = rough * rough;\n    float _1316 = 0.60000002384185791015625f * _1286;\n    return lerp(lerp(_394_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_394_fa_env_horizon.xyz, _394_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _1286)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _1316, 0.0500000007450580596923828125f + _1316, d.y).xxx), ((_394_fa_env_sky.xyz + _394_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_1286 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _1405 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1405.x) + _1405.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float3 param = normalize(s.normal);\n    float3 param_1 = i.view_dir;\n    float3 param_2 = lerp(0.039999999105930328369140625f.xxx, s.albedo, clamp(s.metallic, 0.0f, 1.0f).xxx);\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1608 = dot(fa_light_unshadowed(param, param_1).color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_1608 > bestPower)\n        {\n            bestPower = _1608;\n            best = n;\n        }\n    }\n    float3 lit = (_394_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1637 = fa_light(param_2, param_3);\n        float _1645;\n        if (dot(s.normal, _1637.direction) > 0.5f)\n        {\n            _1645 = 1.0f;\n        }\n        else\n        {\n            _1645 = _1651_dark;\n        }\n        lit += ((s.albedo * _1637.color) * _1645);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _1651_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_630_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1173 = int(_630_fa_shadow_cfg.x + 0.5f);\n    float _1183 = dot(world - _630_fa_shadow_eye.xyz, _630_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1188 = _1173 > 0;\n    bool _1197;\n    if (_1188)\n    {\n        int param = _1173 - 1;\n        _1197 = _1183 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1197 = _1188;\n    }\n    if (_1197)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1204 = _1173 > 1;\n        bool _1211;\n        if (_1204)\n        {\n            _1211 = _1183 > _630_fa_shadow_split.x;\n        }\n        else\n        {\n            _1211 = _1204;\n        }\n        if (_1211)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1217 = _1173 > 2;\n        bool _1224;\n        if (_1217)\n        {\n            _1224 = _1183 > _630_fa_shadow_split.y;\n        }\n        else\n        {\n            _1224 = _1217;\n        }\n        if (_1224)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1230 = _1173 > 3;\n        bool _1237;\n        if (_1230)\n        {\n            _1237 = _1183 > _630_fa_shadow_split.z;\n        }\n        else\n        {\n            _1237 = _1230;\n        }\n        if (_1237)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2253 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2253 = -_2253;\n    }\n    float3 _1955 = normalize(_394_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2266 = { fa_world_pos, _2253, fa_world_tangent, fa_uv, fa_vertex_color, _1955, gl_FrontFacing };\n    SurfaceInput param_1 = _2266;\n    Surface _1963 = fa_standard_surface(param_1);\n    float3 _2284 = _1963.albedo;\n    float _2285 = _1963.alpha;\n    float3 _2286 = _1963.normal;\n    float _2287 = _1963.metallic;\n    float _2288 = _1963.roughness;\n    float _2289 = _1963.occlusion;\n    float3 _2290 = _1963.emission;\n    SurfaceInput _2274 = { fa_world_pos, _2253, fa_world_tangent, fa_uv, fa_vertex_color, _1955, gl_FrontFacing };\n    SurfaceInput param_2 = _2274;\n    Surface param_3 = _1963;\n    surface(param_2, param_3);\n    _2284 = param_3.albedo;\n    _2285 = param_3.alpha;\n    _2286 = param_3.normal;\n    _2287 = param_3.metallic;\n    _2288 = param_3.roughness;\n    _2289 = param_3.occlusion;\n    _2290 = param_3.emission;\n    float3 result;\n    if (_394_fa_emissive.w > 0.5f)\n    {\n        result = _2284;\n    }\n    else\n    {\n        float3 _1984 = _2286;\n        float3 _1985 = normalize(_1984);\n        _2286 = _1985;\n        SurfaceInput _2282 = { fa_world_pos, _2253, fa_world_tangent, fa_uv, fa_vertex_color, _1955, gl_FrontFacing };\n        SurfaceInput param_4 = _2282;\n        Surface _2320 = { _2284, _2285, _1985, _2287, _2288, _2289, _2290 };\n        Surface param_5 = _2320;\n        result = lighting(param_4, param_5);\n    }\n    float3 _2000 = result;\n    float3 _2001 = _2000 + _2290;\n    result = _2001;\n    float3 param_6 = _2001;\n    float3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _2010 = _394_fa_fog.w > 0.0f;\n    bool _2018;\n    if (!_2010)\n    {\n        _2018 = _394_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2018 = _2010;\n    }\n    if (_2018)\n    {\n        float3 _2027 = fa_world_pos - _394_fa_camera_pos.xyz;\n        float _2034 = dot(_2027, _394_fa_fog_c.xyz);\n        bool _2038 = _394_fa_fog_c.w > 0.5f;\n        float _2039;\n        if (_2038)\n        {\n            _2039 = _2034;\n        }\n        else\n        {\n            _2039 = length(_2027);\n        }\n        float _2051 = _2039 - _394_fa_fog_b.x;\n        if (_2051 > 0.0f)\n        {\n            float _2060 = _394_fa_fog.w * _2051;\n            float tau = _2060 * _2060;\n            if (_394_fa_fog_b.y > 0.0f)\n            {\n                float _2076;\n                if (_2038)\n                {\n                    _2076 = fa_world_pos.y - (_394_fa_fog_c.y * _2034);\n                }\n                else\n                {\n                    _2076 = _394_fa_camera_pos.y;\n                }\n                float _2097 = lerp(_2076, fa_world_pos.y, clamp(_394_fa_fog_b.x / _2039, 0.0f, 1.0f));\n                float _2101 = fa_world_pos.y - _2097;\n                float _2106 = _2097 - _394_fa_fog_b.z;\n                float _2111 = fa_world_pos.y - _394_fa_fog_b.z;\n                bool _2114 = _2106 <= 0.0f;\n                bool _2115 = !_2114;\n                bool _2121;\n                if (_2115)\n                {\n                    _2121 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2121 = _2114;\n                }\n                float _2122;\n                if (_2121)\n                {\n                    _2122 = _394_fa_fog_b.y;\n                }\n                else\n                {\n                    _2122 = _394_fa_fog_b.y * exp(-min(_394_fa_fog_b.w * _2106, 80.0f));\n                }\n                bool _2149;\n                if (_2115)\n                {\n                    _2149 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2149 = _2114;\n                }\n                float _2150;\n                if (_2149)\n                {\n                    _2150 = _394_fa_fog_b.y * _2106;\n                }\n                else\n                {\n                    _2150 = (_394_fa_fog_b.y * (1.0f - exp(-min(_394_fa_fog_b.w * _2106, 80.0f)))) / _394_fa_fog_b.w;\n                }\n                bool _2175 = _2111 <= 0.0f;\n                bool _2182;\n                if (!_2175)\n                {\n                    _2182 = _394_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2182 = _2175;\n                }\n                float _2183;\n                if (_2182)\n                {\n                    _2183 = _394_fa_fog_b.y * _2111;\n                }\n                else\n                {\n                    _2183 = (_394_fa_fog_b.y * (1.0f - exp(-min(_394_fa_fog_b.w * _2111, 80.0f)))) / _394_fa_fog_b.w;\n                }\n                float _2210;\n                if (abs(_2101) < 0.001000000047497451305389404296875f)\n                {\n                    _2210 = _2122;\n                }\n                else\n                {\n                    _2210 = (_2183 - _2150) / _2101;\n                }\n                tau += (_2051 * max(_2210, 0.0f));\n            }\n            result = lerp(result, _394_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2285);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_394",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_630",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1651",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _295 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _295;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0f);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _590 = base_t;\n    _590.x = _225.x;\n    _590.y = _225.y;\n    _590.z = _225.z;\n    base_t = _590;\n    float4 _241 = (_590 * _213_fa_base_color) * i.vertex_color;\n    float3 _571 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _598 = _279;\n        _598.x = _284.x;\n        _598.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _598;\n        _571 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _601 = mrt;\n    _601.x = _313.x;\n    _601.y = _313.y;\n    _601.z = _313.z;\n    mrt = _601;\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    Surface _583 = { _241.xyz, _241.w, _571, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_354.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _381) };\n    return _583;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _518 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _518 = -_518;\n    }\n    float3 _427 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _531 = { fa_world_pos, _518, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param = _531;\n    SurfaceInput _539 = { fa_world_pos, _518, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param_1 = _539;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _442 = normalize(param_2.normal);\n    float3 _457 = normalize(float3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / ((abs(_457.x) + abs(_457.y)) + abs(_469)).xx;\n    if (_469 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 320,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _590 = base_t;\n    _590.x = _225.x;\n    _590.y = _225.y;\n    _590.z = _225.z;\n    base_t = _590;\n    float4 _241 = (_590 * _213_fa_base_color) * i.vertex_color;\n    float3 _571 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _598 = _279;\n        _598.x = _284.x;\n        _598.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _598;\n        _571 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _601 = mrt;\n    _601.x = _313.x;\n    _601.y = _313.y;\n    _601.z = _313.z;\n    mrt = _601;\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _381 = fa_tex_fix(param_20, param_21);\n    Surface _583 = { _241.xyz, _241.w, _571, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_354.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _381) };\n    return _583;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _518 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _518 = -_518;\n    }\n    float3 _427 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _531 = { fa_world_pos, _518, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param = _531;\n    SurfaceInput _539 = { fa_world_pos, _518, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing };\n    SurfaceInput param_1 = _539;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _442 = normalize(param_2.normal);\n    float3 _457 = normalize(float3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    float2 e = _457.xy / ((abs(_457.x) + abs(_457.y)) + abs(_469)).xx;\n    if (_469 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 320,
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
