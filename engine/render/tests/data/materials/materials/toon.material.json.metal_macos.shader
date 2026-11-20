{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "7cd31c28ac6572768802838498bbbd3180b96e0a1bb1bab7ad49d1d6af9d528c",
  "slang": "metal_macos",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_268, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _388)\n{\n    bool _393 = _388.fa_cl_info.x < 0.0;\n    bool _400;\n    if (!_393)\n    {\n        _400 = _388.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _400 = _393;\n    }\n    bool _408;\n    if (!_400)\n    {\n        _408 = _388.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _408 = _400;\n    }\n    bool _415;\n    if (!_408)\n    {\n        _415 = _388.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _415 = _408;\n    }\n    bool _422;\n    if (!_415)\n    {\n        _422 = _388.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _422 = _415;\n    }\n    if (_422)\n    {\n        return int2(0);\n    }\n    float4 _432 = float4(world_pos, 1.0);\n    float _439 = dot(_388.fa_cl_vpw, _432);\n    if (!(_439 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _461 = float2(dot(_388.fa_cl_vpx, _432), dot(_388.fa_cl_vpy, _432)) / float2(_439);\n    int _465 = int(_388.fa_cl_grid.x);\n    int _469 = int(_388.fa_cl_grid.y);\n    int param = (int(_388.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_388.fa_cl_fwd.xyz, world_pos) + _388.fa_cl_fwd.w, _388.fa_cl_grid.w) / _388.fa_cl_grid.w) * _388.fa_cl_grid.z)), 0, int(_388.fa_cl_info.y) - 1) * _469) + clamp(int(floor(((_461.y * 0.5) + 0.5) * _388.fa_cl_grid.y)), 0, _469 - 1)) * _465)) + clamp(int(floor(((_461.x * 0.5) + 0.5) * _388.fa_cl_grid.x)), 0, _465 - 1);\n    float4 _540 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_540.x), int(_540.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _388, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_388.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1668 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _388);\n    fa_cl_slot = _1668.x;\n    fa_cl_local = _1668.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1825 = fa_linear_to_srgb(param);\n        c = _1825;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1833 = fa_srgb_to_linear(param_1);\n            c = _1833;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _169;\n    if (bool(i.front_facing))\n    {\n        _169 = i.world_normal;\n    }\n    else\n    {\n        _169 = -i.world_normal;\n    }\n    float3 _193 = fast::normalize(i.world_tangent.xyz - (_169 * dot(_169, i.world_tangent.xyz)));\n    float3 _221 = fast::normalize(((_193 * m.x) + ((cross(_169, _193) * i.world_tangent.w) * m.y)) + (_169 * m.z));\n    float3 _224;\n    if (bool(i.front_facing))\n    {\n        _224 = _221;\n    }\n    else\n    {\n        _224 = -_221;\n    }\n    return _224;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _388, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _388.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1864 = fa_tex_fix(param_2, param_3);\n    float4 _2782 = base_t;\n    _2782.x = _1864.x;\n    _2782.y = _1864.y;\n    _2782.z = _1864.z;\n    base_t = _2782;\n    float4 _1878 = (_2782 * _388.fa_base_color) * i.vertex_color;\n    float3 _2697 = i.world_normal;\n    if (_388.fa_maps.z > 0.5)\n    {\n        float param_4 = _388.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1910 = fa_tex_fix(param_6, param_7);\n        float3 _1914 = (_1910 * 2.0) - float3(1.0);\n        float2 _1919 = _1914.xy * _388.fa_maps.x;\n        float3 _2790 = _1914;\n        _2790.x = _1919.x;\n        _2790.y = _1919.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2790;\n        _2697 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _388.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1948 = fa_tex_fix(param_12, param_13);\n    float4 _2793 = mrt;\n    _2793.x = _1948.x;\n    _2793.y = _1948.y;\n    _2793.z = _1948.z;\n    mrt = _2793;\n    float4 _1977 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _388.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1977.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1989 = fa_tex_fix(param_16, param_17);\n    float param_18 = _388.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2019 = fa_tex_fix(param_20, param_21);\n    float _2702 = _388.fa_layers_a.x;\n    float _2703 = _388.fa_layers_a.y;\n    float _2706 = _388.fa_layers_a.z;\n    float _2705 = _388.fa_layers_b.w;\n    float _2708 = _388.fa_layers_c.x;\n    if (_388.fa_layers_c.z > 0.5)\n    {\n        if (mod(_388.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2702 *= _1989.y;\n            _2703 *= _1989.z;\n            _2705 *= _1977.w;\n        }\n        if (_388.fa_layers_c.z > 1.5)\n        {\n            _2706 *= mrt.x;\n            _2708 *= mrt.w;\n        }\n    }\n    return Surface{ _1878.xyz, _1878.w, _2697, fast::clamp(_388.fa_pbr.x * _1948.z, 0.0, 1.0), fast::clamp(_388.fa_pbr.y * _1948.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_388.fa_maps.y * (_1989.x - 1.0)), _388.fa_emissive.xyz + (_388.fa_model_emissive.xyz * _2019), _2702, _2703, _388.fa_layers_b.xyz, _2705, _2706, _388.fa_layers_a.w, _2708, _388.fa_layers_c.y, _388.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _388, texturecube<float> fa_irr_tex, sampler fa_env_smp)\n{\n    if (_388.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _388.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _388)\n{\n    int param = (int(_388.fa_cl_info.x) + int(_388.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _388, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _388);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _261 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _267 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _270 = _267.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _277 = _270 < 0.5;\n    float3 l;\n    if (_277)\n    {\n        l = fast::normalize(_261.xyz);\n    }\n    else\n    {\n        float3 _289 = _261.xyz - world_pos;\n        float _291 = length(_289);\n        dist = _291;\n        l = _289 / float3(fast::max(_291, 9.9999997473787516355514526367188e-05));\n        float _306 = _291 / fast::max(_261.w, 0.001000000047497451305389404296875);\n        float _312 = fast::clamp(1.0 - (_306 * _306), 0.0, 1.0);\n        atten = _312 * _312;\n        if (_270 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _326 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _336 = _326.w;\n            int param_3 = (li * 4) + 3;\n            float4 _343 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _344 = _343.x;\n            float cos_inner = _344;\n            if (_344 > 1.5)\n            {\n                cos_inner = mix(_336, 1.0, 0.25);\n            }\n            atten *= smoothstep(_336, cos_inner, dot(-l, fast::normalize(_326.xyz)));\n        }\n    }\n    int _374;\n    if (_277)\n    {\n        _374 = 0;\n    }\n    else\n    {\n        _374 = (_270 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _267.xyz * atten, atten, 1.0, dist, _374 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _624)\n{\n    float _614;\n    if (i == 0)\n    {\n        _614 = _624.fa_shadow_split.x;\n    }\n    else\n    {\n        float _630;\n        if (i == 1)\n        {\n            _630 = _624.fa_shadow_split.y;\n        }\n        else\n        {\n            float _638;\n            if (i == 2)\n            {\n                _638 = _624.fa_shadow_split.z;\n            }\n            else\n            {\n                _638 = _624.fa_shadow_split.w;\n            }\n            _630 = _638;\n        }\n        _614 = _630;\n    }\n    return _614;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _671 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _675;\n    if (conv.x < 0.5)\n    {\n        _675 = _671;\n    }\n    else\n    {\n        _675 = (conv.y * conv.z) / (conv.z - (_671 * (conv.z - conv.y)));\n    }\n    return _675;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _602 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_602), sin(_602)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _624, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _721 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _735 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _721;\n            float2 _754 = fa_shadow_vogel(param_3, param_4, param_5) * _735;\n            float2 param_6 = uv + (_754 * _624.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _766 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_766 < (zr - (length(_754) * plane)))\n            {\n                sum += _766;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _810 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _810; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _810;\n        float param_11 = _721;\n        float2 _829 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_829 * _624.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_829) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_810);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _624, texture2d<float> fa_shadow_tex)\n{\n    float _871 = fast::max(_624.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _876 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _882 = sqrt(1.0 - (_876 * _876));\n    float _890 = fast::min(_882 / fast::max(_876, 0.20000000298023223876953125), 4.0);\n    float _895;\n    if (_624.fa_shadow_bias.y > 0.0)\n    {\n        _895 = _624.fa_shadow_bias.y;\n    }\n    else\n    {\n        _895 = 1.5 * _624.fa_shadow_info[ci].x;\n    }\n    float4 _920 = _624.fa_shadow_mat[ci] * float4(world + (n * (_895 * _882)), 1.0);\n    float _927 = _920.x;\n    bool _930 = _927 < _624.fa_shadow_rect[ci].x;\n    bool _939;\n    if (!_930)\n    {\n        _939 = _927 > _624.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _939 = _930;\n    }\n    bool _948;\n    if (!_939)\n    {\n        _948 = _920.y < _624.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _948 = _939;\n    }\n    bool _957;\n    if (!_948)\n    {\n        _957 = _920.y > _624.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _957 = _948;\n    }\n    bool _964;\n    if (!_957)\n    {\n        _964 = _920.z > 1.0;\n    }\n    else\n    {\n        _964 = _957;\n    }\n    if (_964)\n    {\n        return -1.0;\n    }\n    float _973;\n    if (_624.fa_shadow_bias.x > 0.0)\n    {\n        _973 = _624.fa_shadow_bias.x;\n    }\n    else\n    {\n        _973 = 1.5 * _624.fa_shadow_info[ci].x;\n    }\n    float2 param = _920.xy;\n    float4 param_1 = _624.fa_shadow_rect[ci];\n    float param_2 = _920.z - ((_973 * (1.0 + (0.5 * _890))) / _871);\n    float param_3 = _624.fa_shadow_info[ci].x;\n    float param_4 = _871;\n    float param_5 = _871 * 0.25;\n    float param_6 = ((_624.fa_shadow_info[ci].x * fast::min(_890, 3.0)) * 0.5) / _871;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_624.fa_shadow_cfg.z + 0.5);\n    float param_9 = _624.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _624, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _388, thread float4& gl_FragCoord, constant fa_shadows& _624, texture2d<float> fa_shadow_tex)\n{\n    if (_388.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1367 = int(_624.fa_shadow_cfg.x + 0.5);\n    if (_1367 < 1)\n    {\n        return 1.0;\n    }\n    float _1383 = dot(world - _624.fa_shadow_eye.xyz, _624.fa_shadow_fwd.xyz);\n    int param = _1367 - 1;\n    if (_1383 > fa_shadow_split_at(param, _624))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1395 = _1367 > 1;\n    bool _1402;\n    if (_1395)\n    {\n        _1402 = _1383 > _624.fa_shadow_split.x;\n    }\n    else\n    {\n        _1402 = _1395;\n    }\n    if (_1402)\n    {\n        ci = 1;\n    }\n    bool _1406 = _1367 > 2;\n    bool _1413;\n    if (_1406)\n    {\n        _1413 = _1383 > _624.fa_shadow_split.y;\n    }\n    else\n    {\n        _1413 = _1406;\n    }\n    if (_1413)\n    {\n        ci = 2;\n    }\n    bool _1417 = _1367 > 3;\n    bool _1424;\n    if (_1417)\n    {\n        _1424 = _1383 > _624.fa_shadow_split.z;\n    }\n    else\n    {\n        _1424 = _1417;\n    }\n    if (_1424)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1367)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1450 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _624, fa_shadow_tex);\n        s = _1450;\n        if (_1450 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_624.fa_shadow_cfg.y > 0.0)\n    {\n        float _1475;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1475 = fa_shadow_split_at(param_5, _624);\n        }\n        else\n        {\n            _1475 = _624.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1494 = _624.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _624) - _1475, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1505 = fast::clamp((_1383 - (fa_shadow_split_at(param_7, _624) - _1494)) / _1494, 0.0, 1.0);\n        if (_1505 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1367)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1526 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _624, fa_shadow_tex);\n                s2 = _1526;\n                if (_1526 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1505);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _388, thread float4& gl_FragCoord, constant fa_shadows& _624, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _388, gl_FragCoord, _624, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _388, thread float4& gl_FragCoord, constant fa_shadows& _624, texture2d<float> fa_shadow_tex)\n{\n    bool _1032 = _388.fa_pbr.z < 0.5;\n    bool _1040;\n    if (!_1032)\n    {\n        _1040 = _624.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1040 = _1032;\n    }\n    if (_1040)\n    {\n        return 1.0;\n    }\n    int param = (int(_624.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1053 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1054 = _1053.x;\n    if (_1054 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1063 = int(_1054 + 0.5);\n    int param_1 = _1063;\n    float4 _1067 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1063 + 1;\n    float4 _1072 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1075 = _1067.y;\n    if (_1075 > 0.0)\n    {\n        float _1092 = 1.0 - smoothstep(0.75 * _1075, _1075, length(world - _624.fa_shadow_eye.xyz));\n        fade = _1092;\n        if (_1092 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1067.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1111 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1114 = abs(_1111);\n        float _1116 = _1114.x;\n        float _1118 = _1114.y;\n        bool _1119 = _1116 >= _1118;\n        bool _1127;\n        if (_1119)\n        {\n            _1127 = _1116 >= _1114.z;\n        }\n        else\n        {\n            _1127 = _1119;\n        }\n        int _1128;\n        if (_1127)\n        {\n            _1128 = (_1111.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1141;\n            if (_1118 >= _1114.z)\n            {\n                _1141 = (_1111.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1141 = (_1111.z > 0.0) ? 4 : 5;\n            }\n            _1128 = _1141;\n        }\n        face = _1128;\n    }\n    int _1160 = (_1063 + 2) + (face * 6);\n    int param_4 = _1160;\n    int param_5 = _1160 + 1;\n    int param_6 = _1160 + 3;\n    float4 _1174 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1160 + 4;\n    float4 _1179 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1160 + 5;\n    float4 _1184 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1196 = _1184.x * fast::max(dot(_1174, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1201 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1207 = sqrt(1.0 - (_1201 * _1201));\n    float _1213 = fast::min(_1207 / fast::max(_1201, 0.20000000298023223876953125), 4.0);\n    float _1216 = _1072.y;\n    float _1218;\n    if (_1216 > 0.0)\n    {\n        _1218 = _1216;\n    }\n    else\n    {\n        _1218 = 1.5 * _1196;\n    }\n    float4 _1238 = float4(world + (n * (_1218 * _1207)), 1.0);\n    float _1242 = dot(_1174, _1238);\n    float _1245 = _1184.y;\n    if (_1242 < _1245)\n    {\n        return 1.0;\n    }\n    float2 _1260 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1238), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1238)) / float2(_1242);\n    float _1262 = _1260.x;\n    bool _1265 = _1262 < _1179.x;\n    bool _1274;\n    if (!_1265)\n    {\n        _1274 = _1262 > _1179.z;\n    }\n    else\n    {\n        _1274 = _1265;\n    }\n    bool _1283;\n    if (!_1274)\n    {\n        _1283 = _1260.y < _1179.y;\n    }\n    else\n    {\n        _1283 = _1274;\n    }\n    bool _1292;\n    if (!_1283)\n    {\n        _1292 = _1260.y > _1179.w;\n    }\n    else\n    {\n        _1292 = _1283;\n    }\n    if (_1292)\n    {\n        return 1.0;\n    }\n    float _1298 = _1072.x;\n    float _1300;\n    if (_1298 > 0.0)\n    {\n        _1300 = _1298;\n    }\n    else\n    {\n        _1300 = 1.5 * _1196;\n    }\n    float2 param_9 = _1260;\n    float4 param_10 = _1179;\n    float param_11 = _1242 - (_1300 * (1.0 + (0.5 * _1213)));\n    float param_12 = _1196;\n    float param_13 = 1.0;\n    float param_14 = _1184.z * 0.25;\n    float param_15 = (_1196 * fast::min(_1213, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _1245, _1184.z);\n    int param_17 = int(_1067.z + 0.5);\n    float param_18 = _1067.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _624, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _388, thread float4& gl_FragCoord, constant fa_shadows& _624, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1696 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2682 = _1696.direction;\n    float3 _2677 = _1696.color;\n    float _2684 = _1696.attenuation;\n    float _2679 = _1696.shadow;\n    int _2687 = _1696.type;\n    if ((_2687 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2682;\n        float _1710 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _388, gl_FragCoord, _624, fa_shadow_tex, fa_world_pos);\n        _2679 = _1710;\n        _2677 *= _1710;\n    }\n    else\n    {\n        bool _1721 = _2687 != 0;\n        bool _1727;\n        if (_1721)\n        {\n            _1727 = _2684 > 0.0;\n        }\n        else\n        {\n            _1727 = _1721;\n        }\n        if (_1727)\n        {\n            int param_4 = li;\n            float3 param_5 = world_pos;\n            float3 param_6 = gn;\n            float3 param_7 = _2682;\n            float _1739 = fa_shadow_local(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _388, gl_FragCoord, _624, fa_shadow_tex);\n            _2679 = _1739;\n            _2677 *= _1739;\n        }\n    }\n    return LightSample{ _2682, _2677, _2684, _2679, _1696._distance, _2687 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l, constant fa_material& _1765)\n{\n    float _1759;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _1759 = 1.0;\n    }\n    else\n    {\n        _1759 = _1765.dark;\n    }\n    return (s.albedo * l.color) * _1759;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _624)\n{\n    if (_624.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1550 = int(_624.fa_shadow_cfg.x + 0.5);\n    float _1560 = dot(world - _624.fa_shadow_eye.xyz, _624.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1565 = _1550 > 0;\n    bool _1574;\n    if (_1565)\n    {\n        int param = _1550 - 1;\n        _1574 = _1560 <= fa_shadow_split_at(param, _624);\n    }\n    else\n    {\n        _1574 = _1565;\n    }\n    if (_1574)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1581 = _1550 > 1;\n        bool _1588;\n        if (_1581)\n        {\n            _1588 = _1560 > _624.fa_shadow_split.x;\n        }\n        else\n        {\n            _1588 = _1581;\n        }\n        if (_1588)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1594 = _1550 > 2;\n        bool _1601;\n        if (_1594)\n        {\n            _1601 = _1560 > _624.fa_shadow_split.y;\n        }\n        else\n        {\n            _1601 = _1594;\n        }\n        if (_1601)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1607 = _1550 > 3;\n        bool _1614;\n        if (_1607)\n        {\n            _1614 = _1560 > _624.fa_shadow_split.z;\n        }\n        else\n        {\n            _1614 = _1607;\n        }\n        if (_1614)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _388 [[buffer(1)]], constant fa_material& _1765 [[buffer(5)]], constant fa_shadows& _624 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2531 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2531 = -_2531;\n    }\n    float3 _2144 = fast::normalize(_388.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _388, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2531, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2144, short(gl_FrontFacing) };\n    Surface _2152 = fa_standard_surface(param_1, _388, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2562 = _2152.albedo;\n    float _2563 = _2152.alpha;\n    float3 _2564 = _2152.normal;\n    float _2565 = _2152.metallic;\n    float _2566 = _2152.roughness;\n    float _2567 = _2152.occlusion;\n    float3 _2568 = _2152.emission;\n    float _2569 = _2152.clearcoat;\n    float _2570 = _2152.clearcoat_roughness;\n    float3 _2571 = _2152.sheen_color;\n    float _2572 = _2152.sheen_roughness;\n    float _2573 = _2152.anisotropy;\n    float _2574 = _2152.anisotropy_rotation;\n    float _2575 = _2152.specular;\n    float _2576 = _2152.ior;\n    float3 _2577 = _2152.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2531, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2144, short(gl_FrontFacing) };\n    Surface param_3 = _2152;\n    surface(param_2, param_3);\n    _2562 = param_3.albedo;\n    _2563 = param_3.alpha;\n    _2564 = param_3.normal;\n    _2565 = param_3.metallic;\n    _2566 = param_3.roughness;\n    _2567 = param_3.occlusion;\n    _2568 = param_3.emission;\n    _2569 = param_3.clearcoat;\n    _2570 = param_3.clearcoat_roughness;\n    _2571 = param_3.sheen_color;\n    _2572 = param_3.sheen_roughness;\n    _2573 = param_3.anisotropy;\n    _2574 = param_3.anisotropy_rotation;\n    _2575 = param_3.specular;\n    _2576 = param_3.ior;\n    _2577 = param_3.specular_color;\n    float3 result;\n    if (_388.fa_emissive.w > 0.5)\n    {\n        result = _2562;\n    }\n    else\n    {\n        float3 _2173 = _2564;\n        float3 _2174 = fast::normalize(_2173);\n        _2564 = _2174;\n        float3 param_4 = _2174;\n        float3 lit = (fa_ambient_light(param_4, _388, fa_irr_tex, fa_env_smp) * _2562) * _2567;\n        int _2193 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2193; ln++)\n        {\n            int param_5 = ln;\n            int param_6 = fa_cl_light(param_5, fa_light_tex, fa_shadow_smp, _388, fa_cl_ndir, fa_cl_slot);\n            float3 param_7 = in.fa_world_pos;\n            float3 param_8 = _2531;\n            SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _2531, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2144, short(gl_FrontFacing) };\n            Surface param_10 = Surface{ _2562, _2563, _2564, _2565, _2566, _2567, _2568, _2569, _2570, _2571, _2572, _2573, _2574, _2575, _2576, _2577 };\n            LightSample param_11 = fa_light_shadowed(param_6, param_7, param_8, fa_light_tex, fa_shadow_smp, _388, gl_FragCoord, _624, fa_shadow_tex, in.fa_world_pos);\n            lit += light(param_9, param_10, param_11, _1765);\n        }\n        result = lit;\n    }\n    float3 _2230 = result;\n    float3 _2231 = _2230 + _2568;\n    result = _2231;\n    float3 param_12 = _2231;\n    float3 param_13 = in.fa_world_pos;\n    result = fa_shadow_debug(param_12, param_13, _624);\n    bool _2240 = _388.fa_fog.w > 0.0;\n    bool _2247;\n    if (!_2240)\n    {\n        _2247 = _388.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2247 = _2240;\n    }\n    if (_2247)\n    {\n        float3 _2256 = in.fa_world_pos - _388.fa_camera_pos.xyz;\n        float _2262 = dot(_2256, _388.fa_fog_c.xyz);\n        bool _2266 = _388.fa_fog_c.w > 0.5;\n        float _2267;\n        if (_2266)\n        {\n            _2267 = _2262;\n        }\n        else\n        {\n            _2267 = length(_2256);\n        }\n        float _2279 = _2267 - _388.fa_fog_b.x;\n        if (_2279 > 0.0)\n        {\n            float _2288 = _388.fa_fog.w * _2279;\n            float tau = _2288 * _2288;\n            if (_388.fa_fog_b.y > 0.0)\n            {\n                float _2304;\n                if (_2266)\n                {\n                    _2304 = in.fa_world_pos.y - (_388.fa_fog_c.y * _2262);\n                }\n                else\n                {\n                    _2304 = _388.fa_camera_pos.y;\n                }\n                float _2325 = mix(_2304, in.fa_world_pos.y, fast::clamp(_388.fa_fog_b.x / _2267, 0.0, 1.0));\n                float _2329 = in.fa_world_pos.y - _2325;\n                float _2334 = _2325 - _388.fa_fog_b.z;\n                float _2339 = in.fa_world_pos.y - _388.fa_fog_b.z;\n                bool _2342 = _2334 <= 0.0;\n                bool _2343 = !_2342;\n                bool _2349;\n                if (_2343)\n                {\n                    _2349 = _388.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2349 = _2342;\n                }\n                float _2350;\n                if (_2349)\n                {\n                    _2350 = _388.fa_fog_b.y;\n                }\n                else\n                {\n                    _2350 = _388.fa_fog_b.y * exp(-fast::min(_388.fa_fog_b.w * _2334, 80.0));\n                }\n                bool _2377;\n                if (_2343)\n                {\n                    _2377 = _388.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2377 = _2342;\n                }\n                float _2378;\n                if (_2377)\n                {\n                    _2378 = _388.fa_fog_b.y * _2334;\n                }\n                else\n                {\n                    _2378 = (_388.fa_fog_b.y * (1.0 - exp(-fast::min(_388.fa_fog_b.w * _2334, 80.0)))) / _388.fa_fog_b.w;\n                }\n                bool _2403 = _2339 <= 0.0;\n                bool _2410;\n                if (!_2403)\n                {\n                    _2410 = _388.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2410 = _2403;\n                }\n                float _2411;\n                if (_2410)\n                {\n                    _2411 = _388.fa_fog_b.y * _2339;\n                }\n                else\n                {\n                    _2411 = (_388.fa_fog_b.y * (1.0 - exp(-fast::min(_388.fa_fog_b.w * _2339, 80.0)))) / _388.fa_fog_b.w;\n                }\n                float _2438;\n                if (abs(_2329) < 0.001000000047497451305389404296875)\n                {\n                    _2438 = _2350;\n                }\n                else\n                {\n                    _2438 = (_2411 - _2378) / _2329;\n                }\n                tau += (_2279 * fast::max(_2438, 0.0));\n            }\n            result = mix(result, _388.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2563);\n    return out;\n}\n\n",
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
            "inst_name": "_388",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_624",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1765",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_389, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _388)\n{\n    bool _393 = _388.fa_cl_info.x < 0.0;\n    bool _400;\n    if (!_393)\n    {\n        _400 = _388.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _400 = _393;\n    }\n    bool _408;\n    if (!_400)\n    {\n        _408 = _388.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _408 = _400;\n    }\n    bool _415;\n    if (!_408)\n    {\n        _415 = _388.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _415 = _408;\n    }\n    bool _422;\n    if (!_415)\n    {\n        _422 = _388.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _422 = _415;\n    }\n    if (_422)\n    {\n        return int2(0);\n    }\n    float4 _432 = float4(world_pos, 1.0);\n    float _439 = dot(_388.fa_cl_vpw, _432);\n    if (!(_439 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _461 = float2(dot(_388.fa_cl_vpx, _432), dot(_388.fa_cl_vpy, _432)) / float2(_439);\n    int _465 = int(_388.fa_cl_grid.x);\n    int _469 = int(_388.fa_cl_grid.y);\n    int param = (int(_388.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_388.fa_cl_fwd.xyz, world_pos) + _388.fa_cl_fwd.w, _388.fa_cl_grid.w) / _388.fa_cl_grid.w) * _388.fa_cl_grid.z)), 0, int(_388.fa_cl_info.y) - 1) * _469) + clamp(int(floor(((_461.y * 0.5) + 0.5) * _388.fa_cl_grid.y)), 0, _469 - 1)) * _465)) + clamp(int(floor(((_461.x * 0.5) + 0.5) * _388.fa_cl_grid.x)), 0, _465 - 1);\n    float4 _540 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_540.x), int(_540.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _388, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_388.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _1668 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _388);\n    fa_cl_slot = _1668.x;\n    fa_cl_local = _1668.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _1825 = fa_linear_to_srgb(param);\n        c = _1825;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _1833 = fa_srgb_to_linear(param_1);\n            c = _1833;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _169;\n    if (bool(i.front_facing))\n    {\n        _169 = i.world_normal;\n    }\n    else\n    {\n        _169 = -i.world_normal;\n    }\n    float3 _193 = fast::normalize(i.world_tangent.xyz - (_169 * dot(_169, i.world_tangent.xyz)));\n    float3 _221 = fast::normalize(((_193 * m.x) + ((cross(_169, _193) * i.world_tangent.w) * m.y)) + (_169 * m.z));\n    float3 _224;\n    if (bool(i.front_facing))\n    {\n        _224 = _221;\n    }\n    else\n    {\n        _224 = -_221;\n    }\n    return _224;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _388, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _388.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _1864 = fa_tex_fix(param_2, param_3);\n    float4 _2782 = base_t;\n    _2782.x = _1864.x;\n    _2782.y = _1864.y;\n    _2782.z = _1864.z;\n    base_t = _2782;\n    float4 _1878 = (_2782 * _388.fa_base_color) * i.vertex_color;\n    float3 _2697 = i.world_normal;\n    if (_388.fa_maps.z > 0.5)\n    {\n        float param_4 = _388.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _1910 = fa_tex_fix(param_6, param_7);\n        float3 _1914 = (_1910 * 2.0) - float3(1.0);\n        float2 _1919 = _1914.xy * _388.fa_maps.x;\n        float3 _2790 = _1914;\n        _2790.x = _1919.x;\n        _2790.y = _1919.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _2790;\n        _2697 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _388.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _1948 = fa_tex_fix(param_12, param_13);\n    float4 _2793 = mrt;\n    _2793.x = _1948.x;\n    _2793.y = _1948.y;\n    _2793.z = _1948.z;\n    mrt = _2793;\n    float4 _1977 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _388.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _1977.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _1989 = fa_tex_fix(param_16, param_17);\n    float param_18 = _388.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2019 = fa_tex_fix(param_20, param_21);\n    float _2702 = _388.fa_layers_a.x;\n    float _2703 = _388.fa_layers_a.y;\n    float _2706 = _388.fa_layers_a.z;\n    float _2705 = _388.fa_layers_b.w;\n    float _2708 = _388.fa_layers_c.x;\n    if (_388.fa_layers_c.z > 0.5)\n    {\n        if (mod(_388.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _2702 *= _1989.y;\n            _2703 *= _1989.z;\n            _2705 *= _1977.w;\n        }\n        if (_388.fa_layers_c.z > 1.5)\n        {\n            _2706 *= mrt.x;\n            _2708 *= mrt.w;\n        }\n    }\n    return Surface{ _1878.xyz, _1878.w, _2697, fast::clamp(_388.fa_pbr.x * _1948.z, 0.0, 1.0), fast::clamp(_388.fa_pbr.y * _1948.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_388.fa_maps.y * (_1989.x - 1.0)), _388.fa_emissive.xyz + (_388.fa_model_emissive.xyz * _2019), _2702, _2703, _388.fa_layers_b.xyz, _2705, _2706, _388.fa_layers_a.w, _2708, _388.fa_layers_c.y, _388.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _388, texturecube<float> fa_irr_tex, sampler fa_env_smp)\n{\n    if (_388.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _388.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _388)\n{\n    int param = (int(_388.fa_cl_info.x) + int(_388.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _388, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _388);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _261 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _267 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _270 = _267.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _277 = _270 < 0.5;\n    float3 l;\n    if (_277)\n    {\n        l = fast::normalize(_261.xyz);\n    }\n    else\n    {\n        float3 _289 = _261.xyz - world_pos;\n        float _291 = length(_289);\n        dist = _291;\n        l = _289 / float3(fast::max(_291, 9.9999997473787516355514526367188e-05));\n        float _306 = _291 / fast::max(_261.w, 0.001000000047497451305389404296875);\n        float _312 = fast::clamp(1.0 - (_306 * _306), 0.0, 1.0);\n        atten = _312 * _312;\n        if (_270 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _326 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _336 = _326.w;\n            int param_3 = (li * 4) + 3;\n            float4 _343 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _344 = _343.x;\n            float cos_inner = _344;\n            if (_344 > 1.5)\n            {\n                cos_inner = mix(_336, 1.0, 0.25);\n            }\n            atten *= smoothstep(_336, cos_inner, dot(-l, fast::normalize(_326.xyz)));\n        }\n    }\n    int _374;\n    if (_277)\n    {\n        _374 = 0;\n    }\n    else\n    {\n        _374 = (_270 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _267.xyz * atten, atten, 1.0, dist, _374 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _624)\n{\n    float _614;\n    if (i == 0)\n    {\n        _614 = _624.fa_shadow_split.x;\n    }\n    else\n    {\n        float _630;\n        if (i == 1)\n        {\n            _630 = _624.fa_shadow_split.y;\n        }\n        else\n        {\n            float _638;\n            if (i == 2)\n            {\n                _638 = _624.fa_shadow_split.z;\n            }\n            else\n            {\n                _638 = _624.fa_shadow_split.w;\n            }\n            _630 = _638;\n        }\n        _614 = _630;\n    }\n    return _614;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _671 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _675;\n    if (conv.x < 0.5)\n    {\n        _675 = _671;\n    }\n    else\n    {\n        _675 = (conv.y * conv.z) / (conv.z - (_671 * (conv.z - conv.y)));\n    }\n    return _675;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _602 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_602), sin(_602)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _624, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _721 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _735 = fast::clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _721;\n            float2 _754 = fa_shadow_vogel(param_3, param_4, param_5) * _735;\n            float2 param_6 = uv + (_754 * _624.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _766 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_766 < (zr - (length(_754) * plane)))\n            {\n                sum += _766;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _810 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _810; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _810;\n        float param_11 = _721;\n        float2 _829 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_829 * _624.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_829) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_810);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _624, texture2d<float> fa_shadow_tex)\n{\n    float _871 = fast::max(_624.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _876 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _882 = sqrt(1.0 - (_876 * _876));\n    float _890 = fast::min(_882 / fast::max(_876, 0.20000000298023223876953125), 4.0);\n    float _895;\n    if (_624.fa_shadow_bias.y > 0.0)\n    {\n        _895 = _624.fa_shadow_bias.y;\n    }\n    else\n    {\n        _895 = 1.5 * _624.fa_shadow_info[ci].x;\n    }\n    float4 _920 = _624.fa_shadow_mat[ci] * float4(world + (n * (_895 * _882)), 1.0);\n    float _927 = _920.x;\n    bool _930 = _927 < _624.fa_shadow_rect[ci].x;\n    bool _939;\n    if (!_930)\n    {\n        _939 = _927 > _624.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _939 = _930;\n    }\n    bool _948;\n    if (!_939)\n    {\n        _948 = _920.y < _624.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _948 = _939;\n    }\n    bool _957;\n    if (!_948)\n    {\n        _957 = _920.y > _624.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _957 = _948;\n    }\n    bool _964;\n    if (!_957)\n    {\n        _964 = _920.z > 1.0;\n    }\n    else\n    {\n        _964 = _957;\n    }\n    if (_964)\n    {\n        return -1.0;\n    }\n    float _973;\n    if (_624.fa_shadow_bias.x > 0.0)\n    {\n        _973 = _624.fa_shadow_bias.x;\n    }\n    else\n    {\n        _973 = 1.5 * _624.fa_shadow_info[ci].x;\n    }\n    float2 param = _920.xy;\n    float4 param_1 = _624.fa_shadow_rect[ci];\n    float param_2 = _920.z - ((_973 * (1.0 + (0.5 * _890))) / _871);\n    float param_3 = _624.fa_shadow_info[ci].x;\n    float param_4 = _871;\n    float param_5 = _871 * 0.25;\n    float param_6 = ((_624.fa_shadow_info[ci].x * fast::min(_890, 3.0)) * 0.5) / _871;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_624.fa_shadow_cfg.z + 0.5);\n    float param_9 = _624.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _624, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _388, thread float4& gl_FragCoord, constant fa_shadows& _624, texture2d<float> fa_shadow_tex)\n{\n    if (_388.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1367 = int(_624.fa_shadow_cfg.x + 0.5);\n    if (_1367 < 1)\n    {\n        return 1.0;\n    }\n    float _1383 = dot(world - _624.fa_shadow_eye.xyz, _624.fa_shadow_fwd.xyz);\n    int param = _1367 - 1;\n    if (_1383 > fa_shadow_split_at(param, _624))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1395 = _1367 > 1;\n    bool _1402;\n    if (_1395)\n    {\n        _1402 = _1383 > _624.fa_shadow_split.x;\n    }\n    else\n    {\n        _1402 = _1395;\n    }\n    if (_1402)\n    {\n        ci = 1;\n    }\n    bool _1406 = _1367 > 2;\n    bool _1413;\n    if (_1406)\n    {\n        _1413 = _1383 > _624.fa_shadow_split.y;\n    }\n    else\n    {\n        _1413 = _1406;\n    }\n    if (_1413)\n    {\n        ci = 2;\n    }\n    bool _1417 = _1367 > 3;\n    bool _1424;\n    if (_1417)\n    {\n        _1424 = _1383 > _624.fa_shadow_split.z;\n    }\n    else\n    {\n        _1424 = _1417;\n    }\n    if (_1424)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1367)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1450 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _624, fa_shadow_tex);\n        s = _1450;\n        if (_1450 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_624.fa_shadow_cfg.y > 0.0)\n    {\n        float _1475;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1475 = fa_shadow_split_at(param_5, _624);\n        }\n        else\n        {\n            _1475 = _624.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1494 = _624.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _624) - _1475, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1505 = fast::clamp((_1383 - (fa_shadow_split_at(param_7, _624) - _1494)) / _1494, 0.0, 1.0);\n        if (_1505 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1367)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1526 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _624, fa_shadow_tex);\n                s2 = _1526;\n                if (_1526 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1505);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _388, thread float4& gl_FragCoord, constant fa_shadows& _624, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _388, gl_FragCoord, _624, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _388, thread float4& gl_FragCoord, constant fa_shadows& _624, texture2d<float> fa_shadow_tex)\n{\n    bool _1032 = _388.fa_pbr.z < 0.5;\n    bool _1040;\n    if (!_1032)\n    {\n        _1040 = _624.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _1040 = _1032;\n    }\n    if (_1040)\n    {\n        return 1.0;\n    }\n    int param = (int(_624.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _1053 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _1054 = _1053.x;\n    if (_1054 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1063 = int(_1054 + 0.5);\n    int param_1 = _1063;\n    float4 _1067 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _1063 + 1;\n    float4 _1072 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _1075 = _1067.y;\n    if (_1075 > 0.0)\n    {\n        float _1092 = 1.0 - smoothstep(0.75 * _1075, _1075, length(world - _624.fa_shadow_eye.xyz));\n        fade = _1092;\n        if (_1092 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1067.x > 1.5)\n    {\n        int param_3 = li * 4;\n        float3 _1111 = world - fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz;\n        float3 _1114 = abs(_1111);\n        float _1116 = _1114.x;\n        float _1118 = _1114.y;\n        bool _1119 = _1116 >= _1118;\n        bool _1127;\n        if (_1119)\n        {\n            _1127 = _1116 >= _1114.z;\n        }\n        else\n        {\n            _1127 = _1119;\n        }\n        int _1128;\n        if (_1127)\n        {\n            _1128 = (_1111.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1141;\n            if (_1118 >= _1114.z)\n            {\n                _1141 = (_1111.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1141 = (_1111.z > 0.0) ? 4 : 5;\n            }\n            _1128 = _1141;\n        }\n        face = _1128;\n    }\n    int _1160 = (_1063 + 2) + (face * 6);\n    int param_4 = _1160;\n    int param_5 = _1160 + 1;\n    int param_6 = _1160 + 3;\n    float4 _1174 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _1160 + 4;\n    float4 _1179 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _1160 + 5;\n    float4 _1184 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _1196 = _1184.x * fast::max(dot(_1174, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1201 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1207 = sqrt(1.0 - (_1201 * _1201));\n    float _1213 = fast::min(_1207 / fast::max(_1201, 0.20000000298023223876953125), 4.0);\n    float _1216 = _1072.y;\n    float _1218;\n    if (_1216 > 0.0)\n    {\n        _1218 = _1216;\n    }\n    else\n    {\n        _1218 = 1.5 * _1196;\n    }\n    float4 _1238 = float4(world + (n * (_1218 * _1207)), 1.0);\n    float _1242 = dot(_1174, _1238);\n    float _1245 = _1184.y;\n    if (_1242 < _1245)\n    {\n        return 1.0;\n    }\n    float2 _1260 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _1238), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _1238)) / float2(_1242);\n    float _1262 = _1260.x;\n    bool _1265 = _1262 < _1179.x;\n    bool _1274;\n    if (!_1265)\n    {\n        _1274 = _1262 > _1179.z;\n    }\n    else\n    {\n        _1274 = _1265;\n    }\n    bool _1283;\n    if (!_1274)\n    {\n        _1283 = _1260.y < _1179.y;\n    }\n    else\n    {\n        _1283 = _1274;\n    }\n    bool _1292;\n    if (!_1283)\n    {\n        _1292 = _1260.y > _1179.w;\n    }\n    else\n    {\n        _1292 = _1283;\n    }\n    if (_1292)\n    {\n        return 1.0;\n    }\n    float _1298 = _1072.x;\n    float _1300;\n    if (_1298 > 0.0)\n    {\n        _1300 = _1298;\n    }\n    else\n    {\n        _1300 = 1.5 * _1196;\n    }\n    float2 param_9 = _1260;\n    float4 param_10 = _1179;\n    float param_11 = _1242 - (_1300 * (1.0 + (0.5 * _1213)));\n    float param_12 = _1196;\n    float param_13 = 1.0;\n    float param_14 = _1184.z * 0.25;\n    float param_15 = (_1196 * fast::min(_1213, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _1245, _1184.z);\n    int param_17 = int(_1067.z + 0.5);\n    float param_18 = _1067.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _624, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _388, thread float4& gl_FragCoord, constant fa_shadows& _624, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _1696 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _2682 = _1696.direction;\n    float3 _2677 = _1696.color;\n    float _2684 = _1696.attenuation;\n    float _2679 = _1696.shadow;\n    int _2687 = _1696.type;\n    if ((_2687 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2682;\n        float _1710 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _388, gl_FragCoord, _624, fa_shadow_tex, fa_world_pos);\n        _2679 = _1710;\n        _2677 *= _1710;\n    }\n    else\n    {\n        bool _1721 = _2687 != 0;\n        bool _1727;\n        if (_1721)\n        {\n            _1727 = _2684 > 0.0;\n        }\n        else\n        {\n            _1727 = _1721;\n        }\n        if (_1727)\n        {\n            int param_4 = li;\n            float3 param_5 = world_pos;\n            float3 param_6 = gn;\n            float3 param_7 = _2682;\n            float _1739 = fa_shadow_local(param_4, param_5, param_6, param_7, fa_light_tex, fa_shadow_smp, _388, gl_FragCoord, _624, fa_shadow_tex);\n            _2679 = _1739;\n            _2677 *= _1739;\n        }\n    }\n    return LightSample{ _2682, _2677, _2684, _2679, _1696._distance, _2687 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l, constant fa_material& _1765)\n{\n    float _1759;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _1759 = 1.0;\n    }\n    else\n    {\n        _1759 = _1765.dark;\n    }\n    return (s.albedo * l.color) * _1759;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _624)\n{\n    if (_624.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1550 = int(_624.fa_shadow_cfg.x + 0.5);\n    float _1560 = dot(world - _624.fa_shadow_eye.xyz, _624.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1565 = _1550 > 0;\n    bool _1574;\n    if (_1565)\n    {\n        int param = _1550 - 1;\n        _1574 = _1560 <= fa_shadow_split_at(param, _624);\n    }\n    else\n    {\n        _1574 = _1565;\n    }\n    if (_1574)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1581 = _1550 > 1;\n        bool _1588;\n        if (_1581)\n        {\n            _1588 = _1560 > _624.fa_shadow_split.x;\n        }\n        else\n        {\n            _1588 = _1581;\n        }\n        if (_1588)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1594 = _1550 > 2;\n        bool _1601;\n        if (_1594)\n        {\n            _1601 = _1560 > _624.fa_shadow_split.y;\n        }\n        else\n        {\n            _1601 = _1594;\n        }\n        if (_1601)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1607 = _1550 > 3;\n        bool _1614;\n        if (_1607)\n        {\n            _1614 = _1560 > _624.fa_shadow_split.z;\n        }\n        else\n        {\n            _1614 = _1607;\n        }\n        if (_1614)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _388 [[buffer(1)]], constant fa_material& _1765 [[buffer(5)]], constant fa_shadows& _624 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _2531 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _2531 = -_2531;\n    }\n    float3 _2144 = fast::normalize(_388.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _388, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _2531, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2144, short(gl_FrontFacing) };\n    Surface _2152 = fa_standard_surface(param_1, _388, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _2562 = _2152.albedo;\n    float _2563 = _2152.alpha;\n    float3 _2564 = _2152.normal;\n    float _2565 = _2152.metallic;\n    float _2566 = _2152.roughness;\n    float _2567 = _2152.occlusion;\n    float3 _2568 = _2152.emission;\n    float _2569 = _2152.clearcoat;\n    float _2570 = _2152.clearcoat_roughness;\n    float3 _2571 = _2152.sheen_color;\n    float _2572 = _2152.sheen_roughness;\n    float _2573 = _2152.anisotropy;\n    float _2574 = _2152.anisotropy_rotation;\n    float _2575 = _2152.specular;\n    float _2576 = _2152.ior;\n    float3 _2577 = _2152.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _2531, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2144, short(gl_FrontFacing) };\n    Surface param_3 = _2152;\n    surface(param_2, param_3);\n    _2562 = param_3.albedo;\n    _2563 = param_3.alpha;\n    _2564 = param_3.normal;\n    _2565 = param_3.metallic;\n    _2566 = param_3.roughness;\n    _2567 = param_3.occlusion;\n    _2568 = param_3.emission;\n    _2569 = param_3.clearcoat;\n    _2570 = param_3.clearcoat_roughness;\n    _2571 = param_3.sheen_color;\n    _2572 = param_3.sheen_roughness;\n    _2573 = param_3.anisotropy;\n    _2574 = param_3.anisotropy_rotation;\n    _2575 = param_3.specular;\n    _2576 = param_3.ior;\n    _2577 = param_3.specular_color;\n    float3 result;\n    if (_388.fa_emissive.w > 0.5)\n    {\n        result = _2562;\n    }\n    else\n    {\n        float3 _2173 = _2564;\n        float3 _2174 = fast::normalize(_2173);\n        _2564 = _2174;\n        float3 param_4 = _2174;\n        float3 lit = (fa_ambient_light(param_4, _388, fa_irr_tex, fa_env_smp) * _2562) * _2567;\n        int _2193 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2193; ln++)\n        {\n            int param_5 = ln;\n            int param_6 = fa_cl_light(param_5, fa_light_tex, fa_shadow_smp, _388, fa_cl_ndir, fa_cl_slot);\n            float3 param_7 = in.fa_world_pos;\n            float3 param_8 = _2531;\n            SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _2531, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2144, short(gl_FrontFacing) };\n            Surface param_10 = Surface{ _2562, _2563, _2564, _2565, _2566, _2567, _2568, _2569, _2570, _2571, _2572, _2573, _2574, _2575, _2576, _2577 };\n            LightSample param_11 = fa_light_shadowed(param_6, param_7, param_8, fa_light_tex, fa_shadow_smp, _388, gl_FragCoord, _624, fa_shadow_tex, in.fa_world_pos);\n            lit += light(param_9, param_10, param_11, _1765);\n        }\n        result = lit;\n    }\n    float3 _2230 = result;\n    float3 _2231 = _2230 + _2568;\n    result = _2231;\n    float3 param_12 = _2231;\n    float3 param_13 = in.fa_world_pos;\n    result = fa_shadow_debug(param_12, param_13, _624);\n    bool _2240 = _388.fa_fog.w > 0.0;\n    bool _2247;\n    if (!_2240)\n    {\n        _2247 = _388.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _2247 = _2240;\n    }\n    if (_2247)\n    {\n        float3 _2256 = in.fa_world_pos - _388.fa_camera_pos.xyz;\n        float _2262 = dot(_2256, _388.fa_fog_c.xyz);\n        bool _2266 = _388.fa_fog_c.w > 0.5;\n        float _2267;\n        if (_2266)\n        {\n            _2267 = _2262;\n        }\n        else\n        {\n            _2267 = length(_2256);\n        }\n        float _2279 = _2267 - _388.fa_fog_b.x;\n        if (_2279 > 0.0)\n        {\n            float _2288 = _388.fa_fog.w * _2279;\n            float tau = _2288 * _2288;\n            if (_388.fa_fog_b.y > 0.0)\n            {\n                float _2304;\n                if (_2266)\n                {\n                    _2304 = in.fa_world_pos.y - (_388.fa_fog_c.y * _2262);\n                }\n                else\n                {\n                    _2304 = _388.fa_camera_pos.y;\n                }\n                float _2325 = mix(_2304, in.fa_world_pos.y, fast::clamp(_388.fa_fog_b.x / _2267, 0.0, 1.0));\n                float _2329 = in.fa_world_pos.y - _2325;\n                float _2334 = _2325 - _388.fa_fog_b.z;\n                float _2339 = in.fa_world_pos.y - _388.fa_fog_b.z;\n                bool _2342 = _2334 <= 0.0;\n                bool _2343 = !_2342;\n                bool _2349;\n                if (_2343)\n                {\n                    _2349 = _388.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2349 = _2342;\n                }\n                float _2350;\n                if (_2349)\n                {\n                    _2350 = _388.fa_fog_b.y;\n                }\n                else\n                {\n                    _2350 = _388.fa_fog_b.y * exp(-fast::min(_388.fa_fog_b.w * _2334, 80.0));\n                }\n                bool _2377;\n                if (_2343)\n                {\n                    _2377 = _388.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2377 = _2342;\n                }\n                float _2378;\n                if (_2377)\n                {\n                    _2378 = _388.fa_fog_b.y * _2334;\n                }\n                else\n                {\n                    _2378 = (_388.fa_fog_b.y * (1.0 - exp(-fast::min(_388.fa_fog_b.w * _2334, 80.0)))) / _388.fa_fog_b.w;\n                }\n                bool _2403 = _2339 <= 0.0;\n                bool _2410;\n                if (!_2403)\n                {\n                    _2410 = _388.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2410 = _2403;\n                }\n                float _2411;\n                if (_2410)\n                {\n                    _2411 = _388.fa_fog_b.y * _2339;\n                }\n                else\n                {\n                    _2411 = (_388.fa_fog_b.y * (1.0 - exp(-fast::min(_388.fa_fog_b.w * _2339, 80.0)))) / _388.fa_fog_b.w;\n                }\n                float _2438;\n                if (abs(_2329) < 0.001000000047497451305389404296875)\n                {\n                    _2438 = _2350;\n                }\n                else\n                {\n                    _2438 = (_2411 - _2378) / _2329;\n                }\n                tau += (_2279 * fast::max(_2438, 0.0));\n            }\n            result = mix(result, _388.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _2563);\n    return out;\n}\n\n",
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
            "inst_name": "_388",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_624",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1765",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
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
