{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "738bdbaa5d236ca82c68b48e7af94b35c54ba5d6311eabf2bcbbc814ba3d221c",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_265, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _238, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _710 = _238.fa_cl_info.x < 0.0;\n    bool _717;\n    if (!_710)\n    {\n        _717 = _238.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _717 = _710;\n    }\n    bool _725;\n    if (!_717)\n    {\n        _725 = _238.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _725 = _717;\n    }\n    bool _732;\n    if (!_725)\n    {\n        _732 = _238.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _732 = _725;\n    }\n    bool _739;\n    if (!_732)\n    {\n        _739 = _238.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _739 = _732;\n    }\n    if (_739)\n    {\n        return int2(0);\n    }\n    float4 _749 = float4(world_pos, 1.0);\n    float _756 = dot(_238.fa_cl_vpw, _749);\n    if (!(_756 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _778 = float2(dot(_238.fa_cl_vpx, _749), dot(_238.fa_cl_vpy, _749)) / float2(_756);\n    int _782 = int(_238.fa_cl_grid.x);\n    int _786 = int(_238.fa_cl_grid.y);\n    int param = (int(_238.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_238.fa_cl_fwd.xyz, world_pos) + _238.fa_cl_fwd.w, _238.fa_cl_grid.w) / _238.fa_cl_grid.w) * _238.fa_cl_grid.z)), 0, int(_238.fa_cl_info.y) - 1) * _786) + clamp(int(floor(((_778.y * 0.5) + 0.5) * _238.fa_cl_grid.y)), 0, _786 - 1)) * _782)) + clamp(int(floor(((_778.x * 0.5) + 0.5) * _238.fa_cl_grid.x)), 0, _782 - 1);\n    float4 _857 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_857.x), int(_857.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _238, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_238.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1599 = fa_cluster_lookup(param, _238, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _1599.x;\n    fa_cl_local = _1599.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1707 = fa_linear_to_srgb(param);\n        c = _1707;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1715 = fa_srgb_to_linear(param_1);\n            c = _1715;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _170;\n    if (bool(i.front_facing))\n    {\n        _170 = i.world_normal;\n    }\n    else\n    {\n        _170 = -i.world_normal;\n    }\n    float3 _194 = fast::normalize(i.world_tangent.xyz - (_170 * dot(_170, i.world_tangent.xyz)));\n    float3 _222 = fast::normalize(((_194 * m.x) + ((cross(_170, _194) * i.world_tangent.w) * m.y)) + (_170 * m.z));\n    float3 _225;\n    if (bool(i.front_facing))\n    {\n        _225 = _222;\n    }\n    else\n    {\n        _225 = -_222;\n    }\n    return _225;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _238, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _238.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1746 = fa_tex_fix(param_2, param_3);\n    float4 _2666 = base_t;\n    _2666.x = _1746.x;\n    _2666.y = _1746.y;\n    _2666.z = _1746.z;\n    base_t = _2666;\n    float4 _1760 = (_2666 * _238.fa_base_color) * i.vertex_color;\n    float3 _2603 = i.world_normal;\n    if (_238.fa_maps.z > 0.5)\n    {\n        float param_4 = _238.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1792 = fa_tex_fix(param_6, param_7);\n        float3 _1796 = (_1792 * 2.0) - float3(1.0);\n        float2 _1801 = _1796.xy * _238.fa_maps.x;\n        float3 _2674 = _1796;\n        _2674.x = _1801.x;\n        _2674.y = _1801.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2674;\n        _2603 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _238.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1829 = fa_tex_fix(param_12, param_13);\n    float4 _2677 = mrt;\n    _2677.x = _1829.x;\n    _2677.y = _1829.y;\n    _2677.z = _1829.z;\n    mrt = _2677;\n    float4 _1858 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _238.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1858.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1870 = fa_tex_fix(param_16, param_17);\n    float param_18 = _238.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1900 = fa_tex_fix(param_20, param_21);\n    float _2608 = _238.fa_layers_a.x;\n    float _2609 = _238.fa_layers_a.y;\n    float _2612 = _238.fa_layers_a.z;\n    float _2611 = _238.fa_layers_b.w;\n    float _2614 = _238.fa_layers_c.x;\n    if (_238.fa_layers_c.z > 0.5)\n    {\n        if (mod(_238.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2608 *= _1870.y;\n            _2609 *= _1870.z;\n            _2611 *= _1858.w;\n        }\n        if (_238.fa_layers_c.z > 1.5)\n        {\n            _2612 *= mrt.x;\n            _2614 *= mrt.w;\n        }\n    }\n    return Surface{ _1760.xyz, _1760.w, _2603, fast::clamp(_238.fa_pbr.x * _1829.z, 0.0, 1.0), fast::clamp(_238.fa_pbr.y * _1829.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_238.fa_maps.y * (_1870.x - 1.0)), _238.fa_emissive.xyz + (_238.fa_model_emissive.xyz * _1900), _2608, _2609, _238.fa_layers_b.xyz, _2611, _2612, _238.fa_layers_a.w, _2614, _238.fa_layers_c.y, _238.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _238, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_238.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _238.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _238, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_238.fa_cl_info.x) + int(_238.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _238, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _238, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _238)\n{\n    return li * ((_238.fa_counts.y > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _319 = dot(d, right);\n    float _323 = dot(d, up);\n    float _334;\n    if (((_319 * _319) + (_323 * _323)) > 1.0000000133514319600180897396058e-10)\n    {\n        _334 = precise::atan2(_323, _319) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _334 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_334 - floor(_334)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_mesh_fs_params& _238, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _367 = fa_light_base(param, _238);\n    bool _371 = _238.fa_counts.y > 4.5;\n    int param_1 = _367;\n    float4 _375 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _367 + 1;\n    float4 _380 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _383 = _380.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _395 = _371 && (_383 > 2.5);\n    fa_light_is_area = _395;\n    bool _398 = _383 < 0.5;\n    float3 l;\n    if (_398)\n    {\n        l = fast::normalize(_375.xyz);\n        if (_371)\n        {\n            int param_3 = _367 + 6;\n            float4 _412 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_412.z > 0.5)\n            {\n                int param_4 = _367 + 4;\n                float4 _422 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _367 + 5;\n                float4 _428 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _412.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _422.xyz) * _422.w, (-dot(world_pos, _428.xyz)) * _428.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _460 = _375.xyz - world_pos;\n        float _462 = length(_460);\n        dist = _462;\n        l = _460 / float3(fast::max(_462, 9.9999997473787516355514526367188e-05));\n        float reach = _462;\n        if (_395)\n        {\n            int param_8 = _367 + 7;\n            reach = fast::max(dist - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n        }\n        float _494 = reach / fast::max(_375.w, 0.001000000047497451305389404296875);\n        float _500 = fast::clamp(1.0 - (_494 * _494), 0.0, 1.0);\n        atten = _500 * _500;\n        bool _508 = _383 < 2.5;\n        if ((_383 > 1.5) && _508)\n        {\n            int param_9 = _367 + 2;\n            float4 _516 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            float _526 = _516.w;\n            int param_10 = _367 + 3;\n            float4 _532 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            float _533 = _532.x;\n            float cos_inner = _533;\n            if (_533 > 1.5)\n            {\n                cos_inner = mix(_526, 1.0, 0.25);\n            }\n            atten *= smoothstep(_526, cos_inner, dot(-l, fast::normalize(_516.xyz)));\n        }\n        if (_371 && _508)\n        {\n            int param_11 = _367 + 6;\n            float4 _557 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            int param_12 = _367 + 7;\n            float4 _562 = fa_light_texel(param_12, fa_light_tex, fa_shadow_smp);\n            bool _565 = _557.z > 0.5;\n            bool _572;\n            if (!_565)\n            {\n                _572 = _562.z > 0.5;\n            }\n            else\n            {\n                _572 = _565;\n            }\n            if (_572)\n            {\n                int param_13 = _367 + 2;\n                float4 _579 = fa_light_texel(param_13, fa_light_tex, fa_shadow_smp);\n                float3 _583 = fast::normalize(_579.xyz);\n                int param_14 = _367 + 4;\n                float4 _588 = fa_light_texel(param_14, fa_light_tex, fa_shadow_smp);\n                int param_15 = _367 + 5;\n                float4 _593 = fa_light_texel(param_15, fa_light_tex, fa_shadow_smp);\n                if (_565)\n                {\n                    float3 _601 = -_460;\n                    float _608 = _579.w;\n                    float _624 = 0.5 / fast::max(dot(_601, _583) * (sqrt(fast::max(1.0 - (_608 * _608), 0.0)) / fast::max(_608, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    float2 param_16 = _557.xy;\n                    float2 param_17 = float2(0.5 + (dot(_601, _588.xyz) * _624), 0.5 - (dot(_601, _593.xyz) * _624));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17, fa_light_atlas, fa_env_smp);\n                }\n                if (_562.z > 0.5)\n                {\n                    float2 param_18 = _562.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _583;\n                    float3 param_21 = _588.xyz;\n                    float3 param_22 = _593.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22, fa_light_atlas, fa_env_smp);\n                }\n            }\n        }\n    }\n    float3 _2570 = _380.xyz * atten;\n    if (_371)\n    {\n        _2570 *= fa_light_tint;\n    }\n    int _692;\n    if (_398)\n    {\n        _692 = 0;\n    }\n    else\n    {\n        _692 = ((_383 > 1.5) && (_383 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _2570, atten, 1.0, dist, _692 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _941)\n{\n    float _931;\n    if (i == 0)\n    {\n        _931 = _941.fa_shadow_split.x;\n    }\n    else\n    {\n        float _947;\n        if (i == 1)\n        {\n            _947 = _941.fa_shadow_split.y;\n        }\n        else\n        {\n            float _955;\n            if (i == 2)\n            {\n                _955 = _941.fa_shadow_split.z;\n            }\n            else\n            {\n                _955 = _941.fa_shadow_split.w;\n            }\n            _947 = _955;\n        }\n        _931 = _947;\n    }\n    return _931;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _919 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_919), sin(_919)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _941, texture2d<float> fa_shadow_tex)\n{\n    float _993 = fast::max(_941.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _998 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1004 = sqrt(1.0 - (_998 * _998));\n    float _1012 = fast::min(_1004 / fast::max(_998, 0.20000000298023223876953125), 4.0);\n    float _1017;\n    if (_941.fa_shadow_bias.y > 0.0)\n    {\n        _1017 = _941.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1017 = 1.5 * _941.fa_shadow_info[ci].x;\n    }\n    float4 _1042 = _941.fa_shadow_mat[ci] * float4(world + (n * (_1017 * _1004)), 1.0);\n    float _1049 = _1042.x;\n    bool _1052 = _1049 < _941.fa_shadow_rect[ci].x;\n    bool _1061;\n    if (!_1052)\n    {\n        _1061 = _1049 > _941.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1061 = _1052;\n    }\n    bool _1070;\n    if (!_1061)\n    {\n        _1070 = _1042.y < _941.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1070 = _1061;\n    }\n    bool _1079;\n    if (!_1070)\n    {\n        _1079 = _1042.y > _941.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1079 = _1070;\n    }\n    bool _1086;\n    if (!_1079)\n    {\n        _1086 = _1042.z > 1.0;\n    }\n    else\n    {\n        _1086 = _1079;\n    }\n    if (_1086)\n    {\n        return -1.0;\n    }\n    float _1094;\n    if (_941.fa_shadow_bias.x > 0.0)\n    {\n        _1094 = _941.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1094 = 1.5 * _941.fa_shadow_info[ci].x;\n    }\n    float _1113 = _1042.z - ((_1094 * (1.0 + (0.5 * _1012))) / _993);\n    float _1122 = ((_941.fa_shadow_info[ci].x * fast::min(_1012, 3.0)) * 0.5) / _993;\n    int _1131 = int(_941.fa_shadow_cfg.z + 0.5);\n    if (_1131 == 1)\n    {\n        float2 param = _1042.xy;\n        float4 param_1 = _941.fa_shadow_rect[ci];\n        float _1142 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1113 <= _1142);\n    }\n    float _1149 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1152 = _1131 == 2;\n    if (_1152)\n    {\n        float _1166 = fast::clamp(((_941.fa_shadow_cfg.w * _993) * 0.25) / _941.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1149;\n            float2 _1185 = fa_shadow_vogel(param_2, param_3, param_4) * _1166;\n            float2 param_5 = _1042.xy + (_1185 * _941.fa_shadow_bias.zw);\n            float4 param_6 = _941.fa_shadow_rect[ci];\n            float _1196 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1196 < (_1113 - (length(_1185) * _1122)))\n            {\n                sum += _1196;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1113 - (sum / cnt), 0.0) * _993) * _941.fa_shadow_cfg.w) / _941.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1240 = _1152 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1240; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1240;\n        float param_9 = _1149;\n        float2 _1259 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1042.xy + (_1259 * _941.fa_shadow_bias.zw);\n        float4 param_11 = _941.fa_shadow_rect[ci];\n        float _1270 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1113 - (length(_1259) * _1122)) <= _1270);\n    }\n    return lit / float(_1240);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _238, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _941, texture2d<float> fa_shadow_tex)\n{\n    if (_238.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1300 = int(_941.fa_shadow_cfg.x + 0.5);\n    if (_1300 < 1)\n    {\n        return 1.0;\n    }\n    float _1315 = dot(world - _941.fa_shadow_eye.xyz, _941.fa_shadow_fwd.xyz);\n    int param = _1300 - 1;\n    if (_1315 > fa_shadow_split_at(param, _941))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1327 = _1300 > 1;\n    bool _1334;\n    if (_1327)\n    {\n        _1334 = _1315 > _941.fa_shadow_split.x;\n    }\n    else\n    {\n        _1334 = _1327;\n    }\n    if (_1334)\n    {\n        ci = 1;\n    }\n    bool _1338 = _1300 > 2;\n    bool _1345;\n    if (_1338)\n    {\n        _1345 = _1315 > _941.fa_shadow_split.y;\n    }\n    else\n    {\n        _1345 = _1338;\n    }\n    if (_1345)\n    {\n        ci = 2;\n    }\n    bool _1349 = _1300 > 3;\n    bool _1356;\n    if (_1349)\n    {\n        _1356 = _1315 > _941.fa_shadow_split.z;\n    }\n    else\n    {\n        _1356 = _1349;\n    }\n    if (_1356)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1300)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1382 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _941, fa_shadow_tex);\n        s = _1382;\n        if (_1382 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_941.fa_shadow_cfg.y > 0.0)\n    {\n        float _1407;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1407 = fa_shadow_split_at(param_5, _941);\n        }\n        else\n        {\n            _1407 = _941.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1426 = _941.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _941) - _1407, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1437 = fast::clamp((_1315 - (fa_shadow_split_at(param_7, _941) - _1426)) / _1426, 0.0, 1.0);\n        if (_1437 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1300)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1458 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _941, fa_shadow_tex);\n                s2 = _1458;\n                if (_1458 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1437);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _238, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _941, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _238, fa_shadow_smp, gl_FragCoord, _941, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _238, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _941, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1627 = fa_light_sample(param, param_1, _238, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _2583 = _1627.color;\n    float _2585 = _1627.shadow;\n    if ((_1627.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1627.direction;\n        float _1641 = fa_shadow_factor(param_2, param_3, _238, fa_shadow_smp, gl_FragCoord, _941, fa_shadow_tex, fa_world_pos);\n        _2585 = _1641;\n        _2583 *= _1641;\n    }\n    return LightSample{ _1627.direction, _2583, _1627.attenuation, _2585, _1627._distance, _1627.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _941)\n{\n    if (_941.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1482 = int(_941.fa_shadow_cfg.x + 0.5);\n    float _1492 = dot(world - _941.fa_shadow_eye.xyz, _941.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1497 = _1482 > 0;\n    bool _1506;\n    if (_1497)\n    {\n        int param = _1482 - 1;\n        _1506 = _1492 <= fa_shadow_split_at(param, _941);\n    }\n    else\n    {\n        _1506 = _1497;\n    }\n    if (_1506)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1513 = _1482 > 1;\n        bool _1520;\n        if (_1513)\n        {\n            _1520 = _1492 > _941.fa_shadow_split.x;\n        }\n        else\n        {\n            _1520 = _1513;\n        }\n        if (_1520)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1526 = _1482 > 2;\n        bool _1533;\n        if (_1526)\n        {\n            _1533 = _1492 > _941.fa_shadow_split.y;\n        }\n        else\n        {\n            _1533 = _1526;\n        }\n        if (_1533)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1539 = _1482 > 3;\n        bool _1546;\n        if (_1539)\n        {\n            _1546 = _1492 > _941.fa_shadow_split.z;\n        }\n        else\n        {\n            _1546 = _1539;\n        }\n        if (_1546)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _238 [[buffer(1)]], constant fa_shadows& _941 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2412 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2412 = -_2412;\n    }\n    float3 _2025 = fast::normalize(_238.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _238, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2412, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2025, short(gl_FrontFacing) };\n    Surface _2033 = fa_standard_surface(param_1, _238, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2451 = _2033.albedo;\n    float _2452 = _2033.alpha;\n    float3 _2453 = _2033.normal;\n    float _2454 = _2033.metallic;\n    float _2455 = _2033.roughness;\n    float _2456 = _2033.occlusion;\n    float3 _2457 = _2033.emission;\n    float _2458 = _2033.clearcoat;\n    float _2459 = _2033.clearcoat_roughness;\n    float3 _2460 = _2033.sheen_color;\n    float _2461 = _2033.sheen_roughness;\n    float _2462 = _2033.anisotropy;\n    float _2463 = _2033.anisotropy_rotation;\n    float _2464 = _2033.specular;\n    float _2465 = _2033.ior;\n    float3 _2466 = _2033.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2412, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2025, short(gl_FrontFacing) };\n    Surface param_3 = _2033;\n    surface(param_2, param_3);\n    _2451 = param_3.albedo;\n    _2452 = param_3.alpha;\n    _2453 = param_3.normal;\n    _2454 = param_3.metallic;\n    _2455 = param_3.roughness;\n    _2456 = param_3.occlusion;\n    _2457 = param_3.emission;\n    _2458 = param_3.clearcoat;\n    _2459 = param_3.clearcoat_roughness;\n    _2460 = param_3.sheen_color;\n    _2461 = param_3.sheen_roughness;\n    _2462 = param_3.anisotropy;\n    _2463 = param_3.anisotropy_rotation;\n    _2464 = param_3.specular;\n    _2465 = param_3.ior;\n    _2466 = param_3.specular_color;\n    float3 result;\n    if (_238.fa_emissive.w > 0.5)\n    {\n        result = _2451;\n    }\n    else\n    {\n        float3 _2054 = _2453;\n        float3 _2055 = fast::normalize(_2054);\n        _2453 = _2055;\n        float3 param_4 = _2055;\n        SurfaceInput param_5 = SurfaceInput{ in.fa_world_pos, _2412, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2025, short(gl_FrontFacing) };\n        Surface param_6 = Surface{ _2451, _2452, _2453, _2454, _2455, _2456, _2457, _2458, _2459, _2460, _2461, _2462, _2463, _2464, _2465, _2466 };\n        float3 param_7 = fa_ambient_light(param_4, _238, fa_env_smp, fa_irr_tex);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _2074 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2074; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8, _238, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            float3 param_10 = in.fa_world_pos;\n            float3 param_11 = _2412;\n            LightSample _2096 = fa_light_shadowed(param_9, param_10, param_11, _238, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _941, fa_shadow_tex, in.fa_world_pos);\n            SurfaceInput param_12 = SurfaceInput{ in.fa_world_pos, _2412, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2025, short(gl_FrontFacing) };\n            Surface param_13 = Surface{ _2451, _2452, _2453, _2454, _2455, _2456, _2457, _2458, _2459, _2460, _2461, _2462, _2463, _2464, _2465, _2466 };\n            LightSample param_14 = _2096;\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _2111 = result;\n    float3 _2112 = _2111 + _2457;\n    result = _2112;\n    float3 param_15 = _2112;\n    float3 param_16 = in.fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16, _941);\n    bool _2121 = _238.fa_fog.w > 0.0;\n    bool _2128;\n    if (!_2121)\n    {\n        _2128 = _238.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2128 = _2121;\n    }\n    if (_2128)\n    {\n        float3 _2137 = in.fa_world_pos - _238.fa_camera_pos.xyz;\n        float _2143 = dot(_2137, _238.fa_fog_c.xyz);\n        bool _2147 = _238.fa_fog_c.w > 0.5;\n        float _2148;\n        if (_2147)\n        {\n            _2148 = _2143;\n        }\n        else\n        {\n            _2148 = length(_2137);\n        }\n        float _2160 = _2148 - _238.fa_fog_b.x;\n        if (_2160 > 0.0)\n        {\n            float _2169 = _238.fa_fog.w * _2160;\n            float tau = _2169 * _2169;\n            if (_238.fa_fog_b.y > 0.0)\n            {\n                float _2185;\n                if (_2147)\n                {\n                    _2185 = in.fa_world_pos.y - (_238.fa_fog_c.y * _2143);\n                }\n                else\n                {\n                    _2185 = _238.fa_camera_pos.y;\n                }\n                float _2206 = mix(_2185, in.fa_world_pos.y, fast::clamp(_238.fa_fog_b.x / _2148, 0.0, 1.0));\n                float _2210 = in.fa_world_pos.y - _2206;\n                float _2215 = _2206 - _238.fa_fog_b.z;\n                float _2220 = in.fa_world_pos.y - _238.fa_fog_b.z;\n                bool _2223 = _2215 <= 0.0;\n                bool _2224 = !_2223;\n                bool _2230;\n                if (_2224)\n                {\n                    _2230 = _238.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2230 = _2223;\n                }\n                float _2231;\n                if (_2230)\n                {\n                    _2231 = _238.fa_fog_b.y;\n                }\n                else\n                {\n                    _2231 = _238.fa_fog_b.y * exp(-fast::min(_238.fa_fog_b.w * _2215, 80.0));\n                }\n                bool _2258;\n                if (_2224)\n                {\n                    _2258 = _238.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2258 = _2223;\n                }\n                float _2259;\n                if (_2258)\n                {\n                    _2259 = _238.fa_fog_b.y * _2215;\n                }\n                else\n                {\n                    _2259 = (_238.fa_fog_b.y * (1.0 - exp(-fast::min(_238.fa_fog_b.w * _2215, 80.0)))) / _238.fa_fog_b.w;\n                }\n                bool _2284 = _2220 <= 0.0;\n                bool _2291;\n                if (!_2284)\n                {\n                    _2291 = _238.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2291 = _2284;\n                }\n                float _2292;\n                if (_2291)\n                {\n                    _2292 = _238.fa_fog_b.y * _2220;\n                }\n                else\n                {\n                    _2292 = (_238.fa_fog_b.y * (1.0 - exp(-fast::min(_238.fa_fog_b.w * _2220, 80.0)))) / _238.fa_fog_b.w;\n                }\n                float _2319;\n                if (abs(_2210) < 0.001000000047497451305389404296875)\n                {\n                    _2319 = _2231;\n                }\n                else\n                {\n                    _2319 = (_2292 - _2259) / _2210;\n                }\n                tau += (_2160 * fast::max(_2319, 0.0));\n            }\n            result = mix(result, _238.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2452);\n    return out;\n}\n\n",
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
            "inst_name": "_238",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_941",
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
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_386, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _238, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _710 = _238.fa_cl_info.x < 0.0;\n    bool _717;\n    if (!_710)\n    {\n        _717 = _238.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _717 = _710;\n    }\n    bool _725;\n    if (!_717)\n    {\n        _725 = _238.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _725 = _717;\n    }\n    bool _732;\n    if (!_725)\n    {\n        _732 = _238.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _732 = _725;\n    }\n    bool _739;\n    if (!_732)\n    {\n        _739 = _238.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _739 = _732;\n    }\n    if (_739)\n    {\n        return int2(0);\n    }\n    float4 _749 = float4(world_pos, 1.0);\n    float _756 = dot(_238.fa_cl_vpw, _749);\n    if (!(_756 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _778 = float2(dot(_238.fa_cl_vpx, _749), dot(_238.fa_cl_vpy, _749)) / float2(_756);\n    int _782 = int(_238.fa_cl_grid.x);\n    int _786 = int(_238.fa_cl_grid.y);\n    int param = (int(_238.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_238.fa_cl_fwd.xyz, world_pos) + _238.fa_cl_fwd.w, _238.fa_cl_grid.w) / _238.fa_cl_grid.w) * _238.fa_cl_grid.z)), 0, int(_238.fa_cl_info.y) - 1) * _786) + clamp(int(floor(((_778.y * 0.5) + 0.5) * _238.fa_cl_grid.y)), 0, _786 - 1)) * _782)) + clamp(int(floor(((_778.x * 0.5) + 0.5) * _238.fa_cl_grid.x)), 0, _782 - 1);\n    float4 _857 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_857.x), int(_857.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _238, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_238.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1599 = fa_cluster_lookup(param, _238, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _1599.x;\n    fa_cl_local = _1599.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1707 = fa_linear_to_srgb(param);\n        c = _1707;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1715 = fa_srgb_to_linear(param_1);\n            c = _1715;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _170;\n    if (bool(i.front_facing))\n    {\n        _170 = i.world_normal;\n    }\n    else\n    {\n        _170 = -i.world_normal;\n    }\n    float3 _194 = fast::normalize(i.world_tangent.xyz - (_170 * dot(_170, i.world_tangent.xyz)));\n    float3 _222 = fast::normalize(((_194 * m.x) + ((cross(_170, _194) * i.world_tangent.w) * m.y)) + (_170 * m.z));\n    float3 _225;\n    if (bool(i.front_facing))\n    {\n        _225 = _222;\n    }\n    else\n    {\n        _225 = -_222;\n    }\n    return _225;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _238, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _238.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1746 = fa_tex_fix(param_2, param_3);\n    float4 _2666 = base_t;\n    _2666.x = _1746.x;\n    _2666.y = _1746.y;\n    _2666.z = _1746.z;\n    base_t = _2666;\n    float4 _1760 = (_2666 * _238.fa_base_color) * i.vertex_color;\n    float3 _2603 = i.world_normal;\n    if (_238.fa_maps.z > 0.5)\n    {\n        float param_4 = _238.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1792 = fa_tex_fix(param_6, param_7);\n        float3 _1796 = (_1792 * 2.0) - float3(1.0);\n        float2 _1801 = _1796.xy * _238.fa_maps.x;\n        float3 _2674 = _1796;\n        _2674.x = _1801.x;\n        _2674.y = _1801.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2674;\n        _2603 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _238.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1829 = fa_tex_fix(param_12, param_13);\n    float4 _2677 = mrt;\n    _2677.x = _1829.x;\n    _2677.y = _1829.y;\n    _2677.z = _1829.z;\n    mrt = _2677;\n    float4 _1858 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _238.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1858.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1870 = fa_tex_fix(param_16, param_17);\n    float param_18 = _238.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1900 = fa_tex_fix(param_20, param_21);\n    float _2608 = _238.fa_layers_a.x;\n    float _2609 = _238.fa_layers_a.y;\n    float _2612 = _238.fa_layers_a.z;\n    float _2611 = _238.fa_layers_b.w;\n    float _2614 = _238.fa_layers_c.x;\n    if (_238.fa_layers_c.z > 0.5)\n    {\n        if (mod(_238.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2608 *= _1870.y;\n            _2609 *= _1870.z;\n            _2611 *= _1858.w;\n        }\n        if (_238.fa_layers_c.z > 1.5)\n        {\n            _2612 *= mrt.x;\n            _2614 *= mrt.w;\n        }\n    }\n    return Surface{ _1760.xyz, _1760.w, _2603, fast::clamp(_238.fa_pbr.x * _1829.z, 0.0, 1.0), fast::clamp(_238.fa_pbr.y * _1829.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_238.fa_maps.y * (_1870.x - 1.0)), _238.fa_emissive.xyz + (_238.fa_model_emissive.xyz * _1900), _2608, _2609, _238.fa_layers_b.xyz, _2611, _2612, _238.fa_layers_a.w, _2614, _238.fa_layers_c.y, _238.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _238, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_238.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _238.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _238, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_238.fa_cl_info.x) + int(_238.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _238, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _238, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _238)\n{\n    return li * ((_238.fa_counts.y > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _319 = dot(d, right);\n    float _323 = dot(d, up);\n    float _334;\n    if (((_319 * _319) + (_323 * _323)) > 1.0000000133514319600180897396058e-10)\n    {\n        _334 = precise::atan2(_323, _319) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _334 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_334 - floor(_334)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_mesh_fs_params& _238, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _367 = fa_light_base(param, _238);\n    bool _371 = _238.fa_counts.y > 4.5;\n    int param_1 = _367;\n    float4 _375 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _367 + 1;\n    float4 _380 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _383 = _380.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _395 = _371 && (_383 > 2.5);\n    fa_light_is_area = _395;\n    bool _398 = _383 < 0.5;\n    float3 l;\n    if (_398)\n    {\n        l = fast::normalize(_375.xyz);\n        if (_371)\n        {\n            int param_3 = _367 + 6;\n            float4 _412 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_412.z > 0.5)\n            {\n                int param_4 = _367 + 4;\n                float4 _422 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _367 + 5;\n                float4 _428 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _412.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _422.xyz) * _422.w, (-dot(world_pos, _428.xyz)) * _428.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _460 = _375.xyz - world_pos;\n        float _462 = length(_460);\n        dist = _462;\n        l = _460 / float3(fast::max(_462, 9.9999997473787516355514526367188e-05));\n        float reach = _462;\n        if (_395)\n        {\n            int param_8 = _367 + 7;\n            reach = fast::max(dist - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n        }\n        float _494 = reach / fast::max(_375.w, 0.001000000047497451305389404296875);\n        float _500 = fast::clamp(1.0 - (_494 * _494), 0.0, 1.0);\n        atten = _500 * _500;\n        bool _508 = _383 < 2.5;\n        if ((_383 > 1.5) && _508)\n        {\n            int param_9 = _367 + 2;\n            float4 _516 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            float _526 = _516.w;\n            int param_10 = _367 + 3;\n            float4 _532 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            float _533 = _532.x;\n            float cos_inner = _533;\n            if (_533 > 1.5)\n            {\n                cos_inner = mix(_526, 1.0, 0.25);\n            }\n            atten *= smoothstep(_526, cos_inner, dot(-l, fast::normalize(_516.xyz)));\n        }\n        if (_371 && _508)\n        {\n            int param_11 = _367 + 6;\n            float4 _557 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            int param_12 = _367 + 7;\n            float4 _562 = fa_light_texel(param_12, fa_light_tex, fa_shadow_smp);\n            bool _565 = _557.z > 0.5;\n            bool _572;\n            if (!_565)\n            {\n                _572 = _562.z > 0.5;\n            }\n            else\n            {\n                _572 = _565;\n            }\n            if (_572)\n            {\n                int param_13 = _367 + 2;\n                float4 _579 = fa_light_texel(param_13, fa_light_tex, fa_shadow_smp);\n                float3 _583 = fast::normalize(_579.xyz);\n                int param_14 = _367 + 4;\n                float4 _588 = fa_light_texel(param_14, fa_light_tex, fa_shadow_smp);\n                int param_15 = _367 + 5;\n                float4 _593 = fa_light_texel(param_15, fa_light_tex, fa_shadow_smp);\n                if (_565)\n                {\n                    float3 _601 = -_460;\n                    float _608 = _579.w;\n                    float _624 = 0.5 / fast::max(dot(_601, _583) * (sqrt(fast::max(1.0 - (_608 * _608), 0.0)) / fast::max(_608, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    float2 param_16 = _557.xy;\n                    float2 param_17 = float2(0.5 + (dot(_601, _588.xyz) * _624), 0.5 - (dot(_601, _593.xyz) * _624));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17, fa_light_atlas, fa_env_smp);\n                }\n                if (_562.z > 0.5)\n                {\n                    float2 param_18 = _562.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _583;\n                    float3 param_21 = _588.xyz;\n                    float3 param_22 = _593.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22, fa_light_atlas, fa_env_smp);\n                }\n            }\n        }\n    }\n    float3 _2570 = _380.xyz * atten;\n    if (_371)\n    {\n        _2570 *= fa_light_tint;\n    }\n    int _692;\n    if (_398)\n    {\n        _692 = 0;\n    }\n    else\n    {\n        _692 = ((_383 > 1.5) && (_383 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _2570, atten, 1.0, dist, _692 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _941)\n{\n    float _931;\n    if (i == 0)\n    {\n        _931 = _941.fa_shadow_split.x;\n    }\n    else\n    {\n        float _947;\n        if (i == 1)\n        {\n            _947 = _941.fa_shadow_split.y;\n        }\n        else\n        {\n            float _955;\n            if (i == 2)\n            {\n                _955 = _941.fa_shadow_split.z;\n            }\n            else\n            {\n                _955 = _941.fa_shadow_split.w;\n            }\n            _947 = _955;\n        }\n        _931 = _947;\n    }\n    return _931;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _919 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_919), sin(_919)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _941, texture2d<float> fa_shadow_tex)\n{\n    float _993 = fast::max(_941.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _998 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1004 = sqrt(1.0 - (_998 * _998));\n    float _1012 = fast::min(_1004 / fast::max(_998, 0.20000000298023223876953125), 4.0);\n    float _1017;\n    if (_941.fa_shadow_bias.y > 0.0)\n    {\n        _1017 = _941.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1017 = 1.5 * _941.fa_shadow_info[ci].x;\n    }\n    float4 _1042 = _941.fa_shadow_mat[ci] * float4(world + (n * (_1017 * _1004)), 1.0);\n    float _1049 = _1042.x;\n    bool _1052 = _1049 < _941.fa_shadow_rect[ci].x;\n    bool _1061;\n    if (!_1052)\n    {\n        _1061 = _1049 > _941.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1061 = _1052;\n    }\n    bool _1070;\n    if (!_1061)\n    {\n        _1070 = _1042.y < _941.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1070 = _1061;\n    }\n    bool _1079;\n    if (!_1070)\n    {\n        _1079 = _1042.y > _941.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1079 = _1070;\n    }\n    bool _1086;\n    if (!_1079)\n    {\n        _1086 = _1042.z > 1.0;\n    }\n    else\n    {\n        _1086 = _1079;\n    }\n    if (_1086)\n    {\n        return -1.0;\n    }\n    float _1094;\n    if (_941.fa_shadow_bias.x > 0.0)\n    {\n        _1094 = _941.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1094 = 1.5 * _941.fa_shadow_info[ci].x;\n    }\n    float _1113 = _1042.z - ((_1094 * (1.0 + (0.5 * _1012))) / _993);\n    float _1122 = ((_941.fa_shadow_info[ci].x * fast::min(_1012, 3.0)) * 0.5) / _993;\n    int _1131 = int(_941.fa_shadow_cfg.z + 0.5);\n    if (_1131 == 1)\n    {\n        float2 param = _1042.xy;\n        float4 param_1 = _941.fa_shadow_rect[ci];\n        float _1142 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1113 <= _1142);\n    }\n    float _1149 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1152 = _1131 == 2;\n    if (_1152)\n    {\n        float _1166 = fast::clamp(((_941.fa_shadow_cfg.w * _993) * 0.25) / _941.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1149;\n            float2 _1185 = fa_shadow_vogel(param_2, param_3, param_4) * _1166;\n            float2 param_5 = _1042.xy + (_1185 * _941.fa_shadow_bias.zw);\n            float4 param_6 = _941.fa_shadow_rect[ci];\n            float _1196 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1196 < (_1113 - (length(_1185) * _1122)))\n            {\n                sum += _1196;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1113 - (sum / cnt), 0.0) * _993) * _941.fa_shadow_cfg.w) / _941.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1240 = _1152 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1240; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1240;\n        float param_9 = _1149;\n        float2 _1259 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1042.xy + (_1259 * _941.fa_shadow_bias.zw);\n        float4 param_11 = _941.fa_shadow_rect[ci];\n        float _1270 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1113 - (length(_1259) * _1122)) <= _1270);\n    }\n    return lit / float(_1240);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _238, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _941, texture2d<float> fa_shadow_tex)\n{\n    if (_238.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1300 = int(_941.fa_shadow_cfg.x + 0.5);\n    if (_1300 < 1)\n    {\n        return 1.0;\n    }\n    float _1315 = dot(world - _941.fa_shadow_eye.xyz, _941.fa_shadow_fwd.xyz);\n    int param = _1300 - 1;\n    if (_1315 > fa_shadow_split_at(param, _941))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1327 = _1300 > 1;\n    bool _1334;\n    if (_1327)\n    {\n        _1334 = _1315 > _941.fa_shadow_split.x;\n    }\n    else\n    {\n        _1334 = _1327;\n    }\n    if (_1334)\n    {\n        ci = 1;\n    }\n    bool _1338 = _1300 > 2;\n    bool _1345;\n    if (_1338)\n    {\n        _1345 = _1315 > _941.fa_shadow_split.y;\n    }\n    else\n    {\n        _1345 = _1338;\n    }\n    if (_1345)\n    {\n        ci = 2;\n    }\n    bool _1349 = _1300 > 3;\n    bool _1356;\n    if (_1349)\n    {\n        _1356 = _1315 > _941.fa_shadow_split.z;\n    }\n    else\n    {\n        _1356 = _1349;\n    }\n    if (_1356)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1300)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1382 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _941, fa_shadow_tex);\n        s = _1382;\n        if (_1382 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_941.fa_shadow_cfg.y > 0.0)\n    {\n        float _1407;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1407 = fa_shadow_split_at(param_5, _941);\n        }\n        else\n        {\n            _1407 = _941.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1426 = _941.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _941) - _1407, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1437 = fast::clamp((_1315 - (fa_shadow_split_at(param_7, _941) - _1426)) / _1426, 0.0, 1.0);\n        if (_1437 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1300)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1458 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _941, fa_shadow_tex);\n                s2 = _1458;\n                if (_1458 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1437);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _238, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _941, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _238, fa_shadow_smp, gl_FragCoord, _941, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _238, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _941, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1627 = fa_light_sample(param, param_1, _238, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _2583 = _1627.color;\n    float _2585 = _1627.shadow;\n    if ((_1627.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1627.direction;\n        float _1641 = fa_shadow_factor(param_2, param_3, _238, fa_shadow_smp, gl_FragCoord, _941, fa_shadow_tex, fa_world_pos);\n        _2585 = _1641;\n        _2583 *= _1641;\n    }\n    return LightSample{ _1627.direction, _2583, _1627.attenuation, _2585, _1627._distance, _1627.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _941)\n{\n    if (_941.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1482 = int(_941.fa_shadow_cfg.x + 0.5);\n    float _1492 = dot(world - _941.fa_shadow_eye.xyz, _941.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1497 = _1482 > 0;\n    bool _1506;\n    if (_1497)\n    {\n        int param = _1482 - 1;\n        _1506 = _1492 <= fa_shadow_split_at(param, _941);\n    }\n    else\n    {\n        _1506 = _1497;\n    }\n    if (_1506)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1513 = _1482 > 1;\n        bool _1520;\n        if (_1513)\n        {\n            _1520 = _1492 > _941.fa_shadow_split.x;\n        }\n        else\n        {\n            _1520 = _1513;\n        }\n        if (_1520)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1526 = _1482 > 2;\n        bool _1533;\n        if (_1526)\n        {\n            _1533 = _1492 > _941.fa_shadow_split.y;\n        }\n        else\n        {\n            _1533 = _1526;\n        }\n        if (_1533)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1539 = _1482 > 3;\n        bool _1546;\n        if (_1539)\n        {\n            _1546 = _1492 > _941.fa_shadow_split.z;\n        }\n        else\n        {\n            _1546 = _1539;\n        }\n        if (_1546)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _238 [[buffer(1)]], constant fa_shadows& _941 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2412 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2412 = -_2412;\n    }\n    float3 _2025 = fast::normalize(_238.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _238, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2412, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2025, short(gl_FrontFacing) };\n    Surface _2033 = fa_standard_surface(param_1, _238, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2451 = _2033.albedo;\n    float _2452 = _2033.alpha;\n    float3 _2453 = _2033.normal;\n    float _2454 = _2033.metallic;\n    float _2455 = _2033.roughness;\n    float _2456 = _2033.occlusion;\n    float3 _2457 = _2033.emission;\n    float _2458 = _2033.clearcoat;\n    float _2459 = _2033.clearcoat_roughness;\n    float3 _2460 = _2033.sheen_color;\n    float _2461 = _2033.sheen_roughness;\n    float _2462 = _2033.anisotropy;\n    float _2463 = _2033.anisotropy_rotation;\n    float _2464 = _2033.specular;\n    float _2465 = _2033.ior;\n    float3 _2466 = _2033.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2412, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2025, short(gl_FrontFacing) };\n    Surface param_3 = _2033;\n    surface(param_2, param_3);\n    _2451 = param_3.albedo;\n    _2452 = param_3.alpha;\n    _2453 = param_3.normal;\n    _2454 = param_3.metallic;\n    _2455 = param_3.roughness;\n    _2456 = param_3.occlusion;\n    _2457 = param_3.emission;\n    _2458 = param_3.clearcoat;\n    _2459 = param_3.clearcoat_roughness;\n    _2460 = param_3.sheen_color;\n    _2461 = param_3.sheen_roughness;\n    _2462 = param_3.anisotropy;\n    _2463 = param_3.anisotropy_rotation;\n    _2464 = param_3.specular;\n    _2465 = param_3.ior;\n    _2466 = param_3.specular_color;\n    float3 result;\n    if (_238.fa_emissive.w > 0.5)\n    {\n        result = _2451;\n    }\n    else\n    {\n        float3 _2054 = _2453;\n        float3 _2055 = fast::normalize(_2054);\n        _2453 = _2055;\n        float3 param_4 = _2055;\n        SurfaceInput param_5 = SurfaceInput{ in.fa_world_pos, _2412, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2025, short(gl_FrontFacing) };\n        Surface param_6 = Surface{ _2451, _2452, _2453, _2454, _2455, _2456, _2457, _2458, _2459, _2460, _2461, _2462, _2463, _2464, _2465, _2466 };\n        float3 param_7 = fa_ambient_light(param_4, _238, fa_env_smp, fa_irr_tex);\n        float3 lit = ambient(param_5, param_6, param_7);\n        int _2074 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2074; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8, _238, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            float3 param_10 = in.fa_world_pos;\n            float3 param_11 = _2412;\n            LightSample _2096 = fa_light_shadowed(param_9, param_10, param_11, _238, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _941, fa_shadow_tex, in.fa_world_pos);\n            SurfaceInput param_12 = SurfaceInput{ in.fa_world_pos, _2412, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2025, short(gl_FrontFacing) };\n            Surface param_13 = Surface{ _2451, _2452, _2453, _2454, _2455, _2456, _2457, _2458, _2459, _2460, _2461, _2462, _2463, _2464, _2465, _2466 };\n            LightSample param_14 = _2096;\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    float3 _2111 = result;\n    float3 _2112 = _2111 + _2457;\n    result = _2112;\n    float3 param_15 = _2112;\n    float3 param_16 = in.fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16, _941);\n    bool _2121 = _238.fa_fog.w > 0.0;\n    bool _2128;\n    if (!_2121)\n    {\n        _2128 = _238.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2128 = _2121;\n    }\n    if (_2128)\n    {\n        float3 _2137 = in.fa_world_pos - _238.fa_camera_pos.xyz;\n        float _2143 = dot(_2137, _238.fa_fog_c.xyz);\n        bool _2147 = _238.fa_fog_c.w > 0.5;\n        float _2148;\n        if (_2147)\n        {\n            _2148 = _2143;\n        }\n        else\n        {\n            _2148 = length(_2137);\n        }\n        float _2160 = _2148 - _238.fa_fog_b.x;\n        if (_2160 > 0.0)\n        {\n            float _2169 = _238.fa_fog.w * _2160;\n            float tau = _2169 * _2169;\n            if (_238.fa_fog_b.y > 0.0)\n            {\n                float _2185;\n                if (_2147)\n                {\n                    _2185 = in.fa_world_pos.y - (_238.fa_fog_c.y * _2143);\n                }\n                else\n                {\n                    _2185 = _238.fa_camera_pos.y;\n                }\n                float _2206 = mix(_2185, in.fa_world_pos.y, fast::clamp(_238.fa_fog_b.x / _2148, 0.0, 1.0));\n                float _2210 = in.fa_world_pos.y - _2206;\n                float _2215 = _2206 - _238.fa_fog_b.z;\n                float _2220 = in.fa_world_pos.y - _238.fa_fog_b.z;\n                bool _2223 = _2215 <= 0.0;\n                bool _2224 = !_2223;\n                bool _2230;\n                if (_2224)\n                {\n                    _2230 = _238.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2230 = _2223;\n                }\n                float _2231;\n                if (_2230)\n                {\n                    _2231 = _238.fa_fog_b.y;\n                }\n                else\n                {\n                    _2231 = _238.fa_fog_b.y * exp(-fast::min(_238.fa_fog_b.w * _2215, 80.0));\n                }\n                bool _2258;\n                if (_2224)\n                {\n                    _2258 = _238.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2258 = _2223;\n                }\n                float _2259;\n                if (_2258)\n                {\n                    _2259 = _238.fa_fog_b.y * _2215;\n                }\n                else\n                {\n                    _2259 = (_238.fa_fog_b.y * (1.0 - exp(-fast::min(_238.fa_fog_b.w * _2215, 80.0)))) / _238.fa_fog_b.w;\n                }\n                bool _2284 = _2220 <= 0.0;\n                bool _2291;\n                if (!_2284)\n                {\n                    _2291 = _238.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2291 = _2284;\n                }\n                float _2292;\n                if (_2291)\n                {\n                    _2292 = _238.fa_fog_b.y * _2220;\n                }\n                else\n                {\n                    _2292 = (_238.fa_fog_b.y * (1.0 - exp(-fast::min(_238.fa_fog_b.w * _2220, 80.0)))) / _238.fa_fog_b.w;\n                }\n                float _2319;\n                if (abs(_2210) < 0.001000000047497451305389404296875)\n                {\n                    _2319 = _2231;\n                }\n                else\n                {\n                    _2319 = (_2292 - _2259) / _2210;\n                }\n                tau += (_2160 * fast::max(_2319, 0.0));\n            }\n            result = mix(result, _238.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2452);\n    return out;\n}\n\n",
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
            "inst_name": "_238",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_941",
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
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213.fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213.fa_layers_a.x;\n    float _753 = _213.fa_layers_a.y;\n    float _756 = _213.fa_layers_a.z;\n    float _755 = _213.fa_layers_b.w;\n    float _758 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _747, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _752, _753, _213.fa_layers_b.xyz, _755, _756, _213.fa_layers_a.w, _758, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _658 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _658, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _658, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213.fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213.fa_layers_a.x;\n    float _753 = _213.fa_layers_a.y;\n    float _756 = _213.fa_layers_a.z;\n    float _755 = _213.fa_layers_b.w;\n    float _758 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _747, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _752, _753, _213.fa_layers_b.xyz, _755, _756, _213.fa_layers_a.w, _758, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _658 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _658, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _658, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
