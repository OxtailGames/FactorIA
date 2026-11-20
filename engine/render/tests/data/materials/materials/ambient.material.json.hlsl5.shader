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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _421_fa_camera_pos : packoffset(c0);\n    float4 _421_fa_ambient : packoffset(c1);\n    float4 _421_fa_base_color : packoffset(c2);\n    float4 _421_fa_emissive : packoffset(c3);\n    float4 _421_fa_model_emissive : packoffset(c4);\n    float4 _421_fa_pbr : packoffset(c5);\n    float4 _421_fa_maps : packoffset(c6);\n    float4 _421_fa_fog : packoffset(c7);\n    float4 _421_fa_fog_b : packoffset(c8);\n    float4 _421_fa_fog_c : packoffset(c9);\n    float4 _421_fa_counts : packoffset(c10);\n    float4 _421_fa_env_sky : packoffset(c11);\n    float4 _421_fa_env_horizon : packoffset(c12);\n    float4 _421_fa_time : packoffset(c13);\n    float4 _421_fa_cl_vpx : packoffset(c14);\n    float4 _421_fa_cl_vpy : packoffset(c15);\n    float4 _421_fa_cl_vpw : packoffset(c16);\n    float4 _421_fa_cl_fwd : packoffset(c17);\n    float4 _421_fa_cl_grid : packoffset(c18);\n    float4 _421_fa_cl_info : packoffset(c19);\n    float4 _421_fa_layers_a : packoffset(c20);\n    float4 _421_fa_layers_b : packoffset(c21);\n    float4 _421_fa_layers_c : packoffset(c22);\n    float4 _421_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _657_fa_shadow_mat[4] : packoffset(c0);\n    float4 _657_fa_shadow_rect[4] : packoffset(c16);\n    float4 _657_fa_shadow_info[4] : packoffset(c20);\n    float4 _657_fa_shadow_split : packoffset(c24);\n    float4 _657_fa_shadow_cfg : packoffset(c25);\n    float4 _657_fa_shadow_bias : packoffset(c26);\n    float4 _657_fa_shadow_eye : packoffset(c27);\n    float4 _657_fa_shadow_fwd : packoffset(c28);\n    float4 _657_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t8);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _426 = _421_fa_cl_info.x < 0.0f;\n    bool _433;\n    if (!_426)\n    {\n        _433 = _421_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _433 = _426;\n    }\n    bool _441;\n    if (!_433)\n    {\n        _441 = _421_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _441 = _433;\n    }\n    bool _448;\n    if (!_441)\n    {\n        _448 = _421_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _448 = _441;\n    }\n    bool _455;\n    if (!_448)\n    {\n        _455 = _421_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _455 = _448;\n    }\n    if (_455)\n    {\n        return int2(0, 0);\n    }\n    float4 _465 = float4(world_pos, 1.0f);\n    float _472 = dot(_421_fa_cl_vpw, _465);\n    if (!(_472 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _494 = float2(dot(_421_fa_cl_vpx, _465), dot(_421_fa_cl_vpy, _465)) / _472.xx;\n    int _498 = int(_421_fa_cl_grid.x);\n    int _502 = int(_421_fa_cl_grid.y);\n    int param = (int(_421_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_421_fa_cl_fwd.xyz, world_pos) + _421_fa_cl_fwd.w, _421_fa_cl_grid.w) / _421_fa_cl_grid.w) * _421_fa_cl_grid.z)), 0, int(_421_fa_cl_info.y) - 1) * _502) + clamp(int(floor(((_494.y * 0.5f) + 0.5f) * _421_fa_cl_grid.y)), 0, _502 - 1)) * _498)) + clamp(int(floor(((_494.x * 0.5f) + 0.5f) * _421_fa_cl_grid.x)), 0, _498 - 1);\n    float4 _573 = fa_light_texel(param);\n    return int2(int(_573.x), int(_573.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_421_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1735 = fa_cluster_lookup(param);\n    fa_cl_slot = _1735.x;\n    fa_cl_local = _1735.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1899 = fa_linear_to_srgb(param);\n        c = _1899;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1907 = fa_srgb_to_linear(param_1);\n            c = _1907;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _185;\n    if (i.front_facing)\n    {\n        _185 = i.world_normal;\n    }\n    else\n    {\n        _185 = -i.world_normal;\n    }\n    float3 _209 = normalize(i.world_tangent.xyz - (_185 * dot(_185, i.world_tangent.xyz)));\n    float3 _237 = normalize(((_209 * m.x) + ((cross(_185, _209) * i.world_tangent.w) * m.y)) + (_185 * m.z));\n    float3 _240;\n    if (i.front_facing)\n    {\n        _240 = _237;\n    }\n    else\n    {\n        _240 = -_237;\n    }\n    return _240;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _421_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1938 = fa_tex_fix(param_2, param_3);\n    float4 _2925 = base_t;\n    _2925.x = _1938.x;\n    _2925.y = _1938.y;\n    _2925.z = _1938.z;\n    base_t = _2925;\n    float4 _1952 = (_2925 * _421_fa_base_color) * i.vertex_color;\n    float3 _2840 = i.world_normal;\n    if (_421_fa_maps.z > 0.5f)\n    {\n        float param_4 = _421_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1984 = fa_tex_fix(param_6, param_7);\n        float3 _1988 = (_1984 * 2.0f) - 1.0f.xxx;\n        float2 _1993 = _1988.xy * _421_fa_maps.x;\n        float3 _2933 = _1988;\n        _2933.x = _1993.x;\n        _2933.y = _1993.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2933;\n        _2840 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _421_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2022 = fa_tex_fix(param_12, param_13);\n    float4 _2936 = mrt;\n    _2936.x = _2022.x;\n    _2936.y = _2022.y;\n    _2936.z = _2022.z;\n    mrt = _2936;\n    float4 _2051 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _421_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2051.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2063 = fa_tex_fix(param_16, param_17);\n    float param_18 = _421_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2093 = fa_tex_fix(param_20, param_21);\n    float _2845 = _421_fa_layers_a.x;\n    float _2846 = _421_fa_layers_a.y;\n    float _2849 = _421_fa_layers_a.z;\n    float _2848 = _421_fa_layers_b.w;\n    float _2851 = _421_fa_layers_c.x;\n    if (_421_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_421_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _2845 *= _2063.y;\n            _2846 *= _2063.z;\n            _2848 *= _2051.w;\n        }\n        if (_421_fa_layers_c.z > 1.5f)\n        {\n            _2849 *= mrt.x;\n            _2851 *= mrt.w;\n        }\n    }\n    Surface _2870 = { _1952.xyz, _1952.w, _2840, clamp(_421_fa_pbr.x * _2022.z, 0.0f, 1.0f), clamp(_421_fa_pbr.y * _2022.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_421_fa_maps.y * (_2063.x - 1.0f)), _421_fa_emissive.xyz + (_421_fa_model_emissive.xyz * _2093), _2845, _2846, _421_fa_layers_b.xyz, _2848, _2849, _421_fa_layers_a.w, _2851, _421_fa_layers_c.y, _421_fa_layers_d.xyz };\n    return _2870;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_421_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _421_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_421_fa_cl_info.x) + int(_421_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _296 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _302 = fa_light_texel(param_1);\n    float _305 = _302.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _311 = _305 < 0.5f;\n    float3 l;\n    if (_311)\n    {\n        l = normalize(_296.xyz);\n    }\n    else\n    {\n        float3 _323 = _296.xyz - world_pos;\n        float _325 = length(_323);\n        dist = _325;\n        l = _323 / max(_325, 9.9999997473787516355514526367188e-05f).xxx;\n        float _340 = _325 / max(_296.w, 0.001000000047497451305389404296875f);\n        float _346 = clamp(1.0f - (_340 * _340), 0.0f, 1.0f);\n        atten = _346 * _346;\n        if (_305 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _360 = fa_light_texel(param_2);\n            float _370 = _360.w;\n            int param_3 = (li * 4) + 3;\n            float4 _376 = fa_light_texel(param_3);\n            float _377 = _376.x;\n            float cos_inner = _377;\n            if (_377 > 1.5f)\n            {\n                cos_inner = lerp(_370, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_370, cos_inner, dot(-l, normalize(_360.xyz)));\n        }\n    }\n    int _407;\n    if (_311)\n    {\n        _407 = 0;\n    }\n    else\n    {\n        _407 = (_305 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2805 = { l, _302.xyz * atten, atten, 1.0f, dist, _407 };\n    return _2805;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _647;\n    if (i == 0)\n    {\n        _647 = _657_fa_shadow_split.x;\n    }\n    else\n    {\n        float _663;\n        if (i == 1)\n        {\n            _663 = _657_fa_shadow_split.y;\n        }\n        else\n        {\n            float _671;\n            if (i == 2)\n            {\n                _671 = _657_fa_shadow_split.z;\n            }\n            else\n            {\n                _671 = _657_fa_shadow_split.w;\n            }\n            _663 = _671;\n        }\n        _647 = _663;\n    }\n    return _647;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _704 = fa_shadow_depth(param, param_1);\n    float _708;\n    if (conv.x < 0.5f)\n    {\n        _708 = _704;\n    }\n    else\n    {\n        _708 = (conv.y * conv.z) / (conv.z - (_704 * (conv.z - conv.y)));\n    }\n    return _708;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _635 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_635), sin(_635)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _754 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _768 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _754;\n            float2 _787 = fa_shadow_vogel(param_3, param_4, param_5) * _768;\n            float2 param_6 = uv + (_787 * _657_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _799 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_799 < (zr - (length(_787) * plane)))\n            {\n                sum += _799;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _843 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _843; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _843;\n        float param_11 = _754;\n        float2 _862 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_862 * _657_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_862) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_843);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _904 = max(_657_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _909 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _915 = sqrt(1.0f - (_909 * _909));\n    float _923 = min(_915 / max(_909, 0.20000000298023223876953125f), 4.0f);\n    float _928;\n    if (_657_fa_shadow_bias.y > 0.0f)\n    {\n        _928 = _657_fa_shadow_bias.y;\n    }\n    else\n    {\n        _928 = 1.5f * _657_fa_shadow_info[ci].x;\n    }\n    float4 _953 = mul(float4(world + (n * (_928 * _915)), 1.0f), _657_fa_shadow_mat[ci]);\n    float _960 = _953.x;\n    bool _963 = _960 < _657_fa_shadow_rect[ci].x;\n    bool _972;\n    if (!_963)\n    {\n        _972 = _960 > _657_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _972 = _963;\n    }\n    bool _981;\n    if (!_972)\n    {\n        _981 = _953.y < _657_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _981 = _972;\n    }\n    bool _990;\n    if (!_981)\n    {\n        _990 = _953.y > _657_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _990 = _981;\n    }\n    bool _997;\n    if (!_990)\n    {\n        _997 = _953.z > 1.0f;\n    }\n    else\n    {\n        _997 = _990;\n    }\n    if (_997)\n    {\n        return -1.0f;\n    }\n    float _1006;\n    if (_657_fa_shadow_bias.x > 0.0f)\n    {\n        _1006 = _657_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1006 = 1.5f * _657_fa_shadow_info[ci].x;\n    }\n    float2 param = _953.xy;\n    float4 param_1 = _657_fa_shadow_rect[ci];\n    float param_2 = _953.z - ((_1006 * (1.0f + (0.5f * _923))) / _904);\n    float param_3 = _657_fa_shadow_info[ci].x;\n    float param_4 = _904;\n    float param_5 = _904 * 0.25f;\n    float param_6 = ((_657_fa_shadow_info[ci].x * min(_923, 3.0f)) * 0.5f) / _904;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_657_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _657_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_421_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1434 = int(_657_fa_shadow_cfg.x + 0.5f);\n    if (_1434 < 1)\n    {\n        return 1.0f;\n    }\n    float _1450 = dot(world - _657_fa_shadow_eye.xyz, _657_fa_shadow_fwd.xyz);\n    int param = _1434 - 1;\n    if (_1450 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1462 = _1434 > 1;\n    bool _1469;\n    if (_1462)\n    {\n        _1469 = _1450 > _657_fa_shadow_split.x;\n    }\n    else\n    {\n        _1469 = _1462;\n    }\n    if (_1469)\n    {\n        ci = 1;\n    }\n    bool _1473 = _1434 > 2;\n    bool _1480;\n    if (_1473)\n    {\n        _1480 = _1450 > _657_fa_shadow_split.y;\n    }\n    else\n    {\n        _1480 = _1473;\n    }\n    if (_1480)\n    {\n        ci = 2;\n    }\n    bool _1484 = _1434 > 3;\n    bool _1491;\n    if (_1484)\n    {\n        _1491 = _1450 > _657_fa_shadow_split.z;\n    }\n    else\n    {\n        _1491 = _1484;\n    }\n    if (_1491)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1434)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1517 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1517;\n        if (_1517 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_657_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1542;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1542 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1542 = _657_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1561 = _657_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1542, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1572 = clamp((_1450 - (fa_shadow_split_at(param_7) - _1561)) / _1561, 0.0f, 1.0f);\n        if (_1572 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1434)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1593 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1593;\n                if (_1593 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1572);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1065 = _421_fa_pbr.z < 0.5f;\n    bool _1073;\n    if (!_1065)\n    {\n        _1073 = _657_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1073 = _1065;\n    }\n    if (_1073)\n    {\n        return 1.0f;\n    }\n    int param = (int(_657_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1086 = fa_light_texel(param);\n    float _1087 = _1086.x;\n    if (_1087 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1096 = int(_1087 + 0.5f);\n    int param_1 = _1096;\n    float4 _1100 = fa_light_texel(param_1);\n    int param_2 = _1096 + 1;\n    float4 _1105 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1108 = _1100.y;\n    if (_1108 > 0.0f)\n    {\n        float _1125 = 1.0f - smoothstep(0.75f * _1108, _1108, length(world - _657_fa_shadow_eye.xyz));\n        fade = _1125;\n        if (_1125 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1100.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1144 = world - fa_light_texel(param_3).xyz;\n        float3 _1147 = abs(_1144);\n        float _1149 = _1147.x;\n        float _1151 = _1147.y;\n        bool _1152 = _1149 >= _1151;\n        bool _1160;\n        if (_1152)\n        {\n            _1160 = _1149 >= _1147.z;\n        }\n        else\n        {\n            _1160 = _1152;\n        }\n        int _1161;\n        if (_1160)\n        {\n            _1161 = (_1144.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1174;\n            if (_1151 >= _1147.z)\n            {\n                _1174 = (_1144.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1174 = (_1144.z > 0.0f) ? 4 : 5;\n            }\n            _1161 = _1174;\n        }\n        face = _1161;\n    }\n    int _1193 = (_1096 + 2) + (face * 6);\n    int param_4 = _1193;\n    int param_5 = _1193 + 1;\n    int param_6 = _1193 + 3;\n    float4 _1207 = fa_light_texel(param_6);\n    int param_7 = _1193 + 4;\n    float4 _1212 = fa_light_texel(param_7);\n    int param_8 = _1193 + 5;\n    float4 _1217 = fa_light_texel(param_8);\n    float _1229 = _1217.x * max(dot(_1207, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1234 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1257 = clamp(dot(n, _1207.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1280 = min(sqrt(1.0f - (_1257 * _1257)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1207, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1283 = _1105.y;\n    float _1285;\n    if (_1283 > 0.0f)\n    {\n        _1285 = _1283;\n    }\n    else\n    {\n        _1285 = 1.5f * _1229;\n    }\n    float4 _1305 = float4(world + (n * (_1285 * sqrt(1.0f - (_1234 * _1234)))), 1.0f);\n    float _1309 = dot(_1207, _1305);\n    float _1312 = _1217.y;\n    if (_1309 < _1312)\n    {\n        return 1.0f;\n    }\n    float2 _1327 = float2(dot(fa_light_texel(param_4), _1305), dot(fa_light_texel(param_5), _1305)) / _1309.xx;\n    float _1329 = _1327.x;\n    bool _1332 = _1329 < _1212.x;\n    bool _1341;\n    if (!_1332)\n    {\n        _1341 = _1329 > _1212.z;\n    }\n    else\n    {\n        _1341 = _1332;\n    }\n    bool _1350;\n    if (!_1341)\n    {\n        _1350 = _1327.y < _1212.y;\n    }\n    else\n    {\n        _1350 = _1341;\n    }\n    bool _1359;\n    if (!_1350)\n    {\n        _1359 = _1327.y > _1212.w;\n    }\n    else\n    {\n        _1359 = _1350;\n    }\n    if (_1359)\n    {\n        return 1.0f;\n    }\n    float _1365 = _1105.x;\n    float _1367;\n    if (_1365 > 0.0f)\n    {\n        _1367 = _1365;\n    }\n    else\n    {\n        _1367 = 1.5f * _1229;\n    }\n    float2 param_10 = _1327;\n    float4 param_11 = _1212;\n    float param_12 = _1309 - (_1367 * (1.0f + (0.5f * _1280)));\n    float param_13 = _1229;\n    float param_14 = 1.0f;\n    float param_15 = _1217.z * 0.25f;\n    float param_16 = (_1229 * min(_1280, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1312, _1217.z);\n    int param_18 = int(_1100.z + 0.5f);\n    float param_19 = _1100.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _1762 = fa_lm.z > 0.5f;\n    bool _1768;\n    if (_1762)\n    {\n        int param = li;\n        _1768 = fa_light_baked(param);\n    }\n    else\n    {\n        _1768 = _1762;\n    }\n    if (_1768)\n    {\n        int param_1 = li;\n        LightSample _2818 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _2818;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _1791 = fa_light_sample(param_2, param_3);\n    float3 _2825 = _1791.direction;\n    float3 _2820 = _1791.color;\n    float _2827 = _1791.attenuation;\n    float _2822 = _1791.shadow;\n    int _2830 = _1791.type;\n    if ((_2830 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _2825;\n        float _1805 = fa_shadow_factor(param_4, param_5);\n        _2822 = _1805;\n        _2820 *= _1805;\n    }\n    else\n    {\n        bool _1816 = _2830 != 0;\n        bool _1822;\n        if (_1816)\n        {\n            _1822 = _2827 > 0.0f;\n        }\n        else\n        {\n            _1822 = _1816;\n        }\n        if (_1822)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _2825;\n            float _1834 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _2822 = _1834;\n            _2820 *= _1834;\n        }\n    }\n    LightSample _2837 = { _2825, _2820, _2827, _2822, _1791._distance, _2830 };\n    return _2837;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_657_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1617 = int(_657_fa_shadow_cfg.x + 0.5f);\n    float _1627 = dot(world - _657_fa_shadow_eye.xyz, _657_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1632 = _1617 > 0;\n    bool _1641;\n    if (_1632)\n    {\n        int param = _1617 - 1;\n        _1641 = _1627 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1641 = _1632;\n    }\n    if (_1641)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1648 = _1617 > 1;\n        bool _1655;\n        if (_1648)\n        {\n            _1655 = _1627 > _657_fa_shadow_split.x;\n        }\n        else\n        {\n            _1655 = _1648;\n        }\n        if (_1655)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1661 = _1617 > 2;\n        bool _1668;\n        if (_1661)\n        {\n            _1668 = _1627 > _657_fa_shadow_split.y;\n        }\n        else\n        {\n            _1668 = _1661;\n        }\n        if (_1668)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1674 = _1617 > 3;\n        bool _1681;\n        if (_1674)\n        {\n            _1681 = _1627 > _657_fa_shadow_split.z;\n        }\n        else\n        {\n            _1681 = _1674;\n        }\n        if (_1681)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2636 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2636 = -_2636;\n    }\n    float3 _2237 = normalize(_421_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2649 = { fa_world_pos, _2636, fa_world_tangent, fa_uv, fa_vertex_color, _2237, gl_FrontFacing };\n    SurfaceInput param_1 = _2649;\n    Surface _2245 = fa_standard_surface(param_1);\n    float3 _2675 = _2245.albedo;\n    float _2676 = _2245.alpha;\n    float3 _2677 = _2245.normal;\n    float _2678 = _2245.metallic;\n    float _2679 = _2245.roughness;\n    float _2680 = _2245.occlusion;\n    float3 _2681 = _2245.emission;\n    float _2682 = _2245.clearcoat;\n    float _2683 = _2245.clearcoat_roughness;\n    float3 _2684 = _2245.sheen_color;\n    float _2685 = _2245.sheen_roughness;\n    float _2686 = _2245.anisotropy;\n    float _2687 = _2245.anisotropy_rotation;\n    float _2688 = _2245.specular;\n    float _2689 = _2245.ior;\n    float3 _2690 = _2245.specular_color;\n    SurfaceInput _2657 = { fa_world_pos, _2636, fa_world_tangent, fa_uv, fa_vertex_color, _2237, gl_FrontFacing };\n    SurfaceInput param_2 = _2657;\n    Surface param_3 = _2245;\n    surface(param_2, param_3);\n    _2675 = param_3.albedo;\n    _2676 = param_3.alpha;\n    _2677 = param_3.normal;\n    _2678 = param_3.metallic;\n    _2679 = param_3.roughness;\n    _2680 = param_3.occlusion;\n    _2681 = param_3.emission;\n    _2682 = param_3.clearcoat;\n    _2683 = param_3.clearcoat_roughness;\n    _2684 = param_3.sheen_color;\n    _2685 = param_3.sheen_roughness;\n    _2686 = param_3.anisotropy;\n    _2687 = param_3.anisotropy_rotation;\n    _2688 = param_3.specular;\n    _2689 = param_3.ior;\n    _2690 = param_3.specular_color;\n    float3 result;\n    if (_421_fa_emissive.w > 0.5f)\n    {\n        result = _2675;\n    }\n    else\n    {\n        float3 _2266 = _2677;\n        float3 _2267 = normalize(_2266);\n        _2677 = _2267;\n        float3 param_4 = _2267;\n        SurfaceInput _2665 = { fa_world_pos, _2636, fa_world_tangent, fa_uv, fa_vertex_color, _2237, gl_FrontFacing };\n        SurfaceInput param_5 = _2665;\n        Surface _2756 = { _2675, _2676, _2677, _2678, _2679, _2680, _2681, _2682, _2683, _2684, _2685, _2686, _2687, _2688, _2689, _2690 };\n        Surface param_6 = _2756;\n        float3 param_7 = fa_indirect_diffuse(param_4);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _2286 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2286; ln++)\n        {\n            int param_8 = ln;\n            int _2299 = fa_cl_light(param_8);\n            bool _2302 = fa_lm.z > 0.5f;\n            bool _2308;\n            if (_2302)\n            {\n                int param_9 = _2299;\n                _2308 = fa_light_baked(param_9);\n            }\n            else\n            {\n                _2308 = _2302;\n            }\n            if (_2308)\n            {\n                continue;\n            }\n            int param_10 = _2299;\n            float3 param_11 = fa_world_pos;\n            float3 param_12 = _2636;\n            SurfaceInput _2673 = { fa_world_pos, _2636, fa_world_tangent, fa_uv, fa_vertex_color, _2237, gl_FrontFacing };\n            SurfaceInput param_13 = _2673;\n            Surface _2773 = { _2675, _2676, _2677, _2678, _2679, _2680, _2681, _2682, _2683, _2684, _2685, _2686, _2687, _2688, _2689, _2690 };\n            Surface param_14 = _2773;\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    float3 _2335 = result;\n    float3 _2336 = _2335 + _2681;\n    result = _2336;\n    float3 param_16 = _2336;\n    float3 param_17 = fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17);\n    bool _2345 = _421_fa_fog.w > 0.0f;\n    bool _2352;\n    if (!_2345)\n    {\n        _2352 = _421_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2352 = _2345;\n    }\n    if (_2352)\n    {\n        float3 _2361 = fa_world_pos - _421_fa_camera_pos.xyz;\n        float _2367 = dot(_2361, _421_fa_fog_c.xyz);\n        bool _2371 = _421_fa_fog_c.w > 0.5f;\n        float _2372;\n        if (_2371)\n        {\n            _2372 = _2367;\n        }\n        else\n        {\n            _2372 = length(_2361);\n        }\n        float _2384 = _2372 - _421_fa_fog_b.x;\n        if (_2384 > 0.0f)\n        {\n            float _2393 = _421_fa_fog.w * _2384;\n            float tau = _2393 * _2393;\n            if (_421_fa_fog_b.y > 0.0f)\n            {\n                float _2409;\n                if (_2371)\n                {\n                    _2409 = fa_world_pos.y - (_421_fa_fog_c.y * _2367);\n                }\n                else\n                {\n                    _2409 = _421_fa_camera_pos.y;\n                }\n                float _2430 = lerp(_2409, fa_world_pos.y, clamp(_421_fa_fog_b.x / _2372, 0.0f, 1.0f));\n                float _2434 = fa_world_pos.y - _2430;\n                float _2439 = _2430 - _421_fa_fog_b.z;\n                float _2444 = fa_world_pos.y - _421_fa_fog_b.z;\n                bool _2447 = _2439 <= 0.0f;\n                bool _2448 = !_2447;\n                bool _2454;\n                if (_2448)\n                {\n                    _2454 = _421_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2454 = _2447;\n                }\n                float _2455;\n                if (_2454)\n                {\n                    _2455 = _421_fa_fog_b.y;\n                }\n                else\n                {\n                    _2455 = _421_fa_fog_b.y * exp(-min(_421_fa_fog_b.w * _2439, 80.0f));\n                }\n                bool _2482;\n                if (_2448)\n                {\n                    _2482 = _421_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2482 = _2447;\n                }\n                float _2483;\n                if (_2482)\n                {\n                    _2483 = _421_fa_fog_b.y * _2439;\n                }\n                else\n                {\n                    _2483 = (_421_fa_fog_b.y * (1.0f - exp(-min(_421_fa_fog_b.w * _2439, 80.0f)))) / _421_fa_fog_b.w;\n                }\n                bool _2508 = _2444 <= 0.0f;\n                bool _2515;\n                if (!_2508)\n                {\n                    _2515 = _421_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2515 = _2508;\n                }\n                float _2516;\n                if (_2515)\n                {\n                    _2516 = _421_fa_fog_b.y * _2444;\n                }\n                else\n                {\n                    _2516 = (_421_fa_fog_b.y * (1.0f - exp(-min(_421_fa_fog_b.w * _2444, 80.0f)))) / _421_fa_fog_b.w;\n                }\n                float _2543;\n                if (abs(_2434) < 0.001000000047497451305389404296875f)\n                {\n                    _2543 = _2455;\n                }\n                else\n                {\n                    _2543 = (_2516 - _2483) / _2434;\n                }\n                tau += (_2384 * max(_2543, 0.0f));\n            }\n            result = lerp(result, _421_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2676);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_421",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_657",
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
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 8
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_388, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _421_fa_camera_pos : packoffset(c0);\n    float4 _421_fa_ambient : packoffset(c1);\n    float4 _421_fa_base_color : packoffset(c2);\n    float4 _421_fa_emissive : packoffset(c3);\n    float4 _421_fa_model_emissive : packoffset(c4);\n    float4 _421_fa_pbr : packoffset(c5);\n    float4 _421_fa_maps : packoffset(c6);\n    float4 _421_fa_fog : packoffset(c7);\n    float4 _421_fa_fog_b : packoffset(c8);\n    float4 _421_fa_fog_c : packoffset(c9);\n    float4 _421_fa_counts : packoffset(c10);\n    float4 _421_fa_env_sky : packoffset(c11);\n    float4 _421_fa_env_horizon : packoffset(c12);\n    float4 _421_fa_time : packoffset(c13);\n    float4 _421_fa_cl_vpx : packoffset(c14);\n    float4 _421_fa_cl_vpy : packoffset(c15);\n    float4 _421_fa_cl_vpw : packoffset(c16);\n    float4 _421_fa_cl_fwd : packoffset(c17);\n    float4 _421_fa_cl_grid : packoffset(c18);\n    float4 _421_fa_cl_info : packoffset(c19);\n    float4 _421_fa_layers_a : packoffset(c20);\n    float4 _421_fa_layers_b : packoffset(c21);\n    float4 _421_fa_layers_c : packoffset(c22);\n    float4 _421_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _657_fa_shadow_mat[4] : packoffset(c0);\n    float4 _657_fa_shadow_rect[4] : packoffset(c16);\n    float4 _657_fa_shadow_info[4] : packoffset(c20);\n    float4 _657_fa_shadow_split : packoffset(c24);\n    float4 _657_fa_shadow_cfg : packoffset(c25);\n    float4 _657_fa_shadow_bias : packoffset(c26);\n    float4 _657_fa_shadow_eye : packoffset(c27);\n    float4 _657_fa_shadow_fwd : packoffset(c28);\n    float4 _657_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_irr_tex : register(t6);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t8);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    bool _426 = _421_fa_cl_info.x < 0.0f;\n    bool _433;\n    if (!_426)\n    {\n        _433 = _421_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _433 = _426;\n    }\n    bool _441;\n    if (!_433)\n    {\n        _441 = _421_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _441 = _433;\n    }\n    bool _448;\n    if (!_441)\n    {\n        _448 = _421_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _448 = _441;\n    }\n    bool _455;\n    if (!_448)\n    {\n        _455 = _421_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _455 = _448;\n    }\n    if (_455)\n    {\n        return int2(0, 0);\n    }\n    float4 _465 = float4(world_pos, 1.0f);\n    float _472 = dot(_421_fa_cl_vpw, _465);\n    if (!(_472 > 9.9999999747524270787835121154785e-07f))\n    {\n        return int2(0, 0);\n    }\n    float2 _494 = float2(dot(_421_fa_cl_vpx, _465), dot(_421_fa_cl_vpy, _465)) / _472.xx;\n    int _498 = int(_421_fa_cl_grid.x);\n    int _502 = int(_421_fa_cl_grid.y);\n    int param = (int(_421_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_421_fa_cl_fwd.xyz, world_pos) + _421_fa_cl_fwd.w, _421_fa_cl_grid.w) / _421_fa_cl_grid.w) * _421_fa_cl_grid.z)), 0, int(_421_fa_cl_info.y) - 1) * _502) + clamp(int(floor(((_494.y * 0.5f) + 0.5f) * _421_fa_cl_grid.y)), 0, _502 - 1)) * _498)) + clamp(int(floor(((_494.x * 0.5f) + 0.5f) * _421_fa_cl_grid.x)), 0, _498 - 1);\n    float4 _573 = fa_light_texel(param);\n    return int2(int(_573.x), int(_573.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_421_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1735 = fa_cluster_lookup(param);\n    fa_cl_slot = _1735.x;\n    fa_cl_local = _1735.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _1899 = fa_linear_to_srgb(param);\n        c = _1899;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _1907 = fa_srgb_to_linear(param_1);\n            c = _1907;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _185;\n    if (i.front_facing)\n    {\n        _185 = i.world_normal;\n    }\n    else\n    {\n        _185 = -i.world_normal;\n    }\n    float3 _209 = normalize(i.world_tangent.xyz - (_185 * dot(_185, i.world_tangent.xyz)));\n    float3 _237 = normalize(((_209 * m.x) + ((cross(_185, _209) * i.world_tangent.w) * m.y)) + (_185 * m.z));\n    float3 _240;\n    if (i.front_facing)\n    {\n        _240 = _237;\n    }\n    else\n    {\n        _240 = -_237;\n    }\n    return _240;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _421_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1938 = fa_tex_fix(param_2, param_3);\n    float4 _2925 = base_t;\n    _2925.x = _1938.x;\n    _2925.y = _1938.y;\n    _2925.z = _1938.z;\n    base_t = _2925;\n    float4 _1952 = (_2925 * _421_fa_base_color) * i.vertex_color;\n    float3 _2840 = i.world_normal;\n    if (_421_fa_maps.z > 0.5f)\n    {\n        float param_4 = _421_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1984 = fa_tex_fix(param_6, param_7);\n        float3 _1988 = (_1984 * 2.0f) - 1.0f.xxx;\n        float2 _1993 = _1988.xy * _421_fa_maps.x;\n        float3 _2933 = _1988;\n        _2933.x = _1993.x;\n        _2933.y = _1993.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2933;\n        _2840 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _421_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2022 = fa_tex_fix(param_12, param_13);\n    float4 _2936 = mrt;\n    _2936.x = _2022.x;\n    _2936.y = _2022.y;\n    _2936.z = _2022.z;\n    mrt = _2936;\n    float4 _2051 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _421_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _2051.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2063 = fa_tex_fix(param_16, param_17);\n    float param_18 = _421_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2093 = fa_tex_fix(param_20, param_21);\n    float _2845 = _421_fa_layers_a.x;\n    float _2846 = _421_fa_layers_a.y;\n    float _2849 = _421_fa_layers_a.z;\n    float _2848 = _421_fa_layers_b.w;\n    float _2851 = _421_fa_layers_c.x;\n    if (_421_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_421_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _2845 *= _2063.y;\n            _2846 *= _2063.z;\n            _2848 *= _2051.w;\n        }\n        if (_421_fa_layers_c.z > 1.5f)\n        {\n            _2849 *= mrt.x;\n            _2851 *= mrt.w;\n        }\n    }\n    Surface _2870 = { _1952.xyz, _1952.w, _2840, clamp(_421_fa_pbr.x * _2022.z, 0.0f, 1.0f), clamp(_421_fa_pbr.y * _2022.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_421_fa_maps.y * (_2063.x - 1.0f)), _421_fa_emissive.xyz + (_421_fa_model_emissive.xyz * _2093), _2845, _2846, _421_fa_layers_b.xyz, _2848, _2849, _421_fa_layers_a.w, _2851, _421_fa_layers_c.y, _421_fa_layers_d.xyz };\n    return _2870;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_421_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _421_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_421_fa_cl_info.x) + int(_421_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    int param = li * 4;\n    float4 _296 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    float4 _302 = fa_light_texel(param_1);\n    float _305 = _302.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _311 = _305 < 0.5f;\n    float3 l;\n    if (_311)\n    {\n        l = normalize(_296.xyz);\n    }\n    else\n    {\n        float3 _323 = _296.xyz - world_pos;\n        float _325 = length(_323);\n        dist = _325;\n        l = _323 / max(_325, 9.9999997473787516355514526367188e-05f).xxx;\n        float _340 = _325 / max(_296.w, 0.001000000047497451305389404296875f);\n        float _346 = clamp(1.0f - (_340 * _340), 0.0f, 1.0f);\n        atten = _346 * _346;\n        if (_305 > 1.5f)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _360 = fa_light_texel(param_2);\n            float _370 = _360.w;\n            int param_3 = (li * 4) + 3;\n            float4 _376 = fa_light_texel(param_3);\n            float _377 = _376.x;\n            float cos_inner = _377;\n            if (_377 > 1.5f)\n            {\n                cos_inner = lerp(_370, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_370, cos_inner, dot(-l, normalize(_360.xyz)));\n        }\n    }\n    int _407;\n    if (_311)\n    {\n        _407 = 0;\n    }\n    else\n    {\n        _407 = (_305 > 1.5f) ? 2 : 1;\n    }\n    LightSample _2805 = { l, _302.xyz * atten, atten, 1.0f, dist, _407 };\n    return _2805;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _647;\n    if (i == 0)\n    {\n        _647 = _657_fa_shadow_split.x;\n    }\n    else\n    {\n        float _663;\n        if (i == 1)\n        {\n            _663 = _657_fa_shadow_split.y;\n        }\n        else\n        {\n            float _671;\n            if (i == 2)\n            {\n                _671 = _657_fa_shadow_split.z;\n            }\n            else\n            {\n                _671 = _657_fa_shadow_split.w;\n            }\n            _663 = _671;\n        }\n        _647 = _663;\n    }\n    return _647;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _704 = fa_shadow_depth(param, param_1);\n    float _708;\n    if (conv.x < 0.5f)\n    {\n        _708 = _704;\n    }\n    else\n    {\n        _708 = (conv.y * conv.z) / (conv.z - (_704 * (conv.z - conv.y)));\n    }\n    return _708;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _635 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_635), sin(_635)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _754 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _768 = clamp((k * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _754;\n            float2 _787 = fa_shadow_vogel(param_3, param_4, param_5) * _768;\n            float2 param_6 = uv + (_787 * _657_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _799 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_799 < (zr - (length(_787) * plane)))\n            {\n                sum += _799;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0f) * unit) * k) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _843 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _843; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _843;\n        float param_11 = _754;\n        float2 _862 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_862 * _657_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_862) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_843);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _904 = max(_657_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _909 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _915 = sqrt(1.0f - (_909 * _909));\n    float _923 = min(_915 / max(_909, 0.20000000298023223876953125f), 4.0f);\n    float _928;\n    if (_657_fa_shadow_bias.y > 0.0f)\n    {\n        _928 = _657_fa_shadow_bias.y;\n    }\n    else\n    {\n        _928 = 1.5f * _657_fa_shadow_info[ci].x;\n    }\n    float4 _953 = mul(float4(world + (n * (_928 * _915)), 1.0f), _657_fa_shadow_mat[ci]);\n    float _960 = _953.x;\n    bool _963 = _960 < _657_fa_shadow_rect[ci].x;\n    bool _972;\n    if (!_963)\n    {\n        _972 = _960 > _657_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _972 = _963;\n    }\n    bool _981;\n    if (!_972)\n    {\n        _981 = _953.y < _657_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _981 = _972;\n    }\n    bool _990;\n    if (!_981)\n    {\n        _990 = _953.y > _657_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _990 = _981;\n    }\n    bool _997;\n    if (!_990)\n    {\n        _997 = _953.z > 1.0f;\n    }\n    else\n    {\n        _997 = _990;\n    }\n    if (_997)\n    {\n        return -1.0f;\n    }\n    float _1006;\n    if (_657_fa_shadow_bias.x > 0.0f)\n    {\n        _1006 = _657_fa_shadow_bias.x;\n    }\n    else\n    {\n        _1006 = 1.5f * _657_fa_shadow_info[ci].x;\n    }\n    float2 param = _953.xy;\n    float4 param_1 = _657_fa_shadow_rect[ci];\n    float param_2 = _953.z - ((_1006 * (1.0f + (0.5f * _923))) / _904);\n    float param_3 = _657_fa_shadow_info[ci].x;\n    float param_4 = _904;\n    float param_5 = _904 * 0.25f;\n    float param_6 = ((_657_fa_shadow_info[ci].x * min(_923, 3.0f)) * 0.5f) / _904;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_657_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _657_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_421_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _1434 = int(_657_fa_shadow_cfg.x + 0.5f);\n    if (_1434 < 1)\n    {\n        return 1.0f;\n    }\n    float _1450 = dot(world - _657_fa_shadow_eye.xyz, _657_fa_shadow_fwd.xyz);\n    int param = _1434 - 1;\n    if (_1450 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _1462 = _1434 > 1;\n    bool _1469;\n    if (_1462)\n    {\n        _1469 = _1450 > _657_fa_shadow_split.x;\n    }\n    else\n    {\n        _1469 = _1462;\n    }\n    if (_1469)\n    {\n        ci = 1;\n    }\n    bool _1473 = _1434 > 2;\n    bool _1480;\n    if (_1473)\n    {\n        _1480 = _1450 > _657_fa_shadow_split.y;\n    }\n    else\n    {\n        _1480 = _1473;\n    }\n    if (_1480)\n    {\n        ci = 2;\n    }\n    bool _1484 = _1434 > 3;\n    bool _1491;\n    if (_1484)\n    {\n        _1491 = _1450 > _657_fa_shadow_split.z;\n    }\n    else\n    {\n        _1491 = _1484;\n    }\n    if (_1491)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1434)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1517 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1517;\n        if (_1517 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_657_fa_shadow_cfg.y > 0.0f)\n    {\n        float _1542;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1542 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1542 = _657_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1561 = _657_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _1542, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _1572 = clamp((_1450 - (fa_shadow_split_at(param_7) - _1561)) / _1561, 0.0f, 1.0f);\n        if (_1572 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _1434)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1593 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1593;\n                if (_1593 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _1572);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 world, float3 n, float3 l)\n{\n    bool _1065 = _421_fa_pbr.z < 0.5f;\n    bool _1073;\n    if (!_1065)\n    {\n        _1073 = _657_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _1073 = _1065;\n    }\n    if (_1073)\n    {\n        return 1.0f;\n    }\n    int param = (int(_657_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _1086 = fa_light_texel(param);\n    float _1087 = _1086.x;\n    if (_1087 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _1096 = int(_1087 + 0.5f);\n    int param_1 = _1096;\n    float4 _1100 = fa_light_texel(param_1);\n    int param_2 = _1096 + 1;\n    float4 _1105 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _1108 = _1100.y;\n    if (_1108 > 0.0f)\n    {\n        float _1125 = 1.0f - smoothstep(0.75f * _1108, _1108, length(world - _657_fa_shadow_eye.xyz));\n        fade = _1125;\n        if (_1125 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_1100.x > 1.5f)\n    {\n        int param_3 = li * 4;\n        float3 _1144 = world - fa_light_texel(param_3).xyz;\n        float3 _1147 = abs(_1144);\n        float _1149 = _1147.x;\n        float _1151 = _1147.y;\n        bool _1152 = _1149 >= _1151;\n        bool _1160;\n        if (_1152)\n        {\n            _1160 = _1149 >= _1147.z;\n        }\n        else\n        {\n            _1160 = _1152;\n        }\n        int _1161;\n        if (_1160)\n        {\n            _1161 = (_1144.x > 0.0f) ? 0 : 1;\n        }\n        else\n        {\n            int _1174;\n            if (_1151 >= _1147.z)\n            {\n                _1174 = (_1144.y > 0.0f) ? 2 : 3;\n            }\n            else\n            {\n                _1174 = (_1144.z > 0.0f) ? 4 : 5;\n            }\n            _1161 = _1174;\n        }\n        face = _1161;\n    }\n    int _1193 = (_1096 + 2) + (face * 6);\n    int param_4 = _1193;\n    int param_5 = _1193 + 1;\n    int param_6 = _1193 + 3;\n    float4 _1207 = fa_light_texel(param_6);\n    int param_7 = _1193 + 4;\n    float4 _1212 = fa_light_texel(param_7);\n    int param_8 = _1193 + 5;\n    float4 _1217 = fa_light_texel(param_8);\n    float _1229 = _1217.x * max(dot(_1207, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _1234 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _1257 = clamp(dot(n, _1207.xyz), -1.0f, 1.0f);\n    int param_9 = li * 4;\n    float _1280 = min(sqrt(1.0f - (_1257 * _1257)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1207, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _1283 = _1105.y;\n    float _1285;\n    if (_1283 > 0.0f)\n    {\n        _1285 = _1283;\n    }\n    else\n    {\n        _1285 = 1.5f * _1229;\n    }\n    float4 _1305 = float4(world + (n * (_1285 * sqrt(1.0f - (_1234 * _1234)))), 1.0f);\n    float _1309 = dot(_1207, _1305);\n    float _1312 = _1217.y;\n    if (_1309 < _1312)\n    {\n        return 1.0f;\n    }\n    float2 _1327 = float2(dot(fa_light_texel(param_4), _1305), dot(fa_light_texel(param_5), _1305)) / _1309.xx;\n    float _1329 = _1327.x;\n    bool _1332 = _1329 < _1212.x;\n    bool _1341;\n    if (!_1332)\n    {\n        _1341 = _1329 > _1212.z;\n    }\n    else\n    {\n        _1341 = _1332;\n    }\n    bool _1350;\n    if (!_1341)\n    {\n        _1350 = _1327.y < _1212.y;\n    }\n    else\n    {\n        _1350 = _1341;\n    }\n    bool _1359;\n    if (!_1350)\n    {\n        _1359 = _1327.y > _1212.w;\n    }\n    else\n    {\n        _1359 = _1350;\n    }\n    if (_1359)\n    {\n        return 1.0f;\n    }\n    float _1365 = _1105.x;\n    float _1367;\n    if (_1365 > 0.0f)\n    {\n        _1367 = _1365;\n    }\n    else\n    {\n        _1367 = 1.5f * _1229;\n    }\n    float2 param_10 = _1327;\n    float4 param_11 = _1212;\n    float param_12 = _1309 - (_1367 * (1.0f + (0.5f * _1280)));\n    float param_13 = _1229;\n    float param_14 = 1.0f;\n    float param_15 = _1217.z * 0.25f;\n    float param_16 = (_1229 * min(_1280, 3.0f)) * 0.5f;\n    float3 param_17 = float3(1.0f, _1312, _1217.z);\n    int param_18 = int(_1100.z + 0.5f);\n    float param_19 = _1100.w;\n    return lerp(1.0f, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _1762 = fa_lm.z > 0.5f;\n    bool _1768;\n    if (_1762)\n    {\n        int param = li;\n        _1768 = fa_light_baked(param);\n    }\n    else\n    {\n        _1768 = _1762;\n    }\n    if (_1768)\n    {\n        int param_1 = li;\n        LightSample _2818 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _2818;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _1791 = fa_light_sample(param_2, param_3);\n    float3 _2825 = _1791.direction;\n    float3 _2820 = _1791.color;\n    float _2827 = _1791.attenuation;\n    float _2822 = _1791.shadow;\n    int _2830 = _1791.type;\n    if ((_2830 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _2825;\n        float _1805 = fa_shadow_factor(param_4, param_5);\n        _2822 = _1805;\n        _2820 *= _1805;\n    }\n    else\n    {\n        bool _1816 = _2830 != 0;\n        bool _1822;\n        if (_1816)\n        {\n            _1822 = _2827 > 0.0f;\n        }\n        else\n        {\n            _1822 = _1816;\n        }\n        if (_1822)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _2825;\n            float _1834 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _2822 = _1834;\n            _2820 *= _1834;\n        }\n    }\n    LightSample _2837 = { _2825, _2820, _2827, _2822, _1791._distance, _2830 };\n    return _2837;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_657_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _1617 = int(_657_fa_shadow_cfg.x + 0.5f);\n    float _1627 = dot(world - _657_fa_shadow_eye.xyz, _657_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _1632 = _1617 > 0;\n    bool _1641;\n    if (_1632)\n    {\n        int param = _1617 - 1;\n        _1641 = _1627 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1641 = _1632;\n    }\n    if (_1641)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _1648 = _1617 > 1;\n        bool _1655;\n        if (_1648)\n        {\n            _1655 = _1627 > _657_fa_shadow_split.x;\n        }\n        else\n        {\n            _1655 = _1648;\n        }\n        if (_1655)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _1661 = _1617 > 2;\n        bool _1668;\n        if (_1661)\n        {\n            _1668 = _1627 > _657_fa_shadow_split.y;\n        }\n        else\n        {\n            _1668 = _1661;\n        }\n        if (_1668)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _1674 = _1617 > 3;\n        bool _1681;\n        if (_1674)\n        {\n            _1681 = _1627 > _657_fa_shadow_split.z;\n        }\n        else\n        {\n            _1681 = _1674;\n        }\n        if (_1681)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _2636 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2636 = -_2636;\n    }\n    float3 _2237 = normalize(_421_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _2649 = { fa_world_pos, _2636, fa_world_tangent, fa_uv, fa_vertex_color, _2237, gl_FrontFacing };\n    SurfaceInput param_1 = _2649;\n    Surface _2245 = fa_standard_surface(param_1);\n    float3 _2675 = _2245.albedo;\n    float _2676 = _2245.alpha;\n    float3 _2677 = _2245.normal;\n    float _2678 = _2245.metallic;\n    float _2679 = _2245.roughness;\n    float _2680 = _2245.occlusion;\n    float3 _2681 = _2245.emission;\n    float _2682 = _2245.clearcoat;\n    float _2683 = _2245.clearcoat_roughness;\n    float3 _2684 = _2245.sheen_color;\n    float _2685 = _2245.sheen_roughness;\n    float _2686 = _2245.anisotropy;\n    float _2687 = _2245.anisotropy_rotation;\n    float _2688 = _2245.specular;\n    float _2689 = _2245.ior;\n    float3 _2690 = _2245.specular_color;\n    SurfaceInput _2657 = { fa_world_pos, _2636, fa_world_tangent, fa_uv, fa_vertex_color, _2237, gl_FrontFacing };\n    SurfaceInput param_2 = _2657;\n    Surface param_3 = _2245;\n    surface(param_2, param_3);\n    _2675 = param_3.albedo;\n    _2676 = param_3.alpha;\n    _2677 = param_3.normal;\n    _2678 = param_3.metallic;\n    _2679 = param_3.roughness;\n    _2680 = param_3.occlusion;\n    _2681 = param_3.emission;\n    _2682 = param_3.clearcoat;\n    _2683 = param_3.clearcoat_roughness;\n    _2684 = param_3.sheen_color;\n    _2685 = param_3.sheen_roughness;\n    _2686 = param_3.anisotropy;\n    _2687 = param_3.anisotropy_rotation;\n    _2688 = param_3.specular;\n    _2689 = param_3.ior;\n    _2690 = param_3.specular_color;\n    float3 result;\n    if (_421_fa_emissive.w > 0.5f)\n    {\n        result = _2675;\n    }\n    else\n    {\n        float3 _2266 = _2677;\n        float3 _2267 = normalize(_2266);\n        _2677 = _2267;\n        float3 param_4 = _2267;\n        SurfaceInput _2665 = { fa_world_pos, _2636, fa_world_tangent, fa_uv, fa_vertex_color, _2237, gl_FrontFacing };\n        SurfaceInput param_5 = _2665;\n        Surface _2756 = { _2675, _2676, _2677, _2678, _2679, _2680, _2681, _2682, _2683, _2684, _2685, _2686, _2687, _2688, _2689, _2690 };\n        Surface param_6 = _2756;\n        float3 param_7 = fa_indirect_diffuse(param_4);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _2286 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2286; ln++)\n        {\n            int param_8 = ln;\n            int _2299 = fa_cl_light(param_8);\n            bool _2302 = fa_lm.z > 0.5f;\n            bool _2308;\n            if (_2302)\n            {\n                int param_9 = _2299;\n                _2308 = fa_light_baked(param_9);\n            }\n            else\n            {\n                _2308 = _2302;\n            }\n            if (_2308)\n            {\n                continue;\n            }\n            int param_10 = _2299;\n            float3 param_11 = fa_world_pos;\n            float3 param_12 = _2636;\n            SurfaceInput _2673 = { fa_world_pos, _2636, fa_world_tangent, fa_uv, fa_vertex_color, _2237, gl_FrontFacing };\n            SurfaceInput param_13 = _2673;\n            Surface _2773 = { _2675, _2676, _2677, _2678, _2679, _2680, _2681, _2682, _2683, _2684, _2685, _2686, _2687, _2688, _2689, _2690 };\n            Surface param_14 = _2773;\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    float3 _2335 = result;\n    float3 _2336 = _2335 + _2681;\n    result = _2336;\n    float3 param_16 = _2336;\n    float3 param_17 = fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17);\n    bool _2345 = _421_fa_fog.w > 0.0f;\n    bool _2352;\n    if (!_2345)\n    {\n        _2352 = _421_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2352 = _2345;\n    }\n    if (_2352)\n    {\n        float3 _2361 = fa_world_pos - _421_fa_camera_pos.xyz;\n        float _2367 = dot(_2361, _421_fa_fog_c.xyz);\n        bool _2371 = _421_fa_fog_c.w > 0.5f;\n        float _2372;\n        if (_2371)\n        {\n            _2372 = _2367;\n        }\n        else\n        {\n            _2372 = length(_2361);\n        }\n        float _2384 = _2372 - _421_fa_fog_b.x;\n        if (_2384 > 0.0f)\n        {\n            float _2393 = _421_fa_fog.w * _2384;\n            float tau = _2393 * _2393;\n            if (_421_fa_fog_b.y > 0.0f)\n            {\n                float _2409;\n                if (_2371)\n                {\n                    _2409 = fa_world_pos.y - (_421_fa_fog_c.y * _2367);\n                }\n                else\n                {\n                    _2409 = _421_fa_camera_pos.y;\n                }\n                float _2430 = lerp(_2409, fa_world_pos.y, clamp(_421_fa_fog_b.x / _2372, 0.0f, 1.0f));\n                float _2434 = fa_world_pos.y - _2430;\n                float _2439 = _2430 - _421_fa_fog_b.z;\n                float _2444 = fa_world_pos.y - _421_fa_fog_b.z;\n                bool _2447 = _2439 <= 0.0f;\n                bool _2448 = !_2447;\n                bool _2454;\n                if (_2448)\n                {\n                    _2454 = _421_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2454 = _2447;\n                }\n                float _2455;\n                if (_2454)\n                {\n                    _2455 = _421_fa_fog_b.y;\n                }\n                else\n                {\n                    _2455 = _421_fa_fog_b.y * exp(-min(_421_fa_fog_b.w * _2439, 80.0f));\n                }\n                bool _2482;\n                if (_2448)\n                {\n                    _2482 = _421_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2482 = _2447;\n                }\n                float _2483;\n                if (_2482)\n                {\n                    _2483 = _421_fa_fog_b.y * _2439;\n                }\n                else\n                {\n                    _2483 = (_421_fa_fog_b.y * (1.0f - exp(-min(_421_fa_fog_b.w * _2439, 80.0f)))) / _421_fa_fog_b.w;\n                }\n                bool _2508 = _2444 <= 0.0f;\n                bool _2515;\n                if (!_2508)\n                {\n                    _2515 = _421_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2515 = _2508;\n                }\n                float _2516;\n                if (_2515)\n                {\n                    _2516 = _421_fa_fog_b.y * _2444;\n                }\n                else\n                {\n                    _2516 = (_421_fa_fog_b.y * (1.0f - exp(-min(_421_fa_fog_b.w * _2444, 80.0f)))) / _421_fa_fog_b.w;\n                }\n                float _2543;\n                if (abs(_2434) < 0.001000000047497451305389404296875f)\n                {\n                    _2543 = _2455;\n                }\n                else\n                {\n                    _2543 = (_2516 - _2483) / _2434;\n                }\n                tau += (_2384 * max(_2543, 0.0f));\n            }\n            result = lerp(result, _421_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _2676);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_421",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_657",
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
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 8
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
