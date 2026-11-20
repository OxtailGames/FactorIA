{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "df130aaeb5c0790af276010723d2798f8fdace693dbde21948e5a037edff24ef",
  "slang": "metal_macos",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_270, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415)\n{\n    bool _420 = _415.fa_cl_info.x < 0.0;\n    bool _427;\n    if (!_420)\n    {\n        _427 = _415.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _427 = _420;\n    }\n    bool _435;\n    if (!_427)\n    {\n        _435 = _415.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _435 = _427;\n    }\n    bool _442;\n    if (!_435)\n    {\n        _442 = _415.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _442 = _435;\n    }\n    bool _449;\n    if (!_442)\n    {\n        _449 = _415.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _449 = _442;\n    }\n    if (_449)\n    {\n        return int2(0);\n    }\n    float4 _459 = float4(world_pos, 1.0);\n    float _466 = dot(_415.fa_cl_vpw, _459);\n    if (!(_466 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _488 = float2(dot(_415.fa_cl_vpx, _459), dot(_415.fa_cl_vpy, _459)) / float2(_466);\n    int _492 = int(_415.fa_cl_grid.x);\n    int _496 = int(_415.fa_cl_grid.y);\n    int param = (int(_415.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_415.fa_cl_fwd.xyz, world_pos) + _415.fa_cl_fwd.w, _415.fa_cl_grid.w) / _415.fa_cl_grid.w) * _415.fa_cl_grid.z)), 0, int(_415.fa_cl_info.y) - 1) * _496) + clamp(int(floor(((_488.y * 0.5) + 0.5) * _415.fa_cl_grid.y)), 0, _496 - 1)) * _492)) + clamp(int(floor(((_488.x * 0.5) + 0.5) * _415.fa_cl_grid.x)), 0, _492 - 1);\n    float4 _567 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_567.x), int(_567.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_415.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1729 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _415);\n    fa_cl_slot = _1729.x;\n    fa_cl_local = _1729.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1914 = fa_linear_to_srgb(param);\n        c = _1914;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1922 = fa_srgb_to_linear(param_1);\n            c = _1922;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _179;\n    if (bool(i.front_facing))\n    {\n        _179 = i.world_normal;\n    }\n    else\n    {\n        _179 = -i.world_normal;\n    }\n    float3 _203 = fast::normalize(i.world_tangent.xyz - (_179 * dot(_179, i.world_tangent.xyz)));\n    float3 _231 = fast::normalize(((_203 * m.x) + ((cross(_179, _203) * i.world_tangent.w) * m.y)) + (_179 * m.z));\n    float3 _234;\n    if (bool(i.front_facing))\n    {\n        _234 = _231;\n    }\n    else\n    {\n        _234 = -_231;\n    }\n    return _234;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _415, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _415.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1953 = fa_tex_fix(param_2, param_3);\n    float4 _2915 = base_t;\n    _2915.x = _1953.x;\n    _2915.y = _1953.y;\n    _2915.z = _1953.z;\n    base_t = _2915;\n    float4 _1967 = (_2915 * _415.fa_base_color) * i.vertex_color;\n    float3 _2830 = i.world_normal;\n    if (_415.fa_maps.z > 0.5)\n    {\n        float param_4 = _415.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1999 = fa_tex_fix(param_6, param_7);\n        float3 _2003 = (_1999 * 2.0) - float3(1.0);\n        float2 _2008 = _2003.xy * _415.fa_maps.x;\n        float3 _2923 = _2003;\n        _2923.x = _2008.x;\n        _2923.y = _2008.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2923;\n        _2830 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _415.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2037 = fa_tex_fix(param_12, param_13);\n    float4 _2926 = mrt;\n    _2926.x = _2037.x;\n    _2926.y = _2037.y;\n    _2926.z = _2037.z;\n    mrt = _2926;\n    float4 _2066 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _415.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2066.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2078 = fa_tex_fix(param_16, param_17);\n    float param_18 = _415.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2108 = fa_tex_fix(param_20, param_21);\n    float _2835 = _415.fa_layers_a.x;\n    float _2836 = _415.fa_layers_a.y;\n    float _2839 = _415.fa_layers_a.z;\n    float _2838 = _415.fa_layers_b.w;\n    float _2841 = _415.fa_layers_c.x;\n    if (_415.fa_layers_c.z > 0.5)\n    {\n        if (mod(_415.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2835 *= _2078.y;\n            _2836 *= _2078.z;\n            _2838 *= _2066.w;\n        }\n        if (_415.fa_layers_c.z > 1.5)\n        {\n            _2839 *= mrt.x;\n            _2841 *= mrt.w;\n        }\n    }\n    return Surface{ _1967.xyz, _1967.w, _2830, fast::clamp(_415.fa_pbr.x * _2037.z, 0.0, 1.0), fast::clamp(_415.fa_pbr.y * _2037.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_415.fa_maps.y * (_2078.x - 1.0)), _415.fa_emissive.xyz + (_415.fa_model_emissive.xyz * _2108), _2835, _2836, _415.fa_layers_b.xyz, _2838, _2839, _415.fa_layers_a.w, _2841, _415.fa_layers_c.y, _415.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _415, texturecube<float> fa_irr_tex, sampler fa_env_smp)\n{\n    if (_415.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _415.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _415, texturecube<float> fa_irr_tex, sampler fa_env_smp, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _415, fa_irr_tex, fa_env_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415)\n{\n    int param = (int(_415.fa_cl_info.x) + int(_415.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _415);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _290 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _296 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _299 = _296.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _305 = _299 < 0.5;\n    float3 l;\n    if (_305)\n    {\n        l = fast::normalize(_290.xyz);\n    }\n    else\n    {\n        float3 _317 = _290.xyz - world_pos;\n        float _319 = length(_317);\n        dist = _319;\n        l = _317 / float3(fast::max(_319, 9.9999997473787516355514526367188e-05));\n        float _334 = _319 / fast::max(_290.w, 0.001000000047497451305389404296875);\n        float _340 = fast::clamp(1.0 - (_334 * _334), 0.0, 1.0);\n        atten = _340 * _340;\n        if (_299 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _354 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _364 = _354.w;\n            int param_3 = (li * 4) + 3;\n            float4 _370 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _371 = _370.x;\n            float cos_inner = _371;\n            if (_371 > 1.5)\n            {\n                cos_inner = mix(_364, 1.0, 0.25);\n            }\n            atten *= smoothstep(_364, cos_inner, dot(-l, fast::normalize(_354.xyz)));\n        }\n    }\n    int _401;\n    if (_305)\n    {\n        _401 = 0;\n    }\n    else\n    {\n        _401 = (_299 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _296.xyz * atten, atten, 1.0, dist, _401 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _651)\n{\n    float _641;\n    if (i == 0)\n    {\n        _641 = _651.fa_shadow_split.x;\n    }\n    else\n    {\n        float _657;\n        if (i == 1)\n        {\n            _657 = _651.fa_shadow_split.y;\n        }\n        else\n        {\n            float _665;\n            if (i == 2)\n            {\n                _665 = _651.fa_shadow_split.z;\n            }\n            else\n            {\n                _665 = _651.fa_shadow_split.w;\n            }\n            _657 = _665;\n        }\n        _641 = _657;\n    }\n    return _641;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _698 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _702;\n    if (conv.x < 0.5)\n    {\n        _702 = _698;\n    }\n    else\n    {\n        _702 = (conv.y * conv.z) / (conv.z - (_698 * (conv.z - conv.y)));\n    }\n    return _702;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _629 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_629), sin(_629)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _651, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _748 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _762 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _748;\n            float2 _781 = fa_shadow_vogel(param_3, param_4, param_5) * _762;\n            float2 param_6 = uv + (_781 * _651.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _793 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_793 < (zr - (length(_781) * plane)))\n            {\n                sum += _793;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _837 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _837; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _837;\n        float param_11 = _748;\n        float2 _856 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_856 * _651.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_856) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_837);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _651, texture2d<float> fa_shadow_tex)\n{\n    float _898 = fast::max(_651.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _903 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _909 = sqrt(1.0 - (_903 * _903));\n    float _917 = fast::min(_909 / fast::max(_903, 0.20000000298023223876953125), 4.0);\n    float _922;\n    if (_651.fa_shadow_bias.y > 0.0)\n    {\n        _922 = _651.fa_shadow_bias.y;\n    }\n    else\n    {\n        _922 = 1.5 * _651.fa_shadow_info[ci].x;\n    }\n    float4 _947 = _651.fa_shadow_mat[ci] * float4(world + (n * (_922 * _909)), 1.0);\n    float _954 = _947.x;\n    bool _957 = _954 < _651.fa_shadow_rect[ci].x;\n    bool _966;\n    if (!_957)\n    {\n        _966 = _954 > _651.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _966 = _957;\n    }\n    bool _975;\n    if (!_966)\n    {\n        _975 = _947.y < _651.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _975 = _966;\n    }\n    bool _984;\n    if (!_975)\n    {\n        _984 = _947.y > _651.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _984 = _975;\n    }\n    bool _991;\n    if (!_984)\n    {\n        _991 = _947.z > 1.0;\n    }\n    else\n    {\n        _991 = _984;\n    }\n    if (_991)\n    {\n        return -1.0;\n    }\n    float _1000;\n    if (_651.fa_shadow_bias.x > 0.0)\n    {\n        _1000 = _651.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1000 = 1.5 * _651.fa_shadow_info[ci].x;\n    }\n    float2 param = _947.xy;\n    float4 param_1 = _651.fa_shadow_rect[ci];\n    float param_2 = _947.z - ((_1000 * (1.0 + (0.5 * _917))) / _898);\n    float param_3 = _651.fa_shadow_info[ci].x;\n    float param_4 = _898;\n    float param_5 = _898 * 0.25;\n    float param_6 = ((_651.fa_shadow_info[ci].x * fast::min(_917, 3.0)) * 0.5) / _898;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_651.fa_shadow_cfg.z + 0.5);\n    float param_9 = _651.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _651, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread float4& gl_FragCoord, constant fa_shadows& _651, texture2d<float> fa_shadow_tex)\n{\n    if (_415.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1428 = int(_651.fa_shadow_cfg.x + 0.5);\n    if (_1428 < 1)\n    {\n        return 1.0;\n    }\n    float _1444 = dot(world - _651.fa_shadow_eye.xyz, _651.fa_shadow_fwd.xyz);\n    int param = _1428 - 1;\n    if (_1444 > fa_shadow_split_at(param, _651))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1456 = _1428 > 1;\n    bool _1463;\n    if (_1456)\n    {\n        _1463 = _1444 > _651.fa_shadow_split.x;\n    }\n    else\n    {\n        _1463 = _1456;\n    }\n    if (_1463)\n    {\n        ci = 1;\n    }\n    bool _1467 = _1428 > 2;\n    bool _1474;\n    if (_1467)\n    {\n        _1474 = _1444 > _651.fa_shadow_split.y;\n    }\n    else\n    {\n        _1474 = _1467;\n    }\n    if (_1474)\n    {\n        ci = 2;\n    }\n    bool _1478 = _1428 > 3;\n    bool _1485;\n    if (_1478)\n    {\n        _1485 = _1444 > _651.fa_shadow_split.z;\n    }\n    else\n    {\n        _1485 = _1478;\n    }\n    if (_1485)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1428)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1511 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _651, fa_shadow_tex);\n        s = _1511;\n        if (_1511 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_651.fa_shadow_cfg.y > 0.0)\n    {\n        float _1536;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1536 = fa_shadow_split_at(param_5, _651);\n        }\n        else\n        {\n            _1536 = _651.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1555 = _651.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _651) - _1536, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1566 = fast::clamp((_1444 - (fa_shadow_split_at(param_7, _651) - _1555)) / _1555, 0.0, 1.0);\n        if (_1566 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1428)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1587 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _651, fa_shadow_tex);\n                s2 = _1587;\n                if (_1587 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1566);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread float4& gl_FragCoord, constant fa_shadows& _651, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _415, gl_FragCoord, _651, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread float4& gl_FragCoord, constant fa_shadows& _651, texture2d<float> fa_shadow_tex)\n{\n    bool _1059 = _415.fa_pbr.z < 0.5;\n    bool _1067;\n    if (!_1059)\n    {\n        _1067 = _651.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1067 = _1059;\n    }\n    if (_1067)\n    {\n        return 1.0;\n    }\n    int param = (int(_651.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1080 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1081 = _1080.x;\n    if (_1081 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1090 = int(_1081 + 0.5);\n    int param_1 = _1090;\n    float4 _1094 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1090 + 1;\n    float4 _1099 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1102 = _1094.y;\n    if (_1102 > 0.0)\n    {\n        float _1119 = 1.0 - smoothstep(0.75 * _1102, _1102, length(world - _651.fa_shadow_eye.xyz));\n        fade = _1119;\n        if (_1119 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1094.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1138 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1141 = abs(_1138);\n        float _1143 = _1141.x;\n        float _1145 = _1141.y;\n        bool _1146 = _1143 >= _1145;\n        bool _1154;\n        if (_1146)\n        {\n            _1154 = _1143 >= _1141.z;\n        }\n        else\n        {\n            _1154 = _1146;\n        }\n        int _1155;\n        if (_1154)\n        {\n            _1155 = (_1138.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1168;\n            if (_1145 >= _1141.z)\n            {\n                _1168 = (_1138.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1168 = (_1138.z > 0.0) ? 4 : 5;\n            }\n            _1155 = _1168;\n        }\n        face = _1155;\n    }\n    int _1187 = (_1090 + 2) + (face * 6);\n    int param_4 = _1187;\n    int param_5 = _1187 + 1;\n    int param_6 = _1187 + 3;\n    float4 _1201 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1187 + 4;\n    float4 _1206 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1187 + 5;\n    float4 _1211 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1223 = _1211.x * fast::max(dot(_1201, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1228 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1251 = fast::clamp(dot(n, _1201.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1274 = fast::min(sqrt(1.0 - (_1251 * _1251)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1201, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1277 = _1099.y;\n    float _1279;\n    if (_1277 > 0.0)\n    {\n        _1279 = _1277;\n    }\n    else\n    {\n        _1279 = 1.5 * _1223;\n    }\n    float4 _1299 = float4(world + (n * (_1279 * sqrt(1.0 - (_1228 * _1228)))), 1.0);\n    float _1303 = dot(_1201, _1299);\n    float _1306 = _1211.y;\n    if (_1303 < _1306)\n    {\n        return 1.0;\n    }\n    float2 _1321 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1299), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1299)) / float2(_1303);\n    float _1323 = _1321.x;\n    bool _1326 = _1323 < _1206.x;\n    bool _1335;\n    if (!_1326)\n    {\n        _1335 = _1323 > _1206.z;\n    }\n    else\n    {\n        _1335 = _1326;\n    }\n    bool _1344;\n    if (!_1335)\n    {\n        _1344 = _1321.y < _1206.y;\n    }\n    else\n    {\n        _1344 = _1335;\n    }\n    bool _1353;\n    if (!_1344)\n    {\n        _1353 = _1321.y > _1206.w;\n    }\n    else\n    {\n        _1353 = _1344;\n    }\n    if (_1353)\n    {\n        return 1.0;\n    }\n    float _1359 = _1099.x;\n    float _1361;\n    if (_1359 > 0.0)\n    {\n        _1361 = _1359;\n    }\n    else\n    {\n        _1361 = 1.5 * _1223;\n    }\n    float2 param_10 = _1321;\n    float4 param_11 = _1206;\n    float param_12 = _1303 - (_1361 * (1.0 + (0.5 * _1274)));\n    float param_13 = _1223;\n    float param_14 = 1.0;\n    float param_15 = _1211.z * 0.25;\n    float param_16 = (_1223 * fast::min(_1274, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1306, _1211.z);\n    int param_18 = int(_1094.z + 0.5);\n    float param_19 = _1094.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _651, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread float4& gl_FragCoord, constant fa_shadows& _651, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _1756 = fa_lm.z > 0.5;\n    bool _1762;\n    if (_1756)\n    {\n        int param = li;\n        _1762 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _1762 = _1756;\n    }\n    if (_1762)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _1785 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _2815 = _1785.direction;\n    float3 _2810 = _1785.color;\n    float _2817 = _1785.attenuation;\n    float _2812 = _1785.shadow;\n    int _2820 = _1785.type;\n    if ((_2820 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _2815;\n        float _1799 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _415, gl_FragCoord, _651, fa_shadow_tex, fa_world_pos);\n        _2812 = _1799;\n        _2810 *= _1799;\n    }\n    else\n    {\n        bool _1810 = _2820 != 0;\n        bool _1816;\n        if (_1810)\n        {\n            _1816 = _2817 > 0.0;\n        }\n        else\n        {\n            _1816 = _1810;\n        }\n        if (_1816)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _2815;\n            float _1828 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _415, gl_FragCoord, _651, fa_shadow_tex);\n            _2812 = _1828;\n            _2810 *= _1828;\n        }\n    }\n    return LightSample{ _2815, _2810, _2817, _2812, _1785._distance, _2820 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l, constant fa_material& _1854)\n{\n    float _1848;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _1848 = 1.0;\n    }\n    else\n    {\n        _1848 = _1854.dark;\n    }\n    return (s.albedo * l.color) * _1848;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _651)\n{\n    if (_651.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1611 = int(_651.fa_shadow_cfg.x + 0.5);\n    float _1621 = dot(world - _651.fa_shadow_eye.xyz, _651.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1626 = _1611 > 0;\n    bool _1635;\n    if (_1626)\n    {\n        int param = _1611 - 1;\n        _1635 = _1621 <= fa_shadow_split_at(param, _651);\n    }\n    else\n    {\n        _1635 = _1626;\n    }\n    if (_1635)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1642 = _1611 > 1;\n        bool _1649;\n        if (_1642)\n        {\n            _1649 = _1621 > _651.fa_shadow_split.x;\n        }\n        else\n        {\n            _1649 = _1642;\n        }\n        if (_1649)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1655 = _1611 > 2;\n        bool _1662;\n        if (_1655)\n        {\n            _1662 = _1621 > _651.fa_shadow_split.y;\n        }\n        else\n        {\n            _1662 = _1655;\n        }\n        if (_1662)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1668 = _1611 > 3;\n        bool _1675;\n        if (_1668)\n        {\n            _1675 = _1621 > _651.fa_shadow_split.z;\n        }\n        else\n        {\n            _1675 = _1668;\n        }\n        if (_1675)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _415 [[buffer(1)]], constant fa_material& _1854 [[buffer(5)]], constant fa_shadows& _651 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2651 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2651 = -_2651;\n    }\n    float3 _2252 = fast::normalize(_415.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _415, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2651, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2252, short(gl_FrontFacing) };\n    Surface _2260 = fa_standard_surface(param_1, _415, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2682 = _2260.albedo;\n    float _2683 = _2260.alpha;\n    float3 _2684 = _2260.normal;\n    float _2685 = _2260.metallic;\n    float _2686 = _2260.roughness;\n    float _2687 = _2260.occlusion;\n    float3 _2688 = _2260.emission;\n    float _2689 = _2260.clearcoat;\n    float _2690 = _2260.clearcoat_roughness;\n    float3 _2691 = _2260.sheen_color;\n    float _2692 = _2260.sheen_roughness;\n    float _2693 = _2260.anisotropy;\n    float _2694 = _2260.anisotropy_rotation;\n    float _2695 = _2260.specular;\n    float _2696 = _2260.ior;\n    float3 _2697 = _2260.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2651, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2252, short(gl_FrontFacing) };\n    Surface param_3 = _2260;\n    surface(param_2, param_3);\n    _2682 = param_3.albedo;\n    _2683 = param_3.alpha;\n    _2684 = param_3.normal;\n    _2685 = param_3.metallic;\n    _2686 = param_3.roughness;\n    _2687 = param_3.occlusion;\n    _2688 = param_3.emission;\n    _2689 = param_3.clearcoat;\n    _2690 = param_3.clearcoat_roughness;\n    _2691 = param_3.sheen_color;\n    _2692 = param_3.sheen_roughness;\n    _2693 = param_3.anisotropy;\n    _2694 = param_3.anisotropy_rotation;\n    _2695 = param_3.specular;\n    _2696 = param_3.ior;\n    _2697 = param_3.specular_color;\n    float3 result;\n    if (_415.fa_emissive.w > 0.5)\n    {\n        result = _2682;\n    }\n    else\n    {\n        float3 _2281 = _2684;\n        float3 _2282 = fast::normalize(_2281);\n        _2684 = _2282;\n        float3 param_4 = _2282;\n        float3 lit = (fa_indirect_diffuse(param_4, _415, fa_irr_tex, fa_env_smp, in.fa_lm, fa_lightmap) * _2682) * _2687;\n        int _2301 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2301; ln++)\n        {\n            int param_5 = ln;\n            int _2314 = fa_cl_light(param_5, fa_light_tex, fa_shadow_smp, _415, fa_cl_ndir, fa_cl_slot);\n            bool _2317 = in.fa_lm.z > 0.5;\n            bool _2323;\n            if (_2317)\n            {\n                int param_6 = _2314;\n                _2323 = fa_light_baked(param_6, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _2323 = _2317;\n            }\n            if (_2323)\n            {\n                continue;\n            }\n            int param_7 = _2314;\n            float3 param_8 = in.fa_world_pos;\n            float3 param_9 = _2651;\n            SurfaceInput param_10 = SurfaceInput{ in.fa_world_pos, _2651, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2252, short(gl_FrontFacing) };\n            Surface param_11 = Surface{ _2682, _2683, _2684, _2685, _2686, _2687, _2688, _2689, _2690, _2691, _2692, _2693, _2694, _2695, _2696, _2697 };\n            LightSample param_12 = fa_light_shadowed(param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _415, gl_FragCoord, _651, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_10, param_11, param_12, _1854);\n        }\n        result = lit;\n    }\n    float3 _2350 = result;\n    float3 _2351 = _2350 + _2688;\n    result = _2351;\n    float3 param_13 = _2351;\n    float3 param_14 = in.fa_world_pos;\n    result = fa_shadow_debug(param_13, param_14, _651);\n    bool _2360 = _415.fa_fog.w > 0.0;\n    bool _2367;\n    if (!_2360)\n    {\n        _2367 = _415.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2367 = _2360;\n    }\n    if (_2367)\n    {\n        float3 _2376 = in.fa_world_pos - _415.fa_camera_pos.xyz;\n        float _2382 = dot(_2376, _415.fa_fog_c.xyz);\n        bool _2386 = _415.fa_fog_c.w > 0.5;\n        float _2387;\n        if (_2386)\n        {\n            _2387 = _2382;\n        }\n        else\n        {\n            _2387 = length(_2376);\n        }\n        float _2399 = _2387 - _415.fa_fog_b.x;\n        if (_2399 > 0.0)\n        {\n            float _2408 = _415.fa_fog.w * _2399;\n            float tau = _2408 * _2408;\n            if (_415.fa_fog_b.y > 0.0)\n            {\n                float _2424;\n                if (_2386)\n                {\n                    _2424 = in.fa_world_pos.y - (_415.fa_fog_c.y * _2382);\n                }\n                else\n                {\n                    _2424 = _415.fa_camera_pos.y;\n                }\n                float _2445 = mix(_2424, in.fa_world_pos.y, fast::clamp(_415.fa_fog_b.x / _2387, 0.0, 1.0));\n                float _2449 = in.fa_world_pos.y - _2445;\n                float _2454 = _2445 - _415.fa_fog_b.z;\n                float _2459 = in.fa_world_pos.y - _415.fa_fog_b.z;\n                bool _2462 = _2454 <= 0.0;\n                bool _2463 = !_2462;\n                bool _2469;\n                if (_2463)\n                {\n                    _2469 = _415.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2469 = _2462;\n                }\n                float _2470;\n                if (_2469)\n                {\n                    _2470 = _415.fa_fog_b.y;\n                }\n                else\n                {\n                    _2470 = _415.fa_fog_b.y * exp(-fast::min(_415.fa_fog_b.w * _2454, 80.0));\n                }\n                bool _2497;\n                if (_2463)\n                {\n                    _2497 = _415.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2497 = _2462;\n                }\n                float _2498;\n                if (_2497)\n                {\n                    _2498 = _415.fa_fog_b.y * _2454;\n                }\n                else\n                {\n                    _2498 = (_415.fa_fog_b.y * (1.0 - exp(-fast::min(_415.fa_fog_b.w * _2454, 80.0)))) / _415.fa_fog_b.w;\n                }\n                bool _2523 = _2459 <= 0.0;\n                bool _2530;\n                if (!_2523)\n                {\n                    _2530 = _415.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2530 = _2523;\n                }\n                float _2531;\n                if (_2530)\n                {\n                    _2531 = _415.fa_fog_b.y * _2459;\n                }\n                else\n                {\n                    _2531 = (_415.fa_fog_b.y * (1.0 - exp(-fast::min(_415.fa_fog_b.w * _2459, 80.0)))) / _415.fa_fog_b.w;\n                }\n                float _2558;\n                if (abs(_2449) < 0.001000000047497451305389404296875)\n                {\n                    _2558 = _2470;\n                }\n                else\n                {\n                    _2558 = (_2531 - _2498) / _2449;\n                }\n                tau += (_2399 * fast::max(_2558, 0.0));\n            }\n            result = mix(result, _415.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2683);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_415",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_651",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1854",
            "msl_buffer_n": 5
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
              "msl_texture_n": 0
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
              "msl_texture_n": 1
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
              "msl_texture_n": 2
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
              "msl_texture_n": 3
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
              "msl_texture_n": 4
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
              "msl_texture_n": 5
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
              "msl_texture_n": 6
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
              "msl_texture_n": 7
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
              "msl_texture_n": 8
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 10
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_391, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415)\n{\n    bool _420 = _415.fa_cl_info.x < 0.0;\n    bool _427;\n    if (!_420)\n    {\n        _427 = _415.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _427 = _420;\n    }\n    bool _435;\n    if (!_427)\n    {\n        _435 = _415.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _435 = _427;\n    }\n    bool _442;\n    if (!_435)\n    {\n        _442 = _415.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _442 = _435;\n    }\n    bool _449;\n    if (!_442)\n    {\n        _449 = _415.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _449 = _442;\n    }\n    if (_449)\n    {\n        return int2(0);\n    }\n    float4 _459 = float4(world_pos, 1.0);\n    float _466 = dot(_415.fa_cl_vpw, _459);\n    if (!(_466 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _488 = float2(dot(_415.fa_cl_vpx, _459), dot(_415.fa_cl_vpy, _459)) / float2(_466);\n    int _492 = int(_415.fa_cl_grid.x);\n    int _496 = int(_415.fa_cl_grid.y);\n    int param = (int(_415.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_415.fa_cl_fwd.xyz, world_pos) + _415.fa_cl_fwd.w, _415.fa_cl_grid.w) / _415.fa_cl_grid.w) * _415.fa_cl_grid.z)), 0, int(_415.fa_cl_info.y) - 1) * _496) + clamp(int(floor(((_488.y * 0.5) + 0.5) * _415.fa_cl_grid.y)), 0, _496 - 1)) * _492)) + clamp(int(floor(((_488.x * 0.5) + 0.5) * _415.fa_cl_grid.x)), 0, _492 - 1);\n    float4 _567 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_567.x), int(_567.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_415.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1729 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _415);\n    fa_cl_slot = _1729.x;\n    fa_cl_local = _1729.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1914 = fa_linear_to_srgb(param);\n        c = _1914;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1922 = fa_srgb_to_linear(param_1);\n            c = _1922;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _179;\n    if (bool(i.front_facing))\n    {\n        _179 = i.world_normal;\n    }\n    else\n    {\n        _179 = -i.world_normal;\n    }\n    float3 _203 = fast::normalize(i.world_tangent.xyz - (_179 * dot(_179, i.world_tangent.xyz)));\n    float3 _231 = fast::normalize(((_203 * m.x) + ((cross(_179, _203) * i.world_tangent.w) * m.y)) + (_179 * m.z));\n    float3 _234;\n    if (bool(i.front_facing))\n    {\n        _234 = _231;\n    }\n    else\n    {\n        _234 = -_231;\n    }\n    return _234;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _415, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _415.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1953 = fa_tex_fix(param_2, param_3);\n    float4 _2915 = base_t;\n    _2915.x = _1953.x;\n    _2915.y = _1953.y;\n    _2915.z = _1953.z;\n    base_t = _2915;\n    float4 _1967 = (_2915 * _415.fa_base_color) * i.vertex_color;\n    float3 _2830 = i.world_normal;\n    if (_415.fa_maps.z > 0.5)\n    {\n        float param_4 = _415.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1999 = fa_tex_fix(param_6, param_7);\n        float3 _2003 = (_1999 * 2.0) - float3(1.0);\n        float2 _2008 = _2003.xy * _415.fa_maps.x;\n        float3 _2923 = _2003;\n        _2923.x = _2008.x;\n        _2923.y = _2008.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2923;\n        _2830 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _415.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2037 = fa_tex_fix(param_12, param_13);\n    float4 _2926 = mrt;\n    _2926.x = _2037.x;\n    _2926.y = _2037.y;\n    _2926.z = _2037.z;\n    mrt = _2926;\n    float4 _2066 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _415.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2066.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2078 = fa_tex_fix(param_16, param_17);\n    float param_18 = _415.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2108 = fa_tex_fix(param_20, param_21);\n    float _2835 = _415.fa_layers_a.x;\n    float _2836 = _415.fa_layers_a.y;\n    float _2839 = _415.fa_layers_a.z;\n    float _2838 = _415.fa_layers_b.w;\n    float _2841 = _415.fa_layers_c.x;\n    if (_415.fa_layers_c.z > 0.5)\n    {\n        if (mod(_415.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2835 *= _2078.y;\n            _2836 *= _2078.z;\n            _2838 *= _2066.w;\n        }\n        if (_415.fa_layers_c.z > 1.5)\n        {\n            _2839 *= mrt.x;\n            _2841 *= mrt.w;\n        }\n    }\n    return Surface{ _1967.xyz, _1967.w, _2830, fast::clamp(_415.fa_pbr.x * _2037.z, 0.0, 1.0), fast::clamp(_415.fa_pbr.y * _2037.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_415.fa_maps.y * (_2078.x - 1.0)), _415.fa_emissive.xyz + (_415.fa_model_emissive.xyz * _2108), _2835, _2836, _415.fa_layers_b.xyz, _2838, _2839, _415.fa_layers_a.w, _2841, _415.fa_layers_c.y, _415.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _415, texturecube<float> fa_irr_tex, sampler fa_env_smp)\n{\n    if (_415.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _415.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _415, texturecube<float> fa_irr_tex, sampler fa_env_smp, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _415, fa_irr_tex, fa_env_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415)\n{\n    int param = (int(_415.fa_cl_info.x) + int(_415.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _415);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _290 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _296 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _299 = _296.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _305 = _299 < 0.5;\n    float3 l;\n    if (_305)\n    {\n        l = fast::normalize(_290.xyz);\n    }\n    else\n    {\n        float3 _317 = _290.xyz - world_pos;\n        float _319 = length(_317);\n        dist = _319;\n        l = _317 / float3(fast::max(_319, 9.9999997473787516355514526367188e-05));\n        float _334 = _319 / fast::max(_290.w, 0.001000000047497451305389404296875);\n        float _340 = fast::clamp(1.0 - (_334 * _334), 0.0, 1.0);\n        atten = _340 * _340;\n        if (_299 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _354 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _364 = _354.w;\n            int param_3 = (li * 4) + 3;\n            float4 _370 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _371 = _370.x;\n            float cos_inner = _371;\n            if (_371 > 1.5)\n            {\n                cos_inner = mix(_364, 1.0, 0.25);\n            }\n            atten *= smoothstep(_364, cos_inner, dot(-l, fast::normalize(_354.xyz)));\n        }\n    }\n    int _401;\n    if (_305)\n    {\n        _401 = 0;\n    }\n    else\n    {\n        _401 = (_299 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _296.xyz * atten, atten, 1.0, dist, _401 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _651)\n{\n    float _641;\n    if (i == 0)\n    {\n        _641 = _651.fa_shadow_split.x;\n    }\n    else\n    {\n        float _657;\n        if (i == 1)\n        {\n            _657 = _651.fa_shadow_split.y;\n        }\n        else\n        {\n            float _665;\n            if (i == 2)\n            {\n                _665 = _651.fa_shadow_split.z;\n            }\n            else\n            {\n                _665 = _651.fa_shadow_split.w;\n            }\n            _657 = _665;\n        }\n        _641 = _657;\n    }\n    return _641;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _698 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _702;\n    if (conv.x < 0.5)\n    {\n        _702 = _698;\n    }\n    else\n    {\n        _702 = (conv.y * conv.z) / (conv.z - (_698 * (conv.z - conv.y)));\n    }\n    return _702;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _629 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_629), sin(_629)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _651, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _748 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _762 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _748;\n            float2 _781 = fa_shadow_vogel(param_3, param_4, param_5) * _762;\n            float2 param_6 = uv + (_781 * _651.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _793 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_793 < (zr - (length(_781) * plane)))\n            {\n                sum += _793;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _837 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _837; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _837;\n        float param_11 = _748;\n        float2 _856 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_856 * _651.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_856) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_837);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _651, texture2d<float> fa_shadow_tex)\n{\n    float _898 = fast::max(_651.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _903 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _909 = sqrt(1.0 - (_903 * _903));\n    float _917 = fast::min(_909 / fast::max(_903, 0.20000000298023223876953125), 4.0);\n    float _922;\n    if (_651.fa_shadow_bias.y > 0.0)\n    {\n        _922 = _651.fa_shadow_bias.y;\n    }\n    else\n    {\n        _922 = 1.5 * _651.fa_shadow_info[ci].x;\n    }\n    float4 _947 = _651.fa_shadow_mat[ci] * float4(world + (n * (_922 * _909)), 1.0);\n    float _954 = _947.x;\n    bool _957 = _954 < _651.fa_shadow_rect[ci].x;\n    bool _966;\n    if (!_957)\n    {\n        _966 = _954 > _651.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _966 = _957;\n    }\n    bool _975;\n    if (!_966)\n    {\n        _975 = _947.y < _651.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _975 = _966;\n    }\n    bool _984;\n    if (!_975)\n    {\n        _984 = _947.y > _651.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _984 = _975;\n    }\n    bool _991;\n    if (!_984)\n    {\n        _991 = _947.z > 1.0;\n    }\n    else\n    {\n        _991 = _984;\n    }\n    if (_991)\n    {\n        return -1.0;\n    }\n    float _1000;\n    if (_651.fa_shadow_bias.x > 0.0)\n    {\n        _1000 = _651.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1000 = 1.5 * _651.fa_shadow_info[ci].x;\n    }\n    float2 param = _947.xy;\n    float4 param_1 = _651.fa_shadow_rect[ci];\n    float param_2 = _947.z - ((_1000 * (1.0 + (0.5 * _917))) / _898);\n    float param_3 = _651.fa_shadow_info[ci].x;\n    float param_4 = _898;\n    float param_5 = _898 * 0.25;\n    float param_6 = ((_651.fa_shadow_info[ci].x * fast::min(_917, 3.0)) * 0.5) / _898;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_651.fa_shadow_cfg.z + 0.5);\n    float param_9 = _651.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _651, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread float4& gl_FragCoord, constant fa_shadows& _651, texture2d<float> fa_shadow_tex)\n{\n    if (_415.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1428 = int(_651.fa_shadow_cfg.x + 0.5);\n    if (_1428 < 1)\n    {\n        return 1.0;\n    }\n    float _1444 = dot(world - _651.fa_shadow_eye.xyz, _651.fa_shadow_fwd.xyz);\n    int param = _1428 - 1;\n    if (_1444 > fa_shadow_split_at(param, _651))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1456 = _1428 > 1;\n    bool _1463;\n    if (_1456)\n    {\n        _1463 = _1444 > _651.fa_shadow_split.x;\n    }\n    else\n    {\n        _1463 = _1456;\n    }\n    if (_1463)\n    {\n        ci = 1;\n    }\n    bool _1467 = _1428 > 2;\n    bool _1474;\n    if (_1467)\n    {\n        _1474 = _1444 > _651.fa_shadow_split.y;\n    }\n    else\n    {\n        _1474 = _1467;\n    }\n    if (_1474)\n    {\n        ci = 2;\n    }\n    bool _1478 = _1428 > 3;\n    bool _1485;\n    if (_1478)\n    {\n        _1485 = _1444 > _651.fa_shadow_split.z;\n    }\n    else\n    {\n        _1485 = _1478;\n    }\n    if (_1485)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1428)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1511 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _651, fa_shadow_tex);\n        s = _1511;\n        if (_1511 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_651.fa_shadow_cfg.y > 0.0)\n    {\n        float _1536;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1536 = fa_shadow_split_at(param_5, _651);\n        }\n        else\n        {\n            _1536 = _651.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1555 = _651.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _651) - _1536, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1566 = fast::clamp((_1444 - (fa_shadow_split_at(param_7, _651) - _1555)) / _1555, 0.0, 1.0);\n        if (_1566 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1428)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1587 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _651, fa_shadow_tex);\n                s2 = _1587;\n                if (_1587 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1566);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread float4& gl_FragCoord, constant fa_shadows& _651, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _415, gl_FragCoord, _651, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread float4& gl_FragCoord, constant fa_shadows& _651, texture2d<float> fa_shadow_tex)\n{\n    bool _1059 = _415.fa_pbr.z < 0.5;\n    bool _1067;\n    if (!_1059)\n    {\n        _1067 = _651.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1067 = _1059;\n    }\n    if (_1067)\n    {\n        return 1.0;\n    }\n    int param = (int(_651.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1080 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1081 = _1080.x;\n    if (_1081 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1090 = int(_1081 + 0.5);\n    int param_1 = _1090;\n    float4 _1094 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1090 + 1;\n    float4 _1099 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1102 = _1094.y;\n    if (_1102 > 0.0)\n    {\n        float _1119 = 1.0 - smoothstep(0.75 * _1102, _1102, length(world - _651.fa_shadow_eye.xyz));\n        fade = _1119;\n        if (_1119 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1094.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1138 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1141 = abs(_1138);\n        float _1143 = _1141.x;\n        float _1145 = _1141.y;\n        bool _1146 = _1143 >= _1145;\n        bool _1154;\n        if (_1146)\n        {\n            _1154 = _1143 >= _1141.z;\n        }\n        else\n        {\n            _1154 = _1146;\n        }\n        int _1155;\n        if (_1154)\n        {\n            _1155 = (_1138.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1168;\n            if (_1145 >= _1141.z)\n            {\n                _1168 = (_1138.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1168 = (_1138.z > 0.0) ? 4 : 5;\n            }\n            _1155 = _1168;\n        }\n        face = _1155;\n    }\n    int _1187 = (_1090 + 2) + (face * 6);\n    int param_4 = _1187;\n    int param_5 = _1187 + 1;\n    int param_6 = _1187 + 3;\n    float4 _1201 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1187 + 4;\n    float4 _1206 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1187 + 5;\n    float4 _1211 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1223 = _1211.x * fast::max(dot(_1201, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1228 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1251 = fast::clamp(dot(n, _1201.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1274 = fast::min(sqrt(1.0 - (_1251 * _1251)) / fast::max(abs(dot(n, world - fa_light_texel(param_9, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_1201, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1277 = _1099.y;\n    float _1279;\n    if (_1277 > 0.0)\n    {\n        _1279 = _1277;\n    }\n    else\n    {\n        _1279 = 1.5 * _1223;\n    }\n    float4 _1299 = float4(world + (n * (_1279 * sqrt(1.0 - (_1228 * _1228)))), 1.0);\n    float _1303 = dot(_1201, _1299);\n    float _1306 = _1211.y;\n    if (_1303 < _1306)\n    {\n        return 1.0;\n    }\n    float2 _1321 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1299), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1299)) / float2(_1303);\n    float _1323 = _1321.x;\n    bool _1326 = _1323 < _1206.x;\n    bool _1335;\n    if (!_1326)\n    {\n        _1335 = _1323 > _1206.z;\n    }\n    else\n    {\n        _1335 = _1326;\n    }\n    bool _1344;\n    if (!_1335)\n    {\n        _1344 = _1321.y < _1206.y;\n    }\n    else\n    {\n        _1344 = _1335;\n    }\n    bool _1353;\n    if (!_1344)\n    {\n        _1353 = _1321.y > _1206.w;\n    }\n    else\n    {\n        _1353 = _1344;\n    }\n    if (_1353)\n    {\n        return 1.0;\n    }\n    float _1359 = _1099.x;\n    float _1361;\n    if (_1359 > 0.0)\n    {\n        _1361 = _1359;\n    }\n    else\n    {\n        _1361 = 1.5 * _1223;\n    }\n    float2 param_10 = _1321;\n    float4 param_11 = _1206;\n    float param_12 = _1303 - (_1361 * (1.0 + (0.5 * _1274)));\n    float param_13 = _1223;\n    float param_14 = 1.0;\n    float param_15 = _1211.z * 0.25;\n    float param_16 = (_1223 * fast::min(_1274, 3.0)) * 0.5;\n    float3 param_17 = float3(1.0, _1306, _1211.z);\n    int param_18 = int(_1094.z + 0.5);\n    float param_19 = _1094.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, fa_shadow_smp, gl_FragCoord, _651, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _415, thread float4& gl_FragCoord, constant fa_shadows& _651, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _1756 = fa_lm.z > 0.5;\n    bool _1762;\n    if (_1756)\n    {\n        int param = li;\n        _1762 = fa_light_baked(param, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _1762 = _1756;\n    }\n    if (_1762)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    LightSample _1785 = fa_light_sample(param_2, param_3, fa_light_tex, fa_shadow_smp);\n    float3 _2815 = _1785.direction;\n    float3 _2810 = _1785.color;\n    float _2817 = _1785.attenuation;\n    float _2812 = _1785.shadow;\n    int _2820 = _1785.type;\n    if ((_2820 == 0) && (li == 0))\n    {\n        float3 param_4 = gn;\n        float3 param_5 = _2815;\n        float _1799 = fa_shadow_factor(param_4, param_5, fa_shadow_smp, _415, gl_FragCoord, _651, fa_shadow_tex, fa_world_pos);\n        _2812 = _1799;\n        _2810 *= _1799;\n    }\n    else\n    {\n        bool _1810 = _2820 != 0;\n        bool _1816;\n        if (_1810)\n        {\n            _1816 = _2817 > 0.0;\n        }\n        else\n        {\n            _1816 = _1810;\n        }\n        if (_1816)\n        {\n            int param_6 = li;\n            float3 param_7 = world_pos;\n            float3 param_8 = gn;\n            float3 param_9 = _2815;\n            float _1828 = fa_shadow_local(param_6, param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _415, gl_FragCoord, _651, fa_shadow_tex);\n            _2812 = _1828;\n            _2810 *= _1828;\n        }\n    }\n    return LightSample{ _2815, _2810, _2817, _2812, _1785._distance, _2820 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l, constant fa_material& _1854)\n{\n    float _1848;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _1848 = 1.0;\n    }\n    else\n    {\n        _1848 = _1854.dark;\n    }\n    return (s.albedo * l.color) * _1848;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _651)\n{\n    if (_651.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1611 = int(_651.fa_shadow_cfg.x + 0.5);\n    float _1621 = dot(world - _651.fa_shadow_eye.xyz, _651.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1626 = _1611 > 0;\n    bool _1635;\n    if (_1626)\n    {\n        int param = _1611 - 1;\n        _1635 = _1621 <= fa_shadow_split_at(param, _651);\n    }\n    else\n    {\n        _1635 = _1626;\n    }\n    if (_1635)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1642 = _1611 > 1;\n        bool _1649;\n        if (_1642)\n        {\n            _1649 = _1621 > _651.fa_shadow_split.x;\n        }\n        else\n        {\n            _1649 = _1642;\n        }\n        if (_1649)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1655 = _1611 > 2;\n        bool _1662;\n        if (_1655)\n        {\n            _1662 = _1621 > _651.fa_shadow_split.y;\n        }\n        else\n        {\n            _1662 = _1655;\n        }\n        if (_1662)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1668 = _1611 > 3;\n        bool _1675;\n        if (_1668)\n        {\n            _1675 = _1621 > _651.fa_shadow_split.z;\n        }\n        else\n        {\n            _1675 = _1668;\n        }\n        if (_1675)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _415 [[buffer(1)]], constant fa_material& _1854 [[buffer(5)]], constant fa_shadows& _651 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2651 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2651 = -_2651;\n    }\n    float3 _2252 = fast::normalize(_415.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _415, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2651, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2252, short(gl_FrontFacing) };\n    Surface _2260 = fa_standard_surface(param_1, _415, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2682 = _2260.albedo;\n    float _2683 = _2260.alpha;\n    float3 _2684 = _2260.normal;\n    float _2685 = _2260.metallic;\n    float _2686 = _2260.roughness;\n    float _2687 = _2260.occlusion;\n    float3 _2688 = _2260.emission;\n    float _2689 = _2260.clearcoat;\n    float _2690 = _2260.clearcoat_roughness;\n    float3 _2691 = _2260.sheen_color;\n    float _2692 = _2260.sheen_roughness;\n    float _2693 = _2260.anisotropy;\n    float _2694 = _2260.anisotropy_rotation;\n    float _2695 = _2260.specular;\n    float _2696 = _2260.ior;\n    float3 _2697 = _2260.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2651, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2252, short(gl_FrontFacing) };\n    Surface param_3 = _2260;\n    surface(param_2, param_3);\n    _2682 = param_3.albedo;\n    _2683 = param_3.alpha;\n    _2684 = param_3.normal;\n    _2685 = param_3.metallic;\n    _2686 = param_3.roughness;\n    _2687 = param_3.occlusion;\n    _2688 = param_3.emission;\n    _2689 = param_3.clearcoat;\n    _2690 = param_3.clearcoat_roughness;\n    _2691 = param_3.sheen_color;\n    _2692 = param_3.sheen_roughness;\n    _2693 = param_3.anisotropy;\n    _2694 = param_3.anisotropy_rotation;\n    _2695 = param_3.specular;\n    _2696 = param_3.ior;\n    _2697 = param_3.specular_color;\n    float3 result;\n    if (_415.fa_emissive.w > 0.5)\n    {\n        result = _2682;\n    }\n    else\n    {\n        float3 _2281 = _2684;\n        float3 _2282 = fast::normalize(_2281);\n        _2684 = _2282;\n        float3 param_4 = _2282;\n        float3 lit = (fa_indirect_diffuse(param_4, _415, fa_irr_tex, fa_env_smp, in.fa_lm, fa_lightmap) * _2682) * _2687;\n        int _2301 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2301; ln++)\n        {\n            int param_5 = ln;\n            int _2314 = fa_cl_light(param_5, fa_light_tex, fa_shadow_smp, _415, fa_cl_ndir, fa_cl_slot);\n            bool _2317 = in.fa_lm.z > 0.5;\n            bool _2323;\n            if (_2317)\n            {\n                int param_6 = _2314;\n                _2323 = fa_light_baked(param_6, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _2323 = _2317;\n            }\n            if (_2323)\n            {\n                continue;\n            }\n            int param_7 = _2314;\n            float3 param_8 = in.fa_world_pos;\n            float3 param_9 = _2651;\n            SurfaceInput param_10 = SurfaceInput{ in.fa_world_pos, _2651, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2252, short(gl_FrontFacing) };\n            Surface param_11 = Surface{ _2682, _2683, _2684, _2685, _2686, _2687, _2688, _2689, _2690, _2691, _2692, _2693, _2694, _2695, _2696, _2697 };\n            LightSample param_12 = fa_light_shadowed(param_7, param_8, param_9, fa_light_tex, fa_shadow_smp, _415, gl_FragCoord, _651, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            lit += light(param_10, param_11, param_12, _1854);\n        }\n        result = lit;\n    }\n    float3 _2350 = result;\n    float3 _2351 = _2350 + _2688;\n    result = _2351;\n    float3 param_13 = _2351;\n    float3 param_14 = in.fa_world_pos;\n    result = fa_shadow_debug(param_13, param_14, _651);\n    bool _2360 = _415.fa_fog.w > 0.0;\n    bool _2367;\n    if (!_2360)\n    {\n        _2367 = _415.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2367 = _2360;\n    }\n    if (_2367)\n    {\n        float3 _2376 = in.fa_world_pos - _415.fa_camera_pos.xyz;\n        float _2382 = dot(_2376, _415.fa_fog_c.xyz);\n        bool _2386 = _415.fa_fog_c.w > 0.5;\n        float _2387;\n        if (_2386)\n        {\n            _2387 = _2382;\n        }\n        else\n        {\n            _2387 = length(_2376);\n        }\n        float _2399 = _2387 - _415.fa_fog_b.x;\n        if (_2399 > 0.0)\n        {\n            float _2408 = _415.fa_fog.w * _2399;\n            float tau = _2408 * _2408;\n            if (_415.fa_fog_b.y > 0.0)\n            {\n                float _2424;\n                if (_2386)\n                {\n                    _2424 = in.fa_world_pos.y - (_415.fa_fog_c.y * _2382);\n                }\n                else\n                {\n                    _2424 = _415.fa_camera_pos.y;\n                }\n                float _2445 = mix(_2424, in.fa_world_pos.y, fast::clamp(_415.fa_fog_b.x / _2387, 0.0, 1.0));\n                float _2449 = in.fa_world_pos.y - _2445;\n                float _2454 = _2445 - _415.fa_fog_b.z;\n                float _2459 = in.fa_world_pos.y - _415.fa_fog_b.z;\n                bool _2462 = _2454 <= 0.0;\n                bool _2463 = !_2462;\n                bool _2469;\n                if (_2463)\n                {\n                    _2469 = _415.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2469 = _2462;\n                }\n                float _2470;\n                if (_2469)\n                {\n                    _2470 = _415.fa_fog_b.y;\n                }\n                else\n                {\n                    _2470 = _415.fa_fog_b.y * exp(-fast::min(_415.fa_fog_b.w * _2454, 80.0));\n                }\n                bool _2497;\n                if (_2463)\n                {\n                    _2497 = _415.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2497 = _2462;\n                }\n                float _2498;\n                if (_2497)\n                {\n                    _2498 = _415.fa_fog_b.y * _2454;\n                }\n                else\n                {\n                    _2498 = (_415.fa_fog_b.y * (1.0 - exp(-fast::min(_415.fa_fog_b.w * _2454, 80.0)))) / _415.fa_fog_b.w;\n                }\n                bool _2523 = _2459 <= 0.0;\n                bool _2530;\n                if (!_2523)\n                {\n                    _2530 = _415.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2530 = _2523;\n                }\n                float _2531;\n                if (_2530)\n                {\n                    _2531 = _415.fa_fog_b.y * _2459;\n                }\n                else\n                {\n                    _2531 = (_415.fa_fog_b.y * (1.0 - exp(-fast::min(_415.fa_fog_b.w * _2459, 80.0)))) / _415.fa_fog_b.w;\n                }\n                float _2558;\n                if (abs(_2449) < 0.001000000047497451305389404296875)\n                {\n                    _2558 = _2470;\n                }\n                else\n                {\n                    _2558 = (_2531 - _2498) / _2449;\n                }\n                tau += (_2399 * fast::max(_2558, 0.0));\n            }\n            result = mix(result, _415.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2683);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_415",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_651",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1854",
            "msl_buffer_n": 5
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
              "msl_texture_n": 0
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
              "msl_texture_n": 1
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
              "msl_texture_n": 2
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
              "msl_texture_n": 3
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
              "msl_texture_n": 4
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
              "msl_texture_n": 5
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
              "msl_texture_n": 6
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
              "msl_texture_n": 7
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
              "msl_texture_n": 8
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 10
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _786 = base_t;\n    _786.x = _225.x;\n    _786.y = _225.y;\n    _786.z = _225.z;\n    base_t = _786;\n    float4 _241 = (_786 * _213.fa_base_color) * i.vertex_color;\n    float3 _749 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _794 = _279;\n        _794.x = _284.x;\n        _794.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _794;\n        _749 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _797 = mrt;\n    _797.x = _313.x;\n    _797.y = _313.y;\n    _797.z = _313.z;\n    mrt = _797;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _754 = _213.fa_layers_a.x;\n    float _755 = _213.fa_layers_a.y;\n    float _758 = _213.fa_layers_a.z;\n    float _757 = _213.fa_layers_b.w;\n    float _760 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _754 *= _355.y;\n            _755 *= _355.z;\n            _757 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _758 *= mrt.x;\n            _760 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _749, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _754, _755, _213.fa_layers_b.xyz, _757, _758, _213.fa_layers_a.w, _760, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _660 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _660 = -_660;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _660, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _660, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "msl_buffer_n": 1
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
              "msl_texture_n": 0
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
              "msl_texture_n": 1
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
              "msl_texture_n": 2
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
              "msl_texture_n": 3
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
              "msl_texture_n": 4
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _786 = base_t;\n    _786.x = _225.x;\n    _786.y = _225.y;\n    _786.z = _225.z;\n    base_t = _786;\n    float4 _241 = (_786 * _213.fa_base_color) * i.vertex_color;\n    float3 _749 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _794 = _279;\n        _794.x = _284.x;\n        _794.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _794;\n        _749 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _797 = mrt;\n    _797.x = _313.x;\n    _797.y = _313.y;\n    _797.z = _313.z;\n    mrt = _797;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _754 = _213.fa_layers_a.x;\n    float _755 = _213.fa_layers_a.y;\n    float _758 = _213.fa_layers_a.z;\n    float _757 = _213.fa_layers_b.w;\n    float _760 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _754 *= _355.y;\n            _755 *= _355.z;\n            _757 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _758 *= mrt.x;\n            _760 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _749, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _754, _755, _213.fa_layers_b.xyz, _757, _758, _213.fa_layers_a.w, _760, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _660 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _660 = -_660;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _660, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _660, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "msl_buffer_n": 1
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
              "msl_texture_n": 0
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
              "msl_texture_n": 1
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
              "msl_texture_n": 2
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
              "msl_texture_n": 3
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
              "msl_texture_n": 4
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
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
