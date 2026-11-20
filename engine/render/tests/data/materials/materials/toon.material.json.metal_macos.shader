{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "738bdbaa5d236ca82c68b48e7af94b35c54ba5d6311eabf2bcbbc814ba3d221c",
  "slang": "metal_macos",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_268, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _232, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _704 = _232.fa_cl_info.x < 0.0;\n    bool _711;\n    if (!_704)\n    {\n        _711 = _232.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _711 = _704;\n    }\n    bool _719;\n    if (!_711)\n    {\n        _719 = _232.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _719 = _711;\n    }\n    bool _726;\n    if (!_719)\n    {\n        _726 = _232.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _726 = _719;\n    }\n    bool _733;\n    if (!_726)\n    {\n        _733 = _232.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _733 = _726;\n    }\n    if (_733)\n    {\n        return int2(0);\n    }\n    float4 _743 = float4(world_pos, 1.0);\n    float _750 = dot(_232.fa_cl_vpw, _743);\n    if (!(_750 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _772 = float2(dot(_232.fa_cl_vpx, _743), dot(_232.fa_cl_vpy, _743)) / float2(_750);\n    int _776 = int(_232.fa_cl_grid.x);\n    int _780 = int(_232.fa_cl_grid.y);\n    int param = (int(_232.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_232.fa_cl_fwd.xyz, world_pos) + _232.fa_cl_fwd.w, _232.fa_cl_grid.w) / _232.fa_cl_grid.w) * _232.fa_cl_grid.z)), 0, int(_232.fa_cl_info.y) - 1) * _780) + clamp(int(floor(((_772.y * 0.5) + 0.5) * _232.fa_cl_grid.y)), 0, _780 - 1)) * _776)) + clamp(int(floor(((_772.x * 0.5) + 0.5) * _232.fa_cl_grid.x)), 0, _776 - 1);\n    float4 _851 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_851.x), int(_851.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _232, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_232.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1593 = fa_cluster_lookup(param, _232, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _1593.x;\n    fa_cl_local = _1593.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1722 = fa_linear_to_srgb(param);\n        c = _1722;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1730 = fa_srgb_to_linear(param_1);\n            c = _1730;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _164;\n    if (bool(i.front_facing))\n    {\n        _164 = i.world_normal;\n    }\n    else\n    {\n        _164 = -i.world_normal;\n    }\n    float3 _188 = fast::normalize(i.world_tangent.xyz - (_164 * dot(_164, i.world_tangent.xyz)));\n    float3 _216 = fast::normalize(((_188 * m.x) + ((cross(_164, _188) * i.world_tangent.w) * m.y)) + (_164 * m.z));\n    float3 _219;\n    if (bool(i.front_facing))\n    {\n        _219 = _216;\n    }\n    else\n    {\n        _219 = -_216;\n    }\n    return _219;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _232, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _232.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1761 = fa_tex_fix(param_2, param_3);\n    float4 _2656 = base_t;\n    _2656.x = _1761.x;\n    _2656.y = _1761.y;\n    _2656.z = _1761.z;\n    base_t = _2656;\n    float4 _1775 = (_2656 * _232.fa_base_color) * i.vertex_color;\n    float3 _2593 = i.world_normal;\n    if (_232.fa_maps.z > 0.5)\n    {\n        float param_4 = _232.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1807 = fa_tex_fix(param_6, param_7);\n        float3 _1811 = (_1807 * 2.0) - float3(1.0);\n        float2 _1816 = _1811.xy * _232.fa_maps.x;\n        float3 _2664 = _1811;\n        _2664.x = _1816.x;\n        _2664.y = _1816.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2664;\n        _2593 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _232.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1844 = fa_tex_fix(param_12, param_13);\n    float4 _2667 = mrt;\n    _2667.x = _1844.x;\n    _2667.y = _1844.y;\n    _2667.z = _1844.z;\n    mrt = _2667;\n    float4 _1873 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _232.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1873.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1885 = fa_tex_fix(param_16, param_17);\n    float param_18 = _232.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1915 = fa_tex_fix(param_20, param_21);\n    float _2598 = _232.fa_layers_a.x;\n    float _2599 = _232.fa_layers_a.y;\n    float _2602 = _232.fa_layers_a.z;\n    float _2601 = _232.fa_layers_b.w;\n    float _2604 = _232.fa_layers_c.x;\n    if (_232.fa_layers_c.z > 0.5)\n    {\n        if (mod(_232.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2598 *= _1885.y;\n            _2599 *= _1885.z;\n            _2601 *= _1873.w;\n        }\n        if (_232.fa_layers_c.z > 1.5)\n        {\n            _2602 *= mrt.x;\n            _2604 *= mrt.w;\n        }\n    }\n    return Surface{ _1775.xyz, _1775.w, _2593, fast::clamp(_232.fa_pbr.x * _1844.z, 0.0, 1.0), fast::clamp(_232.fa_pbr.y * _1844.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_232.fa_maps.y * (_1885.x - 1.0)), _232.fa_emissive.xyz + (_232.fa_model_emissive.xyz * _1915), _2598, _2599, _232.fa_layers_b.xyz, _2601, _2602, _232.fa_layers_a.w, _2604, _232.fa_layers_c.y, _232.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _232, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_232.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _232.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _232, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_232.fa_cl_info.x) + int(_232.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _232, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _232, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _232)\n{\n    return li * ((_232.fa_counts.y > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _313 = dot(d, right);\n    float _317 = dot(d, up);\n    float _328;\n    if (((_313 * _313) + (_317 * _317)) > 1.0000000133514319600180897396058e-10)\n    {\n        _328 = precise::atan2(_317, _313) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _328 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_328 - floor(_328)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_mesh_fs_params& _232, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _361 = fa_light_base(param, _232);\n    bool _365 = _232.fa_counts.y > 4.5;\n    int param_1 = _361;\n    float4 _369 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _361 + 1;\n    float4 _374 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _377 = _374.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _389 = _365 && (_377 > 2.5);\n    fa_light_is_area = _389;\n    bool _392 = _377 < 0.5;\n    float3 l;\n    if (_392)\n    {\n        l = fast::normalize(_369.xyz);\n        if (_365)\n        {\n            int param_3 = _361 + 6;\n            float4 _406 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_406.z > 0.5)\n            {\n                int param_4 = _361 + 4;\n                float4 _416 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _361 + 5;\n                float4 _422 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _406.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _416.xyz) * _416.w, (-dot(world_pos, _422.xyz)) * _422.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _454 = _369.xyz - world_pos;\n        float _456 = length(_454);\n        dist = _456;\n        l = _454 / float3(fast::max(_456, 9.9999997473787516355514526367188e-05));\n        float reach = _456;\n        if (_389)\n        {\n            int param_8 = _361 + 7;\n            reach = fast::max(dist - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n        }\n        float _488 = reach / fast::max(_369.w, 0.001000000047497451305389404296875);\n        float _494 = fast::clamp(1.0 - (_488 * _488), 0.0, 1.0);\n        atten = _494 * _494;\n        bool _502 = _377 < 2.5;\n        if ((_377 > 1.5) && _502)\n        {\n            int param_9 = _361 + 2;\n            float4 _510 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            float _520 = _510.w;\n            int param_10 = _361 + 3;\n            float4 _526 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            float _527 = _526.x;\n            float cos_inner = _527;\n            if (_527 > 1.5)\n            {\n                cos_inner = mix(_520, 1.0, 0.25);\n            }\n            atten *= smoothstep(_520, cos_inner, dot(-l, fast::normalize(_510.xyz)));\n        }\n        if (_365 && _502)\n        {\n            int param_11 = _361 + 6;\n            float4 _551 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            int param_12 = _361 + 7;\n            float4 _556 = fa_light_texel(param_12, fa_light_tex, fa_shadow_smp);\n            bool _559 = _551.z > 0.5;\n            bool _566;\n            if (!_559)\n            {\n                _566 = _556.z > 0.5;\n            }\n            else\n            {\n                _566 = _559;\n            }\n            if (_566)\n            {\n                int param_13 = _361 + 2;\n                float4 _573 = fa_light_texel(param_13, fa_light_tex, fa_shadow_smp);\n                float3 _577 = fast::normalize(_573.xyz);\n                int param_14 = _361 + 4;\n                float4 _582 = fa_light_texel(param_14, fa_light_tex, fa_shadow_smp);\n                int param_15 = _361 + 5;\n                float4 _587 = fa_light_texel(param_15, fa_light_tex, fa_shadow_smp);\n                if (_559)\n                {\n                    float3 _595 = -_454;\n                    float _602 = _573.w;\n                    float _618 = 0.5 / fast::max(dot(_595, _577) * (sqrt(fast::max(1.0 - (_602 * _602), 0.0)) / fast::max(_602, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    float2 param_16 = _551.xy;\n                    float2 param_17 = float2(0.5 + (dot(_595, _582.xyz) * _618), 0.5 - (dot(_595, _587.xyz) * _618));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17, fa_light_atlas, fa_env_smp);\n                }\n                if (_556.z > 0.5)\n                {\n                    float2 param_18 = _556.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _577;\n                    float3 param_21 = _582.xyz;\n                    float3 param_22 = _587.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22, fa_light_atlas, fa_env_smp);\n                }\n            }\n        }\n    }\n    float3 _2560 = _374.xyz * atten;\n    if (_365)\n    {\n        _2560 *= fa_light_tint;\n    }\n    int _686;\n    if (_392)\n    {\n        _686 = 0;\n    }\n    else\n    {\n        _686 = ((_377 > 1.5) && (_377 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _2560, atten, 1.0, dist, _686 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _935)\n{\n    float _925;\n    if (i == 0)\n    {\n        _925 = _935.fa_shadow_split.x;\n    }\n    else\n    {\n        float _941;\n        if (i == 1)\n        {\n            _941 = _935.fa_shadow_split.y;\n        }\n        else\n        {\n            float _949;\n            if (i == 2)\n            {\n                _949 = _935.fa_shadow_split.z;\n            }\n            else\n            {\n                _949 = _935.fa_shadow_split.w;\n            }\n            _941 = _949;\n        }\n        _925 = _941;\n    }\n    return _925;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _913 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_913), sin(_913)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _935, texture2d<float> fa_shadow_tex)\n{\n    float _987 = fast::max(_935.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _992 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _998 = sqrt(1.0 - (_992 * _992));\n    float _1006 = fast::min(_998 / fast::max(_992, 0.20000000298023223876953125), 4.0);\n    float _1011;\n    if (_935.fa_shadow_bias.y > 0.0)\n    {\n        _1011 = _935.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1011 = 1.5 * _935.fa_shadow_info[ci].x;\n    }\n    float4 _1036 = _935.fa_shadow_mat[ci] * float4(world + (n * (_1011 * _998)), 1.0);\n    float _1043 = _1036.x;\n    bool _1046 = _1043 < _935.fa_shadow_rect[ci].x;\n    bool _1055;\n    if (!_1046)\n    {\n        _1055 = _1043 > _935.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1055 = _1046;\n    }\n    bool _1064;\n    if (!_1055)\n    {\n        _1064 = _1036.y < _935.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1064 = _1055;\n    }\n    bool _1073;\n    if (!_1064)\n    {\n        _1073 = _1036.y > _935.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1073 = _1064;\n    }\n    bool _1080;\n    if (!_1073)\n    {\n        _1080 = _1036.z > 1.0;\n    }\n    else\n    {\n        _1080 = _1073;\n    }\n    if (_1080)\n    {\n        return -1.0;\n    }\n    float _1088;\n    if (_935.fa_shadow_bias.x > 0.0)\n    {\n        _1088 = _935.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1088 = 1.5 * _935.fa_shadow_info[ci].x;\n    }\n    float _1107 = _1036.z - ((_1088 * (1.0 + (0.5 * _1006))) / _987);\n    float _1116 = ((_935.fa_shadow_info[ci].x * fast::min(_1006, 3.0)) * 0.5) / _987;\n    int _1125 = int(_935.fa_shadow_cfg.z + 0.5);\n    if (_1125 == 1)\n    {\n        float2 param = _1036.xy;\n        float4 param_1 = _935.fa_shadow_rect[ci];\n        float _1136 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1107 <= _1136);\n    }\n    float _1143 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1146 = _1125 == 2;\n    if (_1146)\n    {\n        float _1160 = fast::clamp(((_935.fa_shadow_cfg.w * _987) * 0.25) / _935.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1143;\n            float2 _1179 = fa_shadow_vogel(param_2, param_3, param_4) * _1160;\n            float2 param_5 = _1036.xy + (_1179 * _935.fa_shadow_bias.zw);\n            float4 param_6 = _935.fa_shadow_rect[ci];\n            float _1190 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1190 < (_1107 - (length(_1179) * _1116)))\n            {\n                sum += _1190;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1107 - (sum / cnt), 0.0) * _987) * _935.fa_shadow_cfg.w) / _935.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1234 = _1146 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1234; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1234;\n        float param_9 = _1143;\n        float2 _1253 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1036.xy + (_1253 * _935.fa_shadow_bias.zw);\n        float4 param_11 = _935.fa_shadow_rect[ci];\n        float _1264 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1107 - (length(_1253) * _1116)) <= _1264);\n    }\n    return lit / float(_1234);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _232, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _935, texture2d<float> fa_shadow_tex)\n{\n    if (_232.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1294 = int(_935.fa_shadow_cfg.x + 0.5);\n    if (_1294 < 1)\n    {\n        return 1.0;\n    }\n    float _1309 = dot(world - _935.fa_shadow_eye.xyz, _935.fa_shadow_fwd.xyz);\n    int param = _1294 - 1;\n    if (_1309 > fa_shadow_split_at(param, _935))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1321 = _1294 > 1;\n    bool _1328;\n    if (_1321)\n    {\n        _1328 = _1309 > _935.fa_shadow_split.x;\n    }\n    else\n    {\n        _1328 = _1321;\n    }\n    if (_1328)\n    {\n        ci = 1;\n    }\n    bool _1332 = _1294 > 2;\n    bool _1339;\n    if (_1332)\n    {\n        _1339 = _1309 > _935.fa_shadow_split.y;\n    }\n    else\n    {\n        _1339 = _1332;\n    }\n    if (_1339)\n    {\n        ci = 2;\n    }\n    bool _1343 = _1294 > 3;\n    bool _1350;\n    if (_1343)\n    {\n        _1350 = _1309 > _935.fa_shadow_split.z;\n    }\n    else\n    {\n        _1350 = _1343;\n    }\n    if (_1350)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1294)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1376 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _935, fa_shadow_tex);\n        s = _1376;\n        if (_1376 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_935.fa_shadow_cfg.y > 0.0)\n    {\n        float _1401;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1401 = fa_shadow_split_at(param_5, _935);\n        }\n        else\n        {\n            _1401 = _935.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1420 = _935.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _935) - _1401, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1431 = fast::clamp((_1309 - (fa_shadow_split_at(param_7, _935) - _1420)) / _1420, 0.0, 1.0);\n        if (_1431 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1294)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1452 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _935, fa_shadow_tex);\n                s2 = _1452;\n                if (_1452 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1431);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _232, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _935, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _232, fa_shadow_smp, gl_FragCoord, _935, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _232, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _935, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1621 = fa_light_sample(param, param_1, _232, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _2573 = _1621.color;\n    float _2575 = _1621.shadow;\n    if ((_1621.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1621.direction;\n        float _1635 = fa_shadow_factor(param_2, param_3, _232, fa_shadow_smp, gl_FragCoord, _935, fa_shadow_tex, fa_world_pos);\n        _2575 = _1635;\n        _2573 *= _1635;\n    }\n    return LightSample{ _1621.direction, _2573, _1621.attenuation, _2575, _1621._distance, _1621.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l, constant fa_material& _1661)\n{\n    float _1655;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _1655 = 1.0;\n    }\n    else\n    {\n        _1655 = _1661.dark;\n    }\n    return (s.albedo * l.color) * _1655;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _935)\n{\n    if (_935.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1476 = int(_935.fa_shadow_cfg.x + 0.5);\n    float _1486 = dot(world - _935.fa_shadow_eye.xyz, _935.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1491 = _1476 > 0;\n    bool _1500;\n    if (_1491)\n    {\n        int param = _1476 - 1;\n        _1500 = _1486 <= fa_shadow_split_at(param, _935);\n    }\n    else\n    {\n        _1500 = _1491;\n    }\n    if (_1500)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1507 = _1476 > 1;\n        bool _1514;\n        if (_1507)\n        {\n            _1514 = _1486 > _935.fa_shadow_split.x;\n        }\n        else\n        {\n            _1514 = _1507;\n        }\n        if (_1514)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1520 = _1476 > 2;\n        bool _1527;\n        if (_1520)\n        {\n            _1527 = _1486 > _935.fa_shadow_split.y;\n        }\n        else\n        {\n            _1527 = _1520;\n        }\n        if (_1527)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1533 = _1476 > 3;\n        bool _1540;\n        if (_1533)\n        {\n            _1540 = _1486 > _935.fa_shadow_split.z;\n        }\n        else\n        {\n            _1540 = _1533;\n        }\n        if (_1540)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _232 [[buffer(1)]], constant fa_material& _1661 [[buffer(5)]], constant fa_shadows& _935 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2427 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2427 = -_2427;\n    }\n    float3 _2040 = fast::normalize(_232.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _232, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2427, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2040, short(gl_FrontFacing) };\n    Surface _2048 = fa_standard_surface(param_1, _232, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2458 = _2048.albedo;\n    float _2459 = _2048.alpha;\n    float3 _2460 = _2048.normal;\n    float _2461 = _2048.metallic;\n    float _2462 = _2048.roughness;\n    float _2463 = _2048.occlusion;\n    float3 _2464 = _2048.emission;\n    float _2465 = _2048.clearcoat;\n    float _2466 = _2048.clearcoat_roughness;\n    float3 _2467 = _2048.sheen_color;\n    float _2468 = _2048.sheen_roughness;\n    float _2469 = _2048.anisotropy;\n    float _2470 = _2048.anisotropy_rotation;\n    float _2471 = _2048.specular;\n    float _2472 = _2048.ior;\n    float3 _2473 = _2048.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2427, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2040, short(gl_FrontFacing) };\n    Surface param_3 = _2048;\n    surface(param_2, param_3);\n    _2458 = param_3.albedo;\n    _2459 = param_3.alpha;\n    _2460 = param_3.normal;\n    _2461 = param_3.metallic;\n    _2462 = param_3.roughness;\n    _2463 = param_3.occlusion;\n    _2464 = param_3.emission;\n    _2465 = param_3.clearcoat;\n    _2466 = param_3.clearcoat_roughness;\n    _2467 = param_3.sheen_color;\n    _2468 = param_3.sheen_roughness;\n    _2469 = param_3.anisotropy;\n    _2470 = param_3.anisotropy_rotation;\n    _2471 = param_3.specular;\n    _2472 = param_3.ior;\n    _2473 = param_3.specular_color;\n    float3 result;\n    if (_232.fa_emissive.w > 0.5)\n    {\n        result = _2458;\n    }\n    else\n    {\n        float3 _2069 = _2460;\n        float3 _2070 = fast::normalize(_2069);\n        _2460 = _2070;\n        float3 param_4 = _2070;\n        float3 lit = (fa_ambient_light(param_4, _232, fa_env_smp, fa_irr_tex) * _2458) * _2463;\n        int _2089 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2089; ln++)\n        {\n            int param_5 = ln;\n            int param_6 = fa_cl_light(param_5, _232, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            float3 param_7 = in.fa_world_pos;\n            float3 param_8 = _2427;\n            LightSample _2111 = fa_light_shadowed(param_6, param_7, param_8, _232, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _935, fa_shadow_tex, in.fa_world_pos);\n            SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _2427, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2040, short(gl_FrontFacing) };\n            Surface param_10 = Surface{ _2458, _2459, _2460, _2461, _2462, _2463, _2464, _2465, _2466, _2467, _2468, _2469, _2470, _2471, _2472, _2473 };\n            LightSample param_11 = _2111;\n            lit += light(param_9, param_10, param_11, _1661);\n        }\n        result = lit;\n    }\n    float3 _2126 = result;\n    float3 _2127 = _2126 + _2464;\n    result = _2127;\n    float3 param_12 = _2127;\n    float3 param_13 = in.fa_world_pos;\n    result = fa_shadow_debug(param_12, param_13, _935);\n    bool _2136 = _232.fa_fog.w > 0.0;\n    bool _2143;\n    if (!_2136)\n    {\n        _2143 = _232.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2143 = _2136;\n    }\n    if (_2143)\n    {\n        float3 _2152 = in.fa_world_pos - _232.fa_camera_pos.xyz;\n        float _2158 = dot(_2152, _232.fa_fog_c.xyz);\n        bool _2162 = _232.fa_fog_c.w > 0.5;\n        float _2163;\n        if (_2162)\n        {\n            _2163 = _2158;\n        }\n        else\n        {\n            _2163 = length(_2152);\n        }\n        float _2175 = _2163 - _232.fa_fog_b.x;\n        if (_2175 > 0.0)\n        {\n            float _2184 = _232.fa_fog.w * _2175;\n            float tau = _2184 * _2184;\n            if (_232.fa_fog_b.y > 0.0)\n            {\n                float _2200;\n                if (_2162)\n                {\n                    _2200 = in.fa_world_pos.y - (_232.fa_fog_c.y * _2158);\n                }\n                else\n                {\n                    _2200 = _232.fa_camera_pos.y;\n                }\n                float _2221 = mix(_2200, in.fa_world_pos.y, fast::clamp(_232.fa_fog_b.x / _2163, 0.0, 1.0));\n                float _2225 = in.fa_world_pos.y - _2221;\n                float _2230 = _2221 - _232.fa_fog_b.z;\n                float _2235 = in.fa_world_pos.y - _232.fa_fog_b.z;\n                bool _2238 = _2230 <= 0.0;\n                bool _2239 = !_2238;\n                bool _2245;\n                if (_2239)\n                {\n                    _2245 = _232.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2245 = _2238;\n                }\n                float _2246;\n                if (_2245)\n                {\n                    _2246 = _232.fa_fog_b.y;\n                }\n                else\n                {\n                    _2246 = _232.fa_fog_b.y * exp(-fast::min(_232.fa_fog_b.w * _2230, 80.0));\n                }\n                bool _2273;\n                if (_2239)\n                {\n                    _2273 = _232.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2273 = _2238;\n                }\n                float _2274;\n                if (_2273)\n                {\n                    _2274 = _232.fa_fog_b.y * _2230;\n                }\n                else\n                {\n                    _2274 = (_232.fa_fog_b.y * (1.0 - exp(-fast::min(_232.fa_fog_b.w * _2230, 80.0)))) / _232.fa_fog_b.w;\n                }\n                bool _2299 = _2235 <= 0.0;\n                bool _2306;\n                if (!_2299)\n                {\n                    _2306 = _232.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2306 = _2299;\n                }\n                float _2307;\n                if (_2306)\n                {\n                    _2307 = _232.fa_fog_b.y * _2235;\n                }\n                else\n                {\n                    _2307 = (_232.fa_fog_b.y * (1.0 - exp(-fast::min(_232.fa_fog_b.w * _2235, 80.0)))) / _232.fa_fog_b.w;\n                }\n                float _2334;\n                if (abs(_2225) < 0.001000000047497451305389404296875)\n                {\n                    _2334 = _2246;\n                }\n                else\n                {\n                    _2334 = (_2307 - _2274) / _2225;\n                }\n                tau += (_2175 * fast::max(_2334, 0.0));\n            }\n            result = mix(result, _232.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2459);\n    return out;\n}\n\n",
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
            "inst_name": "_232",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_935",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1661",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_389, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _232, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _704 = _232.fa_cl_info.x < 0.0;\n    bool _711;\n    if (!_704)\n    {\n        _711 = _232.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _711 = _704;\n    }\n    bool _719;\n    if (!_711)\n    {\n        _719 = _232.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _719 = _711;\n    }\n    bool _726;\n    if (!_719)\n    {\n        _726 = _232.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _726 = _719;\n    }\n    bool _733;\n    if (!_726)\n    {\n        _733 = _232.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _733 = _726;\n    }\n    if (_733)\n    {\n        return int2(0);\n    }\n    float4 _743 = float4(world_pos, 1.0);\n    float _750 = dot(_232.fa_cl_vpw, _743);\n    if (!(_750 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _772 = float2(dot(_232.fa_cl_vpx, _743), dot(_232.fa_cl_vpy, _743)) / float2(_750);\n    int _776 = int(_232.fa_cl_grid.x);\n    int _780 = int(_232.fa_cl_grid.y);\n    int param = (int(_232.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_232.fa_cl_fwd.xyz, world_pos) + _232.fa_cl_fwd.w, _232.fa_cl_grid.w) / _232.fa_cl_grid.w) * _232.fa_cl_grid.z)), 0, int(_232.fa_cl_info.y) - 1) * _780) + clamp(int(floor(((_772.y * 0.5) + 0.5) * _232.fa_cl_grid.y)), 0, _780 - 1)) * _776)) + clamp(int(floor(((_772.x * 0.5) + 0.5) * _232.fa_cl_grid.x)), 0, _776 - 1);\n    float4 _851 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_851.x), int(_851.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _232, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_232.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1593 = fa_cluster_lookup(param, _232, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _1593.x;\n    fa_cl_local = _1593.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1722 = fa_linear_to_srgb(param);\n        c = _1722;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1730 = fa_srgb_to_linear(param_1);\n            c = _1730;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _164;\n    if (bool(i.front_facing))\n    {\n        _164 = i.world_normal;\n    }\n    else\n    {\n        _164 = -i.world_normal;\n    }\n    float3 _188 = fast::normalize(i.world_tangent.xyz - (_164 * dot(_164, i.world_tangent.xyz)));\n    float3 _216 = fast::normalize(((_188 * m.x) + ((cross(_164, _188) * i.world_tangent.w) * m.y)) + (_164 * m.z));\n    float3 _219;\n    if (bool(i.front_facing))\n    {\n        _219 = _216;\n    }\n    else\n    {\n        _219 = -_216;\n    }\n    return _219;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _232, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _232.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1761 = fa_tex_fix(param_2, param_3);\n    float4 _2656 = base_t;\n    _2656.x = _1761.x;\n    _2656.y = _1761.y;\n    _2656.z = _1761.z;\n    base_t = _2656;\n    float4 _1775 = (_2656 * _232.fa_base_color) * i.vertex_color;\n    float3 _2593 = i.world_normal;\n    if (_232.fa_maps.z > 0.5)\n    {\n        float param_4 = _232.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1807 = fa_tex_fix(param_6, param_7);\n        float3 _1811 = (_1807 * 2.0) - float3(1.0);\n        float2 _1816 = _1811.xy * _232.fa_maps.x;\n        float3 _2664 = _1811;\n        _2664.x = _1816.x;\n        _2664.y = _1816.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2664;\n        _2593 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _232.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1844 = fa_tex_fix(param_12, param_13);\n    float4 _2667 = mrt;\n    _2667.x = _1844.x;\n    _2667.y = _1844.y;\n    _2667.z = _1844.z;\n    mrt = _2667;\n    float4 _1873 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _232.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1873.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1885 = fa_tex_fix(param_16, param_17);\n    float param_18 = _232.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _1915 = fa_tex_fix(param_20, param_21);\n    float _2598 = _232.fa_layers_a.x;\n    float _2599 = _232.fa_layers_a.y;\n    float _2602 = _232.fa_layers_a.z;\n    float _2601 = _232.fa_layers_b.w;\n    float _2604 = _232.fa_layers_c.x;\n    if (_232.fa_layers_c.z > 0.5)\n    {\n        if (mod(_232.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2598 *= _1885.y;\n            _2599 *= _1885.z;\n            _2601 *= _1873.w;\n        }\n        if (_232.fa_layers_c.z > 1.5)\n        {\n            _2602 *= mrt.x;\n            _2604 *= mrt.w;\n        }\n    }\n    return Surface{ _1775.xyz, _1775.w, _2593, fast::clamp(_232.fa_pbr.x * _1844.z, 0.0, 1.0), fast::clamp(_232.fa_pbr.y * _1844.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_232.fa_maps.y * (_1885.x - 1.0)), _232.fa_emissive.xyz + (_232.fa_model_emissive.xyz * _1915), _2598, _2599, _232.fa_layers_b.xyz, _2601, _2602, _232.fa_layers_a.w, _2604, _232.fa_layers_c.y, _232.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _232, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_232.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _232.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _232, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_232.fa_cl_info.x) + int(_232.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _232, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _232, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _232)\n{\n    return li * ((_232.fa_counts.y > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _313 = dot(d, right);\n    float _317 = dot(d, up);\n    float _328;\n    if (((_313 * _313) + (_317 * _317)) > 1.0000000133514319600180897396058e-10)\n    {\n        _328 = precise::atan2(_317, _313) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _328 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_328 - floor(_328)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_mesh_fs_params& _232, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _361 = fa_light_base(param, _232);\n    bool _365 = _232.fa_counts.y > 4.5;\n    int param_1 = _361;\n    float4 _369 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _361 + 1;\n    float4 _374 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _377 = _374.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _389 = _365 && (_377 > 2.5);\n    fa_light_is_area = _389;\n    bool _392 = _377 < 0.5;\n    float3 l;\n    if (_392)\n    {\n        l = fast::normalize(_369.xyz);\n        if (_365)\n        {\n            int param_3 = _361 + 6;\n            float4 _406 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_406.z > 0.5)\n            {\n                int param_4 = _361 + 4;\n                float4 _416 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _361 + 5;\n                float4 _422 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _406.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _416.xyz) * _416.w, (-dot(world_pos, _422.xyz)) * _422.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _454 = _369.xyz - world_pos;\n        float _456 = length(_454);\n        dist = _456;\n        l = _454 / float3(fast::max(_456, 9.9999997473787516355514526367188e-05));\n        float reach = _456;\n        if (_389)\n        {\n            int param_8 = _361 + 7;\n            reach = fast::max(dist - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n        }\n        float _488 = reach / fast::max(_369.w, 0.001000000047497451305389404296875);\n        float _494 = fast::clamp(1.0 - (_488 * _488), 0.0, 1.0);\n        atten = _494 * _494;\n        bool _502 = _377 < 2.5;\n        if ((_377 > 1.5) && _502)\n        {\n            int param_9 = _361 + 2;\n            float4 _510 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            float _520 = _510.w;\n            int param_10 = _361 + 3;\n            float4 _526 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            float _527 = _526.x;\n            float cos_inner = _527;\n            if (_527 > 1.5)\n            {\n                cos_inner = mix(_520, 1.0, 0.25);\n            }\n            atten *= smoothstep(_520, cos_inner, dot(-l, fast::normalize(_510.xyz)));\n        }\n        if (_365 && _502)\n        {\n            int param_11 = _361 + 6;\n            float4 _551 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            int param_12 = _361 + 7;\n            float4 _556 = fa_light_texel(param_12, fa_light_tex, fa_shadow_smp);\n            bool _559 = _551.z > 0.5;\n            bool _566;\n            if (!_559)\n            {\n                _566 = _556.z > 0.5;\n            }\n            else\n            {\n                _566 = _559;\n            }\n            if (_566)\n            {\n                int param_13 = _361 + 2;\n                float4 _573 = fa_light_texel(param_13, fa_light_tex, fa_shadow_smp);\n                float3 _577 = fast::normalize(_573.xyz);\n                int param_14 = _361 + 4;\n                float4 _582 = fa_light_texel(param_14, fa_light_tex, fa_shadow_smp);\n                int param_15 = _361 + 5;\n                float4 _587 = fa_light_texel(param_15, fa_light_tex, fa_shadow_smp);\n                if (_559)\n                {\n                    float3 _595 = -_454;\n                    float _602 = _573.w;\n                    float _618 = 0.5 / fast::max(dot(_595, _577) * (sqrt(fast::max(1.0 - (_602 * _602), 0.0)) / fast::max(_602, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    float2 param_16 = _551.xy;\n                    float2 param_17 = float2(0.5 + (dot(_595, _582.xyz) * _618), 0.5 - (dot(_595, _587.xyz) * _618));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17, fa_light_atlas, fa_env_smp);\n                }\n                if (_556.z > 0.5)\n                {\n                    float2 param_18 = _556.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _577;\n                    float3 param_21 = _582.xyz;\n                    float3 param_22 = _587.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22, fa_light_atlas, fa_env_smp);\n                }\n            }\n        }\n    }\n    float3 _2560 = _374.xyz * atten;\n    if (_365)\n    {\n        _2560 *= fa_light_tint;\n    }\n    int _686;\n    if (_392)\n    {\n        _686 = 0;\n    }\n    else\n    {\n        _686 = ((_377 > 1.5) && (_377 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _2560, atten, 1.0, dist, _686 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _935)\n{\n    float _925;\n    if (i == 0)\n    {\n        _925 = _935.fa_shadow_split.x;\n    }\n    else\n    {\n        float _941;\n        if (i == 1)\n        {\n            _941 = _935.fa_shadow_split.y;\n        }\n        else\n        {\n            float _949;\n            if (i == 2)\n            {\n                _949 = _935.fa_shadow_split.z;\n            }\n            else\n            {\n                _949 = _935.fa_shadow_split.w;\n            }\n            _941 = _949;\n        }\n        _925 = _941;\n    }\n    return _925;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _913 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_913), sin(_913)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _935, texture2d<float> fa_shadow_tex)\n{\n    float _987 = fast::max(_935.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _992 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _998 = sqrt(1.0 - (_992 * _992));\n    float _1006 = fast::min(_998 / fast::max(_992, 0.20000000298023223876953125), 4.0);\n    float _1011;\n    if (_935.fa_shadow_bias.y > 0.0)\n    {\n        _1011 = _935.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1011 = 1.5 * _935.fa_shadow_info[ci].x;\n    }\n    float4 _1036 = _935.fa_shadow_mat[ci] * float4(world + (n * (_1011 * _998)), 1.0);\n    float _1043 = _1036.x;\n    bool _1046 = _1043 < _935.fa_shadow_rect[ci].x;\n    bool _1055;\n    if (!_1046)\n    {\n        _1055 = _1043 > _935.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1055 = _1046;\n    }\n    bool _1064;\n    if (!_1055)\n    {\n        _1064 = _1036.y < _935.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1064 = _1055;\n    }\n    bool _1073;\n    if (!_1064)\n    {\n        _1073 = _1036.y > _935.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1073 = _1064;\n    }\n    bool _1080;\n    if (!_1073)\n    {\n        _1080 = _1036.z > 1.0;\n    }\n    else\n    {\n        _1080 = _1073;\n    }\n    if (_1080)\n    {\n        return -1.0;\n    }\n    float _1088;\n    if (_935.fa_shadow_bias.x > 0.0)\n    {\n        _1088 = _935.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1088 = 1.5 * _935.fa_shadow_info[ci].x;\n    }\n    float _1107 = _1036.z - ((_1088 * (1.0 + (0.5 * _1006))) / _987);\n    float _1116 = ((_935.fa_shadow_info[ci].x * fast::min(_1006, 3.0)) * 0.5) / _987;\n    int _1125 = int(_935.fa_shadow_cfg.z + 0.5);\n    if (_1125 == 1)\n    {\n        float2 param = _1036.xy;\n        float4 param_1 = _935.fa_shadow_rect[ci];\n        float _1136 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1107 <= _1136);\n    }\n    float _1143 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1146 = _1125 == 2;\n    if (_1146)\n    {\n        float _1160 = fast::clamp(((_935.fa_shadow_cfg.w * _987) * 0.25) / _935.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1143;\n            float2 _1179 = fa_shadow_vogel(param_2, param_3, param_4) * _1160;\n            float2 param_5 = _1036.xy + (_1179 * _935.fa_shadow_bias.zw);\n            float4 param_6 = _935.fa_shadow_rect[ci];\n            float _1190 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1190 < (_1107 - (length(_1179) * _1116)))\n            {\n                sum += _1190;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1107 - (sum / cnt), 0.0) * _987) * _935.fa_shadow_cfg.w) / _935.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1234 = _1146 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1234; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1234;\n        float param_9 = _1143;\n        float2 _1253 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1036.xy + (_1253 * _935.fa_shadow_bias.zw);\n        float4 param_11 = _935.fa_shadow_rect[ci];\n        float _1264 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1107 - (length(_1253) * _1116)) <= _1264);\n    }\n    return lit / float(_1234);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _232, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _935, texture2d<float> fa_shadow_tex)\n{\n    if (_232.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1294 = int(_935.fa_shadow_cfg.x + 0.5);\n    if (_1294 < 1)\n    {\n        return 1.0;\n    }\n    float _1309 = dot(world - _935.fa_shadow_eye.xyz, _935.fa_shadow_fwd.xyz);\n    int param = _1294 - 1;\n    if (_1309 > fa_shadow_split_at(param, _935))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1321 = _1294 > 1;\n    bool _1328;\n    if (_1321)\n    {\n        _1328 = _1309 > _935.fa_shadow_split.x;\n    }\n    else\n    {\n        _1328 = _1321;\n    }\n    if (_1328)\n    {\n        ci = 1;\n    }\n    bool _1332 = _1294 > 2;\n    bool _1339;\n    if (_1332)\n    {\n        _1339 = _1309 > _935.fa_shadow_split.y;\n    }\n    else\n    {\n        _1339 = _1332;\n    }\n    if (_1339)\n    {\n        ci = 2;\n    }\n    bool _1343 = _1294 > 3;\n    bool _1350;\n    if (_1343)\n    {\n        _1350 = _1309 > _935.fa_shadow_split.z;\n    }\n    else\n    {\n        _1350 = _1343;\n    }\n    if (_1350)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1294)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1376 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _935, fa_shadow_tex);\n        s = _1376;\n        if (_1376 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_935.fa_shadow_cfg.y > 0.0)\n    {\n        float _1401;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1401 = fa_shadow_split_at(param_5, _935);\n        }\n        else\n        {\n            _1401 = _935.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1420 = _935.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _935) - _1401, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1431 = fast::clamp((_1309 - (fa_shadow_split_at(param_7, _935) - _1420)) / _1420, 0.0, 1.0);\n        if (_1431 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1294)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1452 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _935, fa_shadow_tex);\n                s2 = _1452;\n                if (_1452 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1431);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _232, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _935, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _232, fa_shadow_smp, gl_FragCoord, _935, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _232, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _935, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1621 = fa_light_sample(param, param_1, _232, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _2573 = _1621.color;\n    float _2575 = _1621.shadow;\n    if ((_1621.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1621.direction;\n        float _1635 = fa_shadow_factor(param_2, param_3, _232, fa_shadow_smp, gl_FragCoord, _935, fa_shadow_tex, fa_world_pos);\n        _2575 = _1635;\n        _2573 *= _1635;\n    }\n    return LightSample{ _1621.direction, _2573, _1621.attenuation, _2575, _1621._distance, _1621.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l, constant fa_material& _1661)\n{\n    float _1655;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _1655 = 1.0;\n    }\n    else\n    {\n        _1655 = _1661.dark;\n    }\n    return (s.albedo * l.color) * _1655;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _935)\n{\n    if (_935.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1476 = int(_935.fa_shadow_cfg.x + 0.5);\n    float _1486 = dot(world - _935.fa_shadow_eye.xyz, _935.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1491 = _1476 > 0;\n    bool _1500;\n    if (_1491)\n    {\n        int param = _1476 - 1;\n        _1500 = _1486 <= fa_shadow_split_at(param, _935);\n    }\n    else\n    {\n        _1500 = _1491;\n    }\n    if (_1500)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1507 = _1476 > 1;\n        bool _1514;\n        if (_1507)\n        {\n            _1514 = _1486 > _935.fa_shadow_split.x;\n        }\n        else\n        {\n            _1514 = _1507;\n        }\n        if (_1514)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1520 = _1476 > 2;\n        bool _1527;\n        if (_1520)\n        {\n            _1527 = _1486 > _935.fa_shadow_split.y;\n        }\n        else\n        {\n            _1527 = _1520;\n        }\n        if (_1527)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1533 = _1476 > 3;\n        bool _1540;\n        if (_1533)\n        {\n            _1540 = _1486 > _935.fa_shadow_split.z;\n        }\n        else\n        {\n            _1540 = _1533;\n        }\n        if (_1540)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _232 [[buffer(1)]], constant fa_material& _1661 [[buffer(5)]], constant fa_shadows& _935 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2427 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2427 = -_2427;\n    }\n    float3 _2040 = fast::normalize(_232.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _232, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2427, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2040, short(gl_FrontFacing) };\n    Surface _2048 = fa_standard_surface(param_1, _232, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2458 = _2048.albedo;\n    float _2459 = _2048.alpha;\n    float3 _2460 = _2048.normal;\n    float _2461 = _2048.metallic;\n    float _2462 = _2048.roughness;\n    float _2463 = _2048.occlusion;\n    float3 _2464 = _2048.emission;\n    float _2465 = _2048.clearcoat;\n    float _2466 = _2048.clearcoat_roughness;\n    float3 _2467 = _2048.sheen_color;\n    float _2468 = _2048.sheen_roughness;\n    float _2469 = _2048.anisotropy;\n    float _2470 = _2048.anisotropy_rotation;\n    float _2471 = _2048.specular;\n    float _2472 = _2048.ior;\n    float3 _2473 = _2048.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2427, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2040, short(gl_FrontFacing) };\n    Surface param_3 = _2048;\n    surface(param_2, param_3);\n    _2458 = param_3.albedo;\n    _2459 = param_3.alpha;\n    _2460 = param_3.normal;\n    _2461 = param_3.metallic;\n    _2462 = param_3.roughness;\n    _2463 = param_3.occlusion;\n    _2464 = param_3.emission;\n    _2465 = param_3.clearcoat;\n    _2466 = param_3.clearcoat_roughness;\n    _2467 = param_3.sheen_color;\n    _2468 = param_3.sheen_roughness;\n    _2469 = param_3.anisotropy;\n    _2470 = param_3.anisotropy_rotation;\n    _2471 = param_3.specular;\n    _2472 = param_3.ior;\n    _2473 = param_3.specular_color;\n    float3 result;\n    if (_232.fa_emissive.w > 0.5)\n    {\n        result = _2458;\n    }\n    else\n    {\n        float3 _2069 = _2460;\n        float3 _2070 = fast::normalize(_2069);\n        _2460 = _2070;\n        float3 param_4 = _2070;\n        float3 lit = (fa_ambient_light(param_4, _232, fa_env_smp, fa_irr_tex) * _2458) * _2463;\n        int _2089 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2089; ln++)\n        {\n            int param_5 = ln;\n            int param_6 = fa_cl_light(param_5, _232, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            float3 param_7 = in.fa_world_pos;\n            float3 param_8 = _2427;\n            LightSample _2111 = fa_light_shadowed(param_6, param_7, param_8, _232, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _935, fa_shadow_tex, in.fa_world_pos);\n            SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _2427, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2040, short(gl_FrontFacing) };\n            Surface param_10 = Surface{ _2458, _2459, _2460, _2461, _2462, _2463, _2464, _2465, _2466, _2467, _2468, _2469, _2470, _2471, _2472, _2473 };\n            LightSample param_11 = _2111;\n            lit += light(param_9, param_10, param_11, _1661);\n        }\n        result = lit;\n    }\n    float3 _2126 = result;\n    float3 _2127 = _2126 + _2464;\n    result = _2127;\n    float3 param_12 = _2127;\n    float3 param_13 = in.fa_world_pos;\n    result = fa_shadow_debug(param_12, param_13, _935);\n    bool _2136 = _232.fa_fog.w > 0.0;\n    bool _2143;\n    if (!_2136)\n    {\n        _2143 = _232.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2143 = _2136;\n    }\n    if (_2143)\n    {\n        float3 _2152 = in.fa_world_pos - _232.fa_camera_pos.xyz;\n        float _2158 = dot(_2152, _232.fa_fog_c.xyz);\n        bool _2162 = _232.fa_fog_c.w > 0.5;\n        float _2163;\n        if (_2162)\n        {\n            _2163 = _2158;\n        }\n        else\n        {\n            _2163 = length(_2152);\n        }\n        float _2175 = _2163 - _232.fa_fog_b.x;\n        if (_2175 > 0.0)\n        {\n            float _2184 = _232.fa_fog.w * _2175;\n            float tau = _2184 * _2184;\n            if (_232.fa_fog_b.y > 0.0)\n            {\n                float _2200;\n                if (_2162)\n                {\n                    _2200 = in.fa_world_pos.y - (_232.fa_fog_c.y * _2158);\n                }\n                else\n                {\n                    _2200 = _232.fa_camera_pos.y;\n                }\n                float _2221 = mix(_2200, in.fa_world_pos.y, fast::clamp(_232.fa_fog_b.x / _2163, 0.0, 1.0));\n                float _2225 = in.fa_world_pos.y - _2221;\n                float _2230 = _2221 - _232.fa_fog_b.z;\n                float _2235 = in.fa_world_pos.y - _232.fa_fog_b.z;\n                bool _2238 = _2230 <= 0.0;\n                bool _2239 = !_2238;\n                bool _2245;\n                if (_2239)\n                {\n                    _2245 = _232.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2245 = _2238;\n                }\n                float _2246;\n                if (_2245)\n                {\n                    _2246 = _232.fa_fog_b.y;\n                }\n                else\n                {\n                    _2246 = _232.fa_fog_b.y * exp(-fast::min(_232.fa_fog_b.w * _2230, 80.0));\n                }\n                bool _2273;\n                if (_2239)\n                {\n                    _2273 = _232.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2273 = _2238;\n                }\n                float _2274;\n                if (_2273)\n                {\n                    _2274 = _232.fa_fog_b.y * _2230;\n                }\n                else\n                {\n                    _2274 = (_232.fa_fog_b.y * (1.0 - exp(-fast::min(_232.fa_fog_b.w * _2230, 80.0)))) / _232.fa_fog_b.w;\n                }\n                bool _2299 = _2235 <= 0.0;\n                bool _2306;\n                if (!_2299)\n                {\n                    _2306 = _232.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2306 = _2299;\n                }\n                float _2307;\n                if (_2306)\n                {\n                    _2307 = _232.fa_fog_b.y * _2235;\n                }\n                else\n                {\n                    _2307 = (_232.fa_fog_b.y * (1.0 - exp(-fast::min(_232.fa_fog_b.w * _2235, 80.0)))) / _232.fa_fog_b.w;\n                }\n                float _2334;\n                if (abs(_2225) < 0.001000000047497451305389404296875)\n                {\n                    _2334 = _2246;\n                }\n                else\n                {\n                    _2334 = (_2307 - _2274) / _2225;\n                }\n                tau += (_2175 * fast::max(_2334, 0.0));\n            }\n            result = mix(result, _232.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2459);\n    return out;\n}\n\n",
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
            "inst_name": "_232",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_935",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1661",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    float4 _241 = (_787 * _213.fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = _213.fa_layers_a.x;\n    float _756 = _213.fa_layers_a.y;\n    float _759 = _213.fa_layers_a.z;\n    float _758 = _213.fa_layers_b.w;\n    float _761 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _750, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _755, _756, _213.fa_layers_b.xyz, _758, _759, _213.fa_layers_a.w, _761, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _661 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _661, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _661, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    float4 _241 = (_787 * _213.fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = _213.fa_layers_a.x;\n    float _756 = _213.fa_layers_a.y;\n    float _759 = _213.fa_layers_a.z;\n    float _758 = _213.fa_layers_b.w;\n    float _761 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _750, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _755, _756, _213.fa_layers_b.xyz, _758, _759, _213.fa_layers_a.w, _761, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _661 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _661, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _661, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
