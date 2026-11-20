{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b9137a7fd5249b4222bedebb6ca5e740fb7c4a348474dd42da5706fae9a2d4c0",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_265, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _369)\n{\n    bool _374 = _369.fa_cl_info.x < 0.0;\n    bool _381;\n    if (!_374)\n    {\n        _381 = _369.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _381 = _374;\n    }\n    bool _389;\n    if (!_381)\n    {\n        _389 = _369.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _389 = _381;\n    }\n    bool _396;\n    if (!_389)\n    {\n        _396 = _369.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _396 = _389;\n    }\n    bool _403;\n    if (!_396)\n    {\n        _403 = _369.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _403 = _396;\n    }\n    if (_403)\n    {\n        return int2(0);\n    }\n    float4 _413 = float4(world_pos, 1.0);\n    float _420 = dot(_369.fa_cl_vpw, _413);\n    if (!(_420 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _442 = float2(dot(_369.fa_cl_vpx, _413), dot(_369.fa_cl_vpy, _413)) / float2(_420);\n    int _446 = int(_369.fa_cl_grid.x);\n    int _450 = int(_369.fa_cl_grid.y);\n    int param = (int(_369.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_369.fa_cl_fwd.xyz, world_pos) + _369.fa_cl_fwd.w, _369.fa_cl_grid.w) / _369.fa_cl_grid.w) * _369.fa_cl_grid.z)), 0, int(_369.fa_cl_info.y) - 1) * _450) + clamp(int(floor(((_442.y * 0.5) + 0.5) * _369.fa_cl_grid.y)), 0, _450 - 1)) * _446)) + clamp(int(floor(((_442.x * 0.5) + 0.5) * _369.fa_cl_grid.x)), 0, _446 - 1);\n    float4 _521 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_521.x), int(_521.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _369, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_369.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1266 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _369);\n    fa_cl_slot = _1266.x;\n    fa_cl_local = _1266.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1374 = fa_linear_to_srgb(param);\n        c = _1374;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1382 = fa_srgb_to_linear(param_1);\n            c = _1382;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _150;\n    if (bool(i.front_facing))\n    {\n        _150 = i.world_normal;\n    }\n    else\n    {\n        _150 = -i.world_normal;\n    }\n    float3 _174 = fast::normalize(i.world_tangent.xyz - (_150 * dot(_150, i.world_tangent.xyz)));\n    float3 _202 = fast::normalize(((_174 * m.x) + ((cross(_150, _174) * i.world_tangent.w) * m.y)) + (_150 * m.z));\n    float3 _205;\n    if (bool(i.front_facing))\n    {\n        _205 = _202;\n    }\n    else\n    {\n        _205 = -_202;\n    }\n    return _205;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _369, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _369.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1413 = fa_tex_fix(param_2, param_3);\n    float4 _2325 = base_t;\n    _2325.x = _1413.x;\n    _2325.y = _1413.y;\n    _2325.z = _1413.z;\n    base_t = _2325;\n    float4 _1427 = (_2325 * _369.fa_base_color) * i.vertex_color;\n    float3 _2272 = i.world_normal;\n    if (_369.fa_maps.z > 0.5)\n    {\n        float param_4 = _369.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1459 = fa_tex_fix(param_6, param_7);\n        float3 _1463 = (_1459 * 2.0) - float3(1.0);\n        float2 _1468 = _1463.xy * _369.fa_maps.x;\n        float3 _2333 = _1463;\n        _2333.x = _1468.x;\n        _2333.y = _1468.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2333;\n        _2272 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _369.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1497 = fa_tex_fix(param_12, param_13);\n    float4 _2336 = mrt;\n    _2336.x = _1497.x;\n    _2336.y = _1497.y;\n    _2336.z = _1497.z;\n    mrt = _2336;\n    float4 _1526 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _369.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1526.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1538 = fa_tex_fix(param_16, param_17);\n    float param_18 = _369.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1568 = fa_tex_fix(param_20, param_21);\n    float _2277 = _369.fa_layers_a.x;\n    float _2278 = _369.fa_layers_a.y;\n    float _2281 = _369.fa_layers_a.z;\n    float _2280 = _369.fa_layers_b.w;\n    float _2283 = _369.fa_layers_c.x;\n    if (_369.fa_layers_c.z > 0.5)\n    {\n        if (mod(_369.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2277 *= _1538.y;\n            _2278 *= _1538.z;\n            _2280 *= _1526.w;\n        }\n        if (_369.fa_layers_c.z > 1.5)\n        {\n            _2281 *= mrt.x;\n            _2283 *= mrt.w;\n        }\n    }\n    return Surface{ _1427.xyz, _1427.w, _2272, fast::clamp(_369.fa_pbr.x * _1497.z, 0.0, 1.0), fast::clamp(_369.fa_pbr.y * _1497.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_369.fa_maps.y * (_1538.x - 1.0)), _369.fa_emissive.xyz + (_369.fa_model_emissive.xyz * _1568), _2277, _2278, _369.fa_layers_b.xyz, _2280, _2281, _369.fa_layers_a.w, _2283, _369.fa_layers_c.y, _369.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _369, texturecube<float> fa_irr_tex, sampler fa_env_smp)\n{\n    if (_369.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _369.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _369)\n{\n    int param = (int(_369.fa_cl_info.x) + int(_369.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _369, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _369);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _242 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _248 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _251 = _248.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _258 = _251 < 0.5;\n    float3 l;\n    if (_258)\n    {\n        l = fast::normalize(_242.xyz);\n    }\n    else\n    {\n        float3 _270 = _242.xyz - world_pos;\n        float _272 = length(_270);\n        dist = _272;\n        l = _270 / float3(fast::max(_272, 9.9999997473787516355514526367188e-05));\n        float _287 = _272 / fast::max(_242.w, 0.001000000047497451305389404296875);\n        float _293 = fast::clamp(1.0 - (_287 * _287), 0.0, 1.0);\n        atten = _293 * _293;\n        if (_251 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _307 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _317 = _307.w;\n            int param_3 = (li * 4) + 3;\n            float4 _324 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _325 = _324.x;\n            float cos_inner = _325;\n            if (_325 > 1.5)\n            {\n                cos_inner = mix(_317, 1.0, 0.25);\n            }\n            atten *= smoothstep(_317, cos_inner, dot(-l, fast::normalize(_307.xyz)));\n        }\n    }\n    int _355;\n    if (_258)\n    {\n        _355 = 0;\n    }\n    else\n    {\n        _355 = (_251 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _248.xyz * atten, atten, 1.0, dist, _355 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _605)\n{\n    float _595;\n    if (i == 0)\n    {\n        _595 = _605.fa_shadow_split.x;\n    }\n    else\n    {\n        float _611;\n        if (i == 1)\n        {\n            _611 = _605.fa_shadow_split.y;\n        }\n        else\n        {\n            float _619;\n            if (i == 2)\n            {\n                _619 = _605.fa_shadow_split.z;\n            }\n            else\n            {\n                _619 = _605.fa_shadow_split.w;\n            }\n            _611 = _619;\n        }\n        _595 = _611;\n    }\n    return _595;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _583 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_583), sin(_583)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _605, texture2d<float> fa_shadow_tex)\n{\n    float _657 = fast::max(_605.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _662 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _668 = sqrt(1.0 - (_662 * _662));\n    float _676 = fast::min(_668 / fast::max(_662, 0.20000000298023223876953125), 4.0);\n    float _681;\n    if (_605.fa_shadow_bias.y > 0.0)\n    {\n        _681 = _605.fa_shadow_bias.y;\n    }\n    else\n    {\n        _681 = 1.5 * _605.fa_shadow_info[ci].x;\n    }\n    float4 _706 = _605.fa_shadow_mat[ci] * float4(world + (n * (_681 * _668)), 1.0);\n    float _713 = _706.x;\n    bool _716 = _713 < _605.fa_shadow_rect[ci].x;\n    bool _725;\n    if (!_716)\n    {\n        _725 = _713 > _605.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _725 = _716;\n    }\n    bool _734;\n    if (!_725)\n    {\n        _734 = _706.y < _605.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _734 = _725;\n    }\n    bool _743;\n    if (!_734)\n    {\n        _743 = _706.y > _605.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _743 = _734;\n    }\n    bool _750;\n    if (!_743)\n    {\n        _750 = _706.z > 1.0;\n    }\n    else\n    {\n        _750 = _743;\n    }\n    if (_750)\n    {\n        return -1.0;\n    }\n    float _759;\n    if (_605.fa_shadow_bias.x > 0.0)\n    {\n        _759 = _605.fa_shadow_bias.x;\n    }\n    else\n    {\n        _759 = 1.5 * _605.fa_shadow_info[ci].x;\n    }\n    float _778 = _706.z - ((_759 * (1.0 + (0.5 * _676))) / _657);\n    float _787 = ((_605.fa_shadow_info[ci].x * fast::min(_676, 3.0)) * 0.5) / _657;\n    int _796 = int(_605.fa_shadow_cfg.z + 0.5);\n    if (_796 == 1)\n    {\n        float2 param = _706.xy;\n        float4 param_1 = _605.fa_shadow_rect[ci];\n        float _807 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_778 <= _807);\n    }\n    float _814 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _817 = _796 == 2;\n    if (_817)\n    {\n        float _831 = fast::clamp(((_605.fa_shadow_cfg.w * _657) * 0.25) / _605.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _814;\n            float2 _850 = fa_shadow_vogel(param_2, param_3, param_4) * _831;\n            float2 param_5 = _706.xy + (_850 * _605.fa_shadow_bias.zw);\n            float4 param_6 = _605.fa_shadow_rect[ci];\n            float _861 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_861 < (_778 - (length(_850) * _787)))\n            {\n                sum += _861;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_778 - (sum / cnt), 0.0) * _657) * _605.fa_shadow_cfg.w) / _605.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _905 = _817 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _905; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _905;\n        float param_9 = _814;\n        float2 _924 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _706.xy + (_924 * _605.fa_shadow_bias.zw);\n        float4 param_11 = _605.fa_shadow_rect[ci];\n        float _935 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_778 - (length(_924) * _787)) <= _935);\n    }\n    return lit / float(_905);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _369, thread float4& gl_FragCoord, constant fa_shadows& _605, texture2d<float> fa_shadow_tex)\n{\n    if (_369.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _965 = int(_605.fa_shadow_cfg.x + 0.5);\n    if (_965 < 1)\n    {\n        return 1.0;\n    }\n    float _981 = dot(world - _605.fa_shadow_eye.xyz, _605.fa_shadow_fwd.xyz);\n    int param = _965 - 1;\n    if (_981 > fa_shadow_split_at(param, _605))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _993 = _965 > 1;\n    bool _1000;\n    if (_993)\n    {\n        _1000 = _981 > _605.fa_shadow_split.x;\n    }\n    else\n    {\n        _1000 = _993;\n    }\n    if (_1000)\n    {\n        ci = 1;\n    }\n    bool _1004 = _965 > 2;\n    bool _1011;\n    if (_1004)\n    {\n        _1011 = _981 > _605.fa_shadow_split.y;\n    }\n    else\n    {\n        _1011 = _1004;\n    }\n    if (_1011)\n    {\n        ci = 2;\n    }\n    bool _1015 = _965 > 3;\n    bool _1022;\n    if (_1015)\n    {\n        _1022 = _981 > _605.fa_shadow_split.z;\n    }\n    else\n    {\n        _1022 = _1015;\n    }\n    if (_1022)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _965)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1048 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _605, fa_shadow_tex);\n        s = _1048;\n        if (_1048 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_605.fa_shadow_cfg.y > 0.0)\n    {\n        float _1073;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1073 = fa_shadow_split_at(param_5, _605);\n        }\n        else\n        {\n            _1073 = _605.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1092 = _605.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _605) - _1073, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1103 = fast::clamp((_981 - (fa_shadow_split_at(param_7, _605) - _1092)) / _1092, 0.0, 1.0);\n        if (_1103 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _965)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1124 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _605, fa_shadow_tex);\n                s2 = _1124;\n                if (_1124 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1103);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _369, thread float4& gl_FragCoord, constant fa_shadows& _605, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _369, gl_FragCoord, _605, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _369, thread float4& gl_FragCoord, constant fa_shadows& _605, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1294 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2257 = _1294.direction;\n    float3 _2252 = _1294.color;\n    float _2254 = _1294.shadow;\n    int _2262 = _1294.type;\n    if ((_2262 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2257;\n        float _1308 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _369, gl_FragCoord, _605, fa_shadow_tex, fa_world_pos);\n        _2254 = _1308;\n        _2252 *= _1308;\n    }\n    return LightSample{ _2257, _2252, _1294.attenuation, _2254, _1294._distance, _2262 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _605)\n{\n    if (_605.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1148 = int(_605.fa_shadow_cfg.x + 0.5);\n    float _1158 = dot(world - _605.fa_shadow_eye.xyz, _605.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1163 = _1148 > 0;\n    bool _1172;\n    if (_1163)\n    {\n        int param = _1148 - 1;\n        _1172 = _1158 <= fa_shadow_split_at(param, _605);\n    }\n    else\n    {\n        _1172 = _1163;\n    }\n    if (_1172)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1179 = _1148 > 1;\n        bool _1186;\n        if (_1179)\n        {\n            _1186 = _1158 > _605.fa_shadow_split.x;\n        }\n        else\n        {\n            _1186 = _1179;\n        }\n        if (_1186)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1192 = _1148 > 2;\n        bool _1199;\n        if (_1192)\n        {\n            _1199 = _1158 > _605.fa_shadow_split.y;\n        }\n        else\n        {\n            _1199 = _1192;\n        }\n        if (_1199)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1205 = _1148 > 3;\n        bool _1212;\n        if (_1205)\n        {\n            _1212 = _1158 > _605.fa_shadow_split.z;\n        }\n        else\n        {\n            _1212 = _1205;\n        }\n        if (_1212)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _369 [[buffer(1)]], constant fa_shadows& _605 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2081 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2081 = -_2081;\n    }\n    float3 _1694 = fast::normalize(_369.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _369, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2081, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1694, short(gl_FrontFacing) };\n    Surface _1702 = fa_standard_surface(param_1, _369, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2120 = _1702.albedo;\n    float _2121 = _1702.alpha;\n    float3 _2122 = _1702.normal;\n    float _2123 = _1702.metallic;\n    float _2124 = _1702.roughness;\n    float _2125 = _1702.occlusion;\n    float3 _2126 = _1702.emission;\n    float _2127 = _1702.clearcoat;\n    float _2128 = _1702.clearcoat_roughness;\n    float3 _2129 = _1702.sheen_color;\n    float _2130 = _1702.sheen_roughness;\n    float _2131 = _1702.anisotropy;\n    float _2132 = _1702.anisotropy_rotation;\n    float _2133 = _1702.specular;\n    float _2134 = _1702.ior;\n    float3 _2135 = _1702.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2081, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1694, short(gl_FrontFacing) };\n    Surface param_3 = _1702;\n    surface(param_2, param_3);\n    _2120 = param_3.albedo;\n    _2121 = param_3.alpha;\n    _2122 = param_3.normal;\n    _2123 = param_3.metallic;\n    _2124 = param_3.roughness;\n    _2125 = param_3.occlusion;\n    _2126 = param_3.emission;\n    _2127 = param_3.clearcoat;\n    _2128 = param_3.clearcoat_roughness;\n    _2129 = param_3.sheen_color;\n    _2130 = param_3.sheen_roughness;\n    _2131 = param_3.anisotropy;\n    _2132 = param_3.anisotropy_rotation;\n    _2133 = param_3.specular;\n    _2134 = param_3.ior;\n    _2135 = param_3.specular_color;\n    float3 result;\n    if (_369.fa_emissive.w > 0.5)\n    {\n        result = _2120;\n    }\n    else\n    {\n        float3 _1723 = _2122;\n        float3 _1724 = fast::normalize(_1723);\n        _2122 = _1724;\n        float3 param_4 = _1724;\n        SurfaceInput param_5 = SurfaceInput{ in.fa_world_pos, _2081, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1694, short(gl_FrontFacing) };\n        Surface param_6 = Surface{ _2120, _2121, _2122, _2123, _2124, _2125, _2126, _2127, _2128, _2129, _2130, _2131, _2132, _2133, _2134, _2135 };\n        float3 param_7 = fa_ambient_light(param_4, _369, fa_irr_tex, fa_env_smp);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _1743 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1743; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8, fa_light_tex, fa_shadow_smp, _369, fa_cl_ndir, fa_cl_slot);\n            float3 param_10 = in.fa_world_pos;\n            float3 param_11 = _2081;\n            SurfaceInput param_12 = SurfaceInput{ in.fa_world_pos, _2081, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1694, short(gl_FrontFacing) };\n            Surface param_13 = Surface{ _2120, _2121, _2122, _2123, _2124, _2125, _2126, _2127, _2128, _2129, _2130, _2131, _2132, _2133, _2134, _2135 };\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11, fa_light_tex, fa_shadow_smp, _369, gl_FragCoord, _605, fa_shadow_tex, in.fa_world_pos);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _1780 = result;\n    float3 _1781 = _1780 + _2126;\n    result = _1781;\n    float3 param_15 = _1781;\n    float3 param_16 = in.fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16, _605);\n    bool _1790 = _369.fa_fog.w > 0.0;\n    bool _1797;\n    if (!_1790)\n    {\n        _1797 = _369.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1797 = _1790;\n    }\n    if (_1797)\n    {\n        float3 _1806 = in.fa_world_pos - _369.fa_camera_pos.xyz;\n        float _1812 = dot(_1806, _369.fa_fog_c.xyz);\n        bool _1816 = _369.fa_fog_c.w > 0.5;\n        float _1817;\n        if (_1816)\n        {\n            _1817 = _1812;\n        }\n        else\n        {\n            _1817 = length(_1806);\n        }\n        float _1829 = _1817 - _369.fa_fog_b.x;\n        if (_1829 > 0.0)\n        {\n            float _1838 = _369.fa_fog.w * _1829;\n            float tau = _1838 * _1838;\n            if (_369.fa_fog_b.y > 0.0)\n            {\n                float _1854;\n                if (_1816)\n                {\n                    _1854 = in.fa_world_pos.y - (_369.fa_fog_c.y * _1812);\n                }\n                else\n                {\n                    _1854 = _369.fa_camera_pos.y;\n                }\n                float _1875 = mix(_1854, in.fa_world_pos.y, fast::clamp(_369.fa_fog_b.x / _1817, 0.0, 1.0));\n                float _1879 = in.fa_world_pos.y - _1875;\n                float _1884 = _1875 - _369.fa_fog_b.z;\n                float _1889 = in.fa_world_pos.y - _369.fa_fog_b.z;\n                bool _1892 = _1884 <= 0.0;\n                bool _1893 = !_1892;\n                bool _1899;\n                if (_1893)\n                {\n                    _1899 = _369.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1899 = _1892;\n                }\n                float _1900;\n                if (_1899)\n                {\n                    _1900 = _369.fa_fog_b.y;\n                }\n                else\n                {\n                    _1900 = _369.fa_fog_b.y * exp(-fast::min(_369.fa_fog_b.w * _1884, 80.0));\n                }\n                bool _1927;\n                if (_1893)\n                {\n                    _1927 = _369.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1927 = _1892;\n                }\n                float _1928;\n                if (_1927)\n                {\n                    _1928 = _369.fa_fog_b.y * _1884;\n                }\n                else\n                {\n                    _1928 = (_369.fa_fog_b.y * (1.0 - exp(-fast::min(_369.fa_fog_b.w * _1884, 80.0)))) / _369.fa_fog_b.w;\n                }\n                bool _1953 = _1889 <= 0.0;\n                bool _1960;\n                if (!_1953)\n                {\n                    _1960 = _369.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1960 = _1953;\n                }\n                float _1961;\n                if (_1960)\n                {\n                    _1961 = _369.fa_fog_b.y * _1889;\n                }\n                else\n                {\n                    _1961 = (_369.fa_fog_b.y * (1.0 - exp(-fast::min(_369.fa_fog_b.w * _1889, 80.0)))) / _369.fa_fog_b.w;\n                }\n                float _1988;\n                if (abs(_1879) < 0.001000000047497451305389404296875)\n                {\n                    _1988 = _1900;\n                }\n                else\n                {\n                    _1988 = (_1961 - _1928) / _1879;\n                }\n                tau += (_1829 * fast::max(_1988, 0.0));\n            }\n            result = mix(result, _369.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2121);\n    return out;\n}\n\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_369",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_605",
            "msl_buffer_n": 7
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_386, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _369)\n{\n    bool _374 = _369.fa_cl_info.x < 0.0;\n    bool _381;\n    if (!_374)\n    {\n        _381 = _369.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _381 = _374;\n    }\n    bool _389;\n    if (!_381)\n    {\n        _389 = _369.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _389 = _381;\n    }\n    bool _396;\n    if (!_389)\n    {\n        _396 = _369.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _396 = _389;\n    }\n    bool _403;\n    if (!_396)\n    {\n        _403 = _369.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _403 = _396;\n    }\n    if (_403)\n    {\n        return int2(0);\n    }\n    float4 _413 = float4(world_pos, 1.0);\n    float _420 = dot(_369.fa_cl_vpw, _413);\n    if (!(_420 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _442 = float2(dot(_369.fa_cl_vpx, _413), dot(_369.fa_cl_vpy, _413)) / float2(_420);\n    int _446 = int(_369.fa_cl_grid.x);\n    int _450 = int(_369.fa_cl_grid.y);\n    int param = (int(_369.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_369.fa_cl_fwd.xyz, world_pos) + _369.fa_cl_fwd.w, _369.fa_cl_grid.w) / _369.fa_cl_grid.w) * _369.fa_cl_grid.z)), 0, int(_369.fa_cl_info.y) - 1) * _450) + clamp(int(floor(((_442.y * 0.5) + 0.5) * _369.fa_cl_grid.y)), 0, _450 - 1)) * _446)) + clamp(int(floor(((_442.x * 0.5) + 0.5) * _369.fa_cl_grid.x)), 0, _446 - 1);\n    float4 _521 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_521.x), int(_521.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _369, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_369.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1266 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _369);\n    fa_cl_slot = _1266.x;\n    fa_cl_local = _1266.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1374 = fa_linear_to_srgb(param);\n        c = _1374;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1382 = fa_srgb_to_linear(param_1);\n            c = _1382;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _150;\n    if (bool(i.front_facing))\n    {\n        _150 = i.world_normal;\n    }\n    else\n    {\n        _150 = -i.world_normal;\n    }\n    float3 _174 = fast::normalize(i.world_tangent.xyz - (_150 * dot(_150, i.world_tangent.xyz)));\n    float3 _202 = fast::normalize(((_174 * m.x) + ((cross(_150, _174) * i.world_tangent.w) * m.y)) + (_150 * m.z));\n    float3 _205;\n    if (bool(i.front_facing))\n    {\n        _205 = _202;\n    }\n    else\n    {\n        _205 = -_202;\n    }\n    return _205;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _369, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _369.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1413 = fa_tex_fix(param_2, param_3);\n    float4 _2325 = base_t;\n    _2325.x = _1413.x;\n    _2325.y = _1413.y;\n    _2325.z = _1413.z;\n    base_t = _2325;\n    float4 _1427 = (_2325 * _369.fa_base_color) * i.vertex_color;\n    float3 _2272 = i.world_normal;\n    if (_369.fa_maps.z > 0.5)\n    {\n        float param_4 = _369.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1459 = fa_tex_fix(param_6, param_7);\n        float3 _1463 = (_1459 * 2.0) - float3(1.0);\n        float2 _1468 = _1463.xy * _369.fa_maps.x;\n        float3 _2333 = _1463;\n        _2333.x = _1468.x;\n        _2333.y = _1468.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2333;\n        _2272 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _369.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1497 = fa_tex_fix(param_12, param_13);\n    float4 _2336 = mrt;\n    _2336.x = _1497.x;\n    _2336.y = _1497.y;\n    _2336.z = _1497.z;\n    mrt = _2336;\n    float4 _1526 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _369.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1526.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1538 = fa_tex_fix(param_16, param_17);\n    float param_18 = _369.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1568 = fa_tex_fix(param_20, param_21);\n    float _2277 = _369.fa_layers_a.x;\n    float _2278 = _369.fa_layers_a.y;\n    float _2281 = _369.fa_layers_a.z;\n    float _2280 = _369.fa_layers_b.w;\n    float _2283 = _369.fa_layers_c.x;\n    if (_369.fa_layers_c.z > 0.5)\n    {\n        if (mod(_369.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2277 *= _1538.y;\n            _2278 *= _1538.z;\n            _2280 *= _1526.w;\n        }\n        if (_369.fa_layers_c.z > 1.5)\n        {\n            _2281 *= mrt.x;\n            _2283 *= mrt.w;\n        }\n    }\n    return Surface{ _1427.xyz, _1427.w, _2272, fast::clamp(_369.fa_pbr.x * _1497.z, 0.0, 1.0), fast::clamp(_369.fa_pbr.y * _1497.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_369.fa_maps.y * (_1538.x - 1.0)), _369.fa_emissive.xyz + (_369.fa_model_emissive.xyz * _1568), _2277, _2278, _369.fa_layers_b.xyz, _2280, _2281, _369.fa_layers_a.w, _2283, _369.fa_layers_c.y, _369.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _369, texturecube<float> fa_irr_tex, sampler fa_env_smp)\n{\n    if (_369.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _369.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _369)\n{\n    int param = (int(_369.fa_cl_info.x) + int(_369.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _369, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _369);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _242 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _248 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _251 = _248.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _258 = _251 < 0.5;\n    float3 l;\n    if (_258)\n    {\n        l = fast::normalize(_242.xyz);\n    }\n    else\n    {\n        float3 _270 = _242.xyz - world_pos;\n        float _272 = length(_270);\n        dist = _272;\n        l = _270 / float3(fast::max(_272, 9.9999997473787516355514526367188e-05));\n        float _287 = _272 / fast::max(_242.w, 0.001000000047497451305389404296875);\n        float _293 = fast::clamp(1.0 - (_287 * _287), 0.0, 1.0);\n        atten = _293 * _293;\n        if (_251 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _307 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _317 = _307.w;\n            int param_3 = (li * 4) + 3;\n            float4 _324 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _325 = _324.x;\n            float cos_inner = _325;\n            if (_325 > 1.5)\n            {\n                cos_inner = mix(_317, 1.0, 0.25);\n            }\n            atten *= smoothstep(_317, cos_inner, dot(-l, fast::normalize(_307.xyz)));\n        }\n    }\n    int _355;\n    if (_258)\n    {\n        _355 = 0;\n    }\n    else\n    {\n        _355 = (_251 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _248.xyz * atten, atten, 1.0, dist, _355 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _605)\n{\n    float _595;\n    if (i == 0)\n    {\n        _595 = _605.fa_shadow_split.x;\n    }\n    else\n    {\n        float _611;\n        if (i == 1)\n        {\n            _611 = _605.fa_shadow_split.y;\n        }\n        else\n        {\n            float _619;\n            if (i == 2)\n            {\n                _619 = _605.fa_shadow_split.z;\n            }\n            else\n            {\n                _619 = _605.fa_shadow_split.w;\n            }\n            _611 = _619;\n        }\n        _595 = _611;\n    }\n    return _595;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _583 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_583), sin(_583)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _605, texture2d<float> fa_shadow_tex)\n{\n    float _657 = fast::max(_605.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _662 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _668 = sqrt(1.0 - (_662 * _662));\n    float _676 = fast::min(_668 / fast::max(_662, 0.20000000298023223876953125), 4.0);\n    float _681;\n    if (_605.fa_shadow_bias.y > 0.0)\n    {\n        _681 = _605.fa_shadow_bias.y;\n    }\n    else\n    {\n        _681 = 1.5 * _605.fa_shadow_info[ci].x;\n    }\n    float4 _706 = _605.fa_shadow_mat[ci] * float4(world + (n * (_681 * _668)), 1.0);\n    float _713 = _706.x;\n    bool _716 = _713 < _605.fa_shadow_rect[ci].x;\n    bool _725;\n    if (!_716)\n    {\n        _725 = _713 > _605.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _725 = _716;\n    }\n    bool _734;\n    if (!_725)\n    {\n        _734 = _706.y < _605.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _734 = _725;\n    }\n    bool _743;\n    if (!_734)\n    {\n        _743 = _706.y > _605.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _743 = _734;\n    }\n    bool _750;\n    if (!_743)\n    {\n        _750 = _706.z > 1.0;\n    }\n    else\n    {\n        _750 = _743;\n    }\n    if (_750)\n    {\n        return -1.0;\n    }\n    float _759;\n    if (_605.fa_shadow_bias.x > 0.0)\n    {\n        _759 = _605.fa_shadow_bias.x;\n    }\n    else\n    {\n        _759 = 1.5 * _605.fa_shadow_info[ci].x;\n    }\n    float _778 = _706.z - ((_759 * (1.0 + (0.5 * _676))) / _657);\n    float _787 = ((_605.fa_shadow_info[ci].x * fast::min(_676, 3.0)) * 0.5) / _657;\n    int _796 = int(_605.fa_shadow_cfg.z + 0.5);\n    if (_796 == 1)\n    {\n        float2 param = _706.xy;\n        float4 param_1 = _605.fa_shadow_rect[ci];\n        float _807 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_778 <= _807);\n    }\n    float _814 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _817 = _796 == 2;\n    if (_817)\n    {\n        float _831 = fast::clamp(((_605.fa_shadow_cfg.w * _657) * 0.25) / _605.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _814;\n            float2 _850 = fa_shadow_vogel(param_2, param_3, param_4) * _831;\n            float2 param_5 = _706.xy + (_850 * _605.fa_shadow_bias.zw);\n            float4 param_6 = _605.fa_shadow_rect[ci];\n            float _861 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_861 < (_778 - (length(_850) * _787)))\n            {\n                sum += _861;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_778 - (sum / cnt), 0.0) * _657) * _605.fa_shadow_cfg.w) / _605.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _905 = _817 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _905; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _905;\n        float param_9 = _814;\n        float2 _924 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _706.xy + (_924 * _605.fa_shadow_bias.zw);\n        float4 param_11 = _605.fa_shadow_rect[ci];\n        float _935 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_778 - (length(_924) * _787)) <= _935);\n    }\n    return lit / float(_905);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _369, thread float4& gl_FragCoord, constant fa_shadows& _605, texture2d<float> fa_shadow_tex)\n{\n    if (_369.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _965 = int(_605.fa_shadow_cfg.x + 0.5);\n    if (_965 < 1)\n    {\n        return 1.0;\n    }\n    float _981 = dot(world - _605.fa_shadow_eye.xyz, _605.fa_shadow_fwd.xyz);\n    int param = _965 - 1;\n    if (_981 > fa_shadow_split_at(param, _605))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _993 = _965 > 1;\n    bool _1000;\n    if (_993)\n    {\n        _1000 = _981 > _605.fa_shadow_split.x;\n    }\n    else\n    {\n        _1000 = _993;\n    }\n    if (_1000)\n    {\n        ci = 1;\n    }\n    bool _1004 = _965 > 2;\n    bool _1011;\n    if (_1004)\n    {\n        _1011 = _981 > _605.fa_shadow_split.y;\n    }\n    else\n    {\n        _1011 = _1004;\n    }\n    if (_1011)\n    {\n        ci = 2;\n    }\n    bool _1015 = _965 > 3;\n    bool _1022;\n    if (_1015)\n    {\n        _1022 = _981 > _605.fa_shadow_split.z;\n    }\n    else\n    {\n        _1022 = _1015;\n    }\n    if (_1022)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _965)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1048 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _605, fa_shadow_tex);\n        s = _1048;\n        if (_1048 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_605.fa_shadow_cfg.y > 0.0)\n    {\n        float _1073;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1073 = fa_shadow_split_at(param_5, _605);\n        }\n        else\n        {\n            _1073 = _605.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1092 = _605.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _605) - _1073, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1103 = fast::clamp((_981 - (fa_shadow_split_at(param_7, _605) - _1092)) / _1092, 0.0, 1.0);\n        if (_1103 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _965)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1124 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _605, fa_shadow_tex);\n                s2 = _1124;\n                if (_1124 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1103);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _369, thread float4& gl_FragCoord, constant fa_shadows& _605, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _369, gl_FragCoord, _605, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _369, thread float4& gl_FragCoord, constant fa_shadows& _605, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1294 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2257 = _1294.direction;\n    float3 _2252 = _1294.color;\n    float _2254 = _1294.shadow;\n    int _2262 = _1294.type;\n    if ((_2262 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2257;\n        float _1308 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _369, gl_FragCoord, _605, fa_shadow_tex, fa_world_pos);\n        _2254 = _1308;\n        _2252 *= _1308;\n    }\n    return LightSample{ _2257, _2252, _1294.attenuation, _2254, _1294._distance, _2262 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _605)\n{\n    if (_605.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1148 = int(_605.fa_shadow_cfg.x + 0.5);\n    float _1158 = dot(world - _605.fa_shadow_eye.xyz, _605.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1163 = _1148 > 0;\n    bool _1172;\n    if (_1163)\n    {\n        int param = _1148 - 1;\n        _1172 = _1158 <= fa_shadow_split_at(param, _605);\n    }\n    else\n    {\n        _1172 = _1163;\n    }\n    if (_1172)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1179 = _1148 > 1;\n        bool _1186;\n        if (_1179)\n        {\n            _1186 = _1158 > _605.fa_shadow_split.x;\n        }\n        else\n        {\n            _1186 = _1179;\n        }\n        if (_1186)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1192 = _1148 > 2;\n        bool _1199;\n        if (_1192)\n        {\n            _1199 = _1158 > _605.fa_shadow_split.y;\n        }\n        else\n        {\n            _1199 = _1192;\n        }\n        if (_1199)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1205 = _1148 > 3;\n        bool _1212;\n        if (_1205)\n        {\n            _1212 = _1158 > _605.fa_shadow_split.z;\n        }\n        else\n        {\n            _1212 = _1205;\n        }\n        if (_1212)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _369 [[buffer(1)]], constant fa_shadows& _605 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2081 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2081 = -_2081;\n    }\n    float3 _1694 = fast::normalize(_369.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _369, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2081, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1694, short(gl_FrontFacing) };\n    Surface _1702 = fa_standard_surface(param_1, _369, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2120 = _1702.albedo;\n    float _2121 = _1702.alpha;\n    float3 _2122 = _1702.normal;\n    float _2123 = _1702.metallic;\n    float _2124 = _1702.roughness;\n    float _2125 = _1702.occlusion;\n    float3 _2126 = _1702.emission;\n    float _2127 = _1702.clearcoat;\n    float _2128 = _1702.clearcoat_roughness;\n    float3 _2129 = _1702.sheen_color;\n    float _2130 = _1702.sheen_roughness;\n    float _2131 = _1702.anisotropy;\n    float _2132 = _1702.anisotropy_rotation;\n    float _2133 = _1702.specular;\n    float _2134 = _1702.ior;\n    float3 _2135 = _1702.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2081, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1694, short(gl_FrontFacing) };\n    Surface param_3 = _1702;\n    surface(param_2, param_3);\n    _2120 = param_3.albedo;\n    _2121 = param_3.alpha;\n    _2122 = param_3.normal;\n    _2123 = param_3.metallic;\n    _2124 = param_3.roughness;\n    _2125 = param_3.occlusion;\n    _2126 = param_3.emission;\n    _2127 = param_3.clearcoat;\n    _2128 = param_3.clearcoat_roughness;\n    _2129 = param_3.sheen_color;\n    _2130 = param_3.sheen_roughness;\n    _2131 = param_3.anisotropy;\n    _2132 = param_3.anisotropy_rotation;\n    _2133 = param_3.specular;\n    _2134 = param_3.ior;\n    _2135 = param_3.specular_color;\n    float3 result;\n    if (_369.fa_emissive.w > 0.5)\n    {\n        result = _2120;\n    }\n    else\n    {\n        float3 _1723 = _2122;\n        float3 _1724 = fast::normalize(_1723);\n        _2122 = _1724;\n        float3 param_4 = _1724;\n        SurfaceInput param_5 = SurfaceInput{ in.fa_world_pos, _2081, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1694, short(gl_FrontFacing) };\n        Surface param_6 = Surface{ _2120, _2121, _2122, _2123, _2124, _2125, _2126, _2127, _2128, _2129, _2130, _2131, _2132, _2133, _2134, _2135 };\n        float3 param_7 = fa_ambient_light(param_4, _369, fa_irr_tex, fa_env_smp);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _1743 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1743; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8, fa_light_tex, fa_shadow_smp, _369, fa_cl_ndir, fa_cl_slot);\n            float3 param_10 = in.fa_world_pos;\n            float3 param_11 = _2081;\n            SurfaceInput param_12 = SurfaceInput{ in.fa_world_pos, _2081, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _1694, short(gl_FrontFacing) };\n            Surface param_13 = Surface{ _2120, _2121, _2122, _2123, _2124, _2125, _2126, _2127, _2128, _2129, _2130, _2131, _2132, _2133, _2134, _2135 };\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11, fa_light_tex, fa_shadow_smp, _369, gl_FragCoord, _605, fa_shadow_tex, in.fa_world_pos);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _1780 = result;\n    float3 _1781 = _1780 + _2126;\n    result = _1781;\n    float3 param_15 = _1781;\n    float3 param_16 = in.fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16, _605);\n    bool _1790 = _369.fa_fog.w > 0.0;\n    bool _1797;\n    if (!_1790)\n    {\n        _1797 = _369.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1797 = _1790;\n    }\n    if (_1797)\n    {\n        float3 _1806 = in.fa_world_pos - _369.fa_camera_pos.xyz;\n        float _1812 = dot(_1806, _369.fa_fog_c.xyz);\n        bool _1816 = _369.fa_fog_c.w > 0.5;\n        float _1817;\n        if (_1816)\n        {\n            _1817 = _1812;\n        }\n        else\n        {\n            _1817 = length(_1806);\n        }\n        float _1829 = _1817 - _369.fa_fog_b.x;\n        if (_1829 > 0.0)\n        {\n            float _1838 = _369.fa_fog.w * _1829;\n            float tau = _1838 * _1838;\n            if (_369.fa_fog_b.y > 0.0)\n            {\n                float _1854;\n                if (_1816)\n                {\n                    _1854 = in.fa_world_pos.y - (_369.fa_fog_c.y * _1812);\n                }\n                else\n                {\n                    _1854 = _369.fa_camera_pos.y;\n                }\n                float _1875 = mix(_1854, in.fa_world_pos.y, fast::clamp(_369.fa_fog_b.x / _1817, 0.0, 1.0));\n                float _1879 = in.fa_world_pos.y - _1875;\n                float _1884 = _1875 - _369.fa_fog_b.z;\n                float _1889 = in.fa_world_pos.y - _369.fa_fog_b.z;\n                bool _1892 = _1884 <= 0.0;\n                bool _1893 = !_1892;\n                bool _1899;\n                if (_1893)\n                {\n                    _1899 = _369.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1899 = _1892;\n                }\n                float _1900;\n                if (_1899)\n                {\n                    _1900 = _369.fa_fog_b.y;\n                }\n                else\n                {\n                    _1900 = _369.fa_fog_b.y * exp(-fast::min(_369.fa_fog_b.w * _1884, 80.0));\n                }\n                bool _1927;\n                if (_1893)\n                {\n                    _1927 = _369.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1927 = _1892;\n                }\n                float _1928;\n                if (_1927)\n                {\n                    _1928 = _369.fa_fog_b.y * _1884;\n                }\n                else\n                {\n                    _1928 = (_369.fa_fog_b.y * (1.0 - exp(-fast::min(_369.fa_fog_b.w * _1884, 80.0)))) / _369.fa_fog_b.w;\n                }\n                bool _1953 = _1889 <= 0.0;\n                bool _1960;\n                if (!_1953)\n                {\n                    _1960 = _369.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1960 = _1953;\n                }\n                float _1961;\n                if (_1960)\n                {\n                    _1961 = _369.fa_fog_b.y * _1889;\n                }\n                else\n                {\n                    _1961 = (_369.fa_fog_b.y * (1.0 - exp(-fast::min(_369.fa_fog_b.w * _1889, 80.0)))) / _369.fa_fog_b.w;\n                }\n                float _1988;\n                if (abs(_1879) < 0.001000000047497451305389404296875)\n                {\n                    _1988 = _1900;\n                }\n                else\n                {\n                    _1988 = (_1961 - _1928) / _1879;\n                }\n                tau += (_1829 * fast::max(_1988, 0.0));\n            }\n            result = mix(result, _369.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2121);\n    return out;\n}\n\n",
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
            "size": 160,
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
            "inst_name": "_369",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_605",
            "msl_buffer_n": 7
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213.fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213.fa_layers_a.x;\n    float _752 = _213.fa_layers_a.y;\n    float _755 = _213.fa_layers_a.z;\n    float _754 = _213.fa_layers_b.w;\n    float _757 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _746, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _751, _752, _213.fa_layers_b.xyz, _754, _755, _213.fa_layers_a.w, _757, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _657 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _657, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _657, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 160,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    float4 _241 = (_783 * _213.fa_base_color) * i.vertex_color;\n    float3 _746 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = _213.fa_layers_a.x;\n    float _752 = _213.fa_layers_a.y;\n    float _755 = _213.fa_layers_a.z;\n    float _754 = _213.fa_layers_b.w;\n    float _757 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _746, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _751, _752, _213.fa_layers_b.xyz, _754, _755, _213.fa_layers_a.w, _757, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _657 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _657, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _657, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 160,
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
