{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "738bdbaa5d236ca82c68b48e7af94b35c54ba5d6311eabf2bcbbc814ba3d221c",
  "slang": "metal_macos",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_268, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nconstant spvUnsafeArray<float, 63> _1863 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _759 = _286.fa_cl_info.x < 0.0;\n    bool _766;\n    if (!_759)\n    {\n        _766 = _286.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _766 = _759;\n    }\n    bool _774;\n    if (!_766)\n    {\n        _774 = _286.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _774 = _766;\n    }\n    bool _781;\n    if (!_774)\n    {\n        _781 = _286.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _781 = _774;\n    }\n    bool _788;\n    if (!_781)\n    {\n        _788 = _286.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _788 = _781;\n    }\n    if (_788)\n    {\n        return int2(0);\n    }\n    float4 _798 = float4(world_pos, 1.0);\n    float _805 = dot(_286.fa_cl_vpw, _798);\n    if (!(_805 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _827 = float2(dot(_286.fa_cl_vpx, _798), dot(_286.fa_cl_vpy, _798)) / float2(_805);\n    int _831 = int(_286.fa_cl_grid.x);\n    int _835 = int(_286.fa_cl_grid.y);\n    int param = (int(_286.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_286.fa_cl_fwd.xyz, world_pos) + _286.fa_cl_fwd.w, _286.fa_cl_grid.w) / _286.fa_cl_grid.w) * _286.fa_cl_grid.z)), 0, int(_286.fa_cl_info.y) - 1) * _835) + clamp(int(floor(((_827.y * 0.5) + 0.5) * _286.fa_cl_grid.y)), 0, _835 - 1)) * _831)) + clamp(int(floor(((_827.x * 0.5) + 0.5) * _286.fa_cl_grid.x)), 0, _831 - 1);\n    float4 _906 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_906.x), int(_906.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_286.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2411 = fa_cluster_lookup(param, _286, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _2411.x;\n    fa_cl_local = _2411.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2658 = fa_linear_to_srgb(param);\n        c = _2658;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2666 = fa_srgb_to_linear(param_1);\n            c = _2666;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _218;\n    if (bool(i.front_facing))\n    {\n        _218 = i.world_normal;\n    }\n    else\n    {\n        _218 = -i.world_normal;\n    }\n    float3 _242 = fast::normalize(i.world_tangent.xyz - (_218 * dot(_218, i.world_tangent.xyz)));\n    float3 _270 = fast::normalize(((_242 * m.x) + ((cross(_218, _242) * i.world_tangent.w) * m.y)) + (_218 * m.z));\n    float3 _273;\n    if (bool(i.front_facing))\n    {\n        _273 = _270;\n    }\n    else\n    {\n        _273 = -_270;\n    }\n    return _273;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _286, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _286.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2697 = fa_tex_fix(param_2, param_3);\n    float4 _3619 = base_t;\n    _3619.x = _2697.x;\n    _3619.y = _2697.y;\n    _3619.z = _2697.z;\n    base_t = _3619;\n    float4 _2711 = (_3619 * _286.fa_base_color) * i.vertex_color;\n    float3 _3543 = i.world_normal;\n    if (_286.fa_maps.z > 0.5)\n    {\n        float param_4 = _286.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2743 = fa_tex_fix(param_6, param_7);\n        float3 _2747 = (_2743 * 2.0) - float3(1.0);\n        float2 _2752 = _2747.xy * _286.fa_maps.x;\n        float3 _3627 = _2747;\n        _3627.x = _2752.x;\n        _3627.y = _2752.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3627;\n        _3543 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _286.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2780 = fa_tex_fix(param_12, param_13);\n    float4 _3630 = mrt;\n    _3630.x = _2780.x;\n    _3630.y = _2780.y;\n    _3630.z = _2780.z;\n    mrt = _3630;\n    float4 _2808 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _286.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2808.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2820 = fa_tex_fix(param_16, param_17);\n    float param_18 = _286.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2850 = fa_tex_fix(param_20, param_21);\n    float _3548 = _286.fa_layers_a.x;\n    float _3549 = _286.fa_layers_a.y;\n    float _3552 = _286.fa_layers_a.z;\n    float _3551 = _286.fa_layers_b.w;\n    float _3554 = _286.fa_layers_c.x;\n    if (_286.fa_layers_c.z > 0.5)\n    {\n        if (mod(_286.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3548 *= _2820.y;\n            _3549 *= _2820.z;\n            _3551 *= _2808.w;\n        }\n        if (_286.fa_layers_c.z > 1.5)\n        {\n            _3552 *= mrt.x;\n            _3554 *= mrt.w;\n        }\n    }\n    return Surface{ _2711.xyz, _2711.w, _3543, fast::clamp(_286.fa_pbr.x * _2780.z, 0.0, 1.0), fast::clamp(_286.fa_pbr.y * _2780.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_286.fa_maps.y * (_2820.x - 1.0)), _286.fa_emissive.xyz + (_286.fa_model_emissive.xyz * _2850), _3548, _3549, _286.fa_layers_b.xyz, _3551, _3552, _286.fa_layers_a.w, _3554, _286.fa_layers_c.y, _286.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(thread int& fa_cl_ndir, thread int& fa_cl_local)\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_286.fa_cl_info.x) + int(_286.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _286, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _286)\n{\n    return li * ((_286.fa_counts.y > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _367 = dot(d, right);\n    float _371 = dot(d, up);\n    float _382;\n    if (((_367 * _367) + (_371 * _371)) > 1.0000000133514319600180897396058e-10)\n    {\n        _382 = precise::atan2(_371, _367) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _382 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_382 - floor(_382)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _415 = fa_light_base(param, _286);\n    bool _419 = _286.fa_counts.y > 4.5;\n    int param_1 = _415;\n    float4 _423 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _415 + 1;\n    float4 _428 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _431 = _428.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _443 = _419 && (_431 > 2.5);\n    fa_light_is_area = _443;\n    bool _446 = _431 < 0.5;\n    float3 l;\n    if (_446)\n    {\n        l = fast::normalize(_423.xyz);\n        if (_419)\n        {\n            int param_3 = _415 + 6;\n            float4 _460 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_460.z > 0.5)\n            {\n                int param_4 = _415 + 4;\n                float4 _470 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _415 + 5;\n                float4 _476 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _460.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _470.xyz) * _470.w, (-dot(world_pos, _476.xyz)) * _476.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _508 = _423.xyz - world_pos;\n        float _510 = length(_508);\n        dist = _510;\n        l = _508 / float3(fast::max(_510, 9.9999997473787516355514526367188e-05));\n        float reach = _510;\n        if (_443)\n        {\n            int param_8 = _415 + 7;\n            reach = fast::max(dist - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n        }\n        float _542 = reach / fast::max(_423.w, 0.001000000047497451305389404296875);\n        float _548 = fast::clamp(1.0 - (_542 * _542), 0.0, 1.0);\n        atten = _548 * _548;\n        bool _556 = _431 < 2.5;\n        if ((_431 > 1.5) && _556)\n        {\n            int param_9 = _415 + 2;\n            float4 _564 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            float _574 = _564.w;\n            int param_10 = _415 + 3;\n            float4 _580 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            float _581 = _580.x;\n            float cos_inner = _581;\n            if (_581 > 1.5)\n            {\n                cos_inner = mix(_574, 1.0, 0.25);\n            }\n            atten *= smoothstep(_574, cos_inner, dot(-l, fast::normalize(_564.xyz)));\n        }\n        if (_419 && _556)\n        {\n            int param_11 = _415 + 6;\n            float4 _605 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            int param_12 = _415 + 7;\n            float4 _610 = fa_light_texel(param_12, fa_light_tex, fa_shadow_smp);\n            bool _613 = _605.z > 0.5;\n            bool _620;\n            if (!_613)\n            {\n                _620 = _610.z > 0.5;\n            }\n            else\n            {\n                _620 = _613;\n            }\n            if (_620)\n            {\n                int param_13 = _415 + 2;\n                float4 _627 = fa_light_texel(param_13, fa_light_tex, fa_shadow_smp);\n                float3 _631 = fast::normalize(_627.xyz);\n                int param_14 = _415 + 4;\n                float4 _636 = fa_light_texel(param_14, fa_light_tex, fa_shadow_smp);\n                int param_15 = _415 + 5;\n                float4 _641 = fa_light_texel(param_15, fa_light_tex, fa_shadow_smp);\n                if (_613)\n                {\n                    float3 _649 = -_508;\n                    float _656 = _627.w;\n                    float _672 = 0.5 / fast::max(dot(_649, _631) * (sqrt(fast::max(1.0 - (_656 * _656), 0.0)) / fast::max(_656, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    float2 param_16 = _605.xy;\n                    float2 param_17 = float2(0.5 + (dot(_649, _636.xyz) * _672), 0.5 - (dot(_649, _641.xyz) * _672));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17, fa_light_atlas, fa_env_smp);\n                }\n                if (_610.z > 0.5)\n                {\n                    float2 param_18 = _610.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _631;\n                    float3 param_21 = _636.xyz;\n                    float3 param_22 = _641.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22, fa_light_atlas, fa_env_smp);\n                }\n            }\n        }\n    }\n    float3 _3381 = _428.xyz * atten;\n    if (_419)\n    {\n        _3381 *= fa_light_tint;\n    }\n    int _741;\n    if (_446)\n    {\n        _741 = 0;\n    }\n    else\n    {\n        _741 = ((_431 > 1.5) && (_431 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _3381, atten, 1.0, dist, _741 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    bool _2496 = n < 0;\n    bool _2503;\n    if (!_2496)\n    {\n        _2503 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _2503 = _2496;\n    }\n    if (_2503)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, _286, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    LightSample _2515 = fa_light_sample(param_1, param_2, _286, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    return _2515;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _990)\n{\n    float _980;\n    if (i == 0)\n    {\n        _980 = _990.fa_shadow_split.x;\n    }\n    else\n    {\n        float _996;\n        if (i == 1)\n        {\n            _996 = _990.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1004;\n            if (i == 2)\n            {\n                _1004 = _990.fa_shadow_split.z;\n            }\n            else\n            {\n                _1004 = _990.fa_shadow_split.w;\n            }\n            _996 = _1004;\n        }\n        _980 = _996;\n    }\n    return _980;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _968 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_968), sin(_968)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _990, texture2d<float> fa_shadow_tex)\n{\n    float _1042 = fast::max(_990.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1047 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1053 = sqrt(1.0 - (_1047 * _1047));\n    float _1061 = fast::min(_1053 / fast::max(_1047, 0.20000000298023223876953125), 4.0);\n    float _1066;\n    if (_990.fa_shadow_bias.y > 0.0)\n    {\n        _1066 = _990.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1066 = 1.5 * _990.fa_shadow_info[ci].x;\n    }\n    float4 _1091 = _990.fa_shadow_mat[ci] * float4(world + (n * (_1066 * _1053)), 1.0);\n    float _1098 = _1091.x;\n    bool _1101 = _1098 < _990.fa_shadow_rect[ci].x;\n    bool _1110;\n    if (!_1101)\n    {\n        _1110 = _1098 > _990.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1110 = _1101;\n    }\n    bool _1119;\n    if (!_1110)\n    {\n        _1119 = _1091.y < _990.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1119 = _1110;\n    }\n    bool _1128;\n    if (!_1119)\n    {\n        _1128 = _1091.y > _990.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1128 = _1119;\n    }\n    bool _1135;\n    if (!_1128)\n    {\n        _1135 = _1091.z > 1.0;\n    }\n    else\n    {\n        _1135 = _1128;\n    }\n    if (_1135)\n    {\n        return -1.0;\n    }\n    float _1143;\n    if (_990.fa_shadow_bias.x > 0.0)\n    {\n        _1143 = _990.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1143 = 1.5 * _990.fa_shadow_info[ci].x;\n    }\n    float _1162 = _1091.z - ((_1143 * (1.0 + (0.5 * _1061))) / _1042);\n    float _1171 = ((_990.fa_shadow_info[ci].x * fast::min(_1061, 3.0)) * 0.5) / _1042;\n    int _1180 = int(_990.fa_shadow_cfg.z + 0.5);\n    if (_1180 == 1)\n    {\n        float2 param = _1091.xy;\n        float4 param_1 = _990.fa_shadow_rect[ci];\n        float _1191 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1162 <= _1191);\n    }\n    float _1198 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1201 = _1180 == 2;\n    if (_1201)\n    {\n        float _1215 = fast::clamp(((_990.fa_shadow_cfg.w * _1042) * 0.25) / _990.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1198;\n            float2 _1234 = fa_shadow_vogel(param_2, param_3, param_4) * _1215;\n            float2 param_5 = _1091.xy + (_1234 * _990.fa_shadow_bias.zw);\n            float4 param_6 = _990.fa_shadow_rect[ci];\n            float _1245 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1245 < (_1162 - (length(_1234) * _1171)))\n            {\n                sum += _1245;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1162 - (sum / cnt), 0.0) * _1042) * _990.fa_shadow_cfg.w) / _990.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1289 = _1201 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1289; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1289;\n        float param_9 = _1198;\n        float2 _1308 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1091.xy + (_1308 * _990.fa_shadow_bias.zw);\n        float4 param_11 = _990.fa_shadow_rect[ci];\n        float _1319 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1162 - (length(_1308) * _1171)) <= _1319);\n    }\n    return lit / float(_1289);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _286, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _990, texture2d<float> fa_shadow_tex)\n{\n    if (_286.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1349 = int(_990.fa_shadow_cfg.x + 0.5);\n    if (_1349 < 1)\n    {\n        return 1.0;\n    }\n    float _1364 = dot(world - _990.fa_shadow_eye.xyz, _990.fa_shadow_fwd.xyz);\n    int param = _1349 - 1;\n    if (_1364 > fa_shadow_split_at(param, _990))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1376 = _1349 > 1;\n    bool _1383;\n    if (_1376)\n    {\n        _1383 = _1364 > _990.fa_shadow_split.x;\n    }\n    else\n    {\n        _1383 = _1376;\n    }\n    if (_1383)\n    {\n        ci = 1;\n    }\n    bool _1387 = _1349 > 2;\n    bool _1394;\n    if (_1387)\n    {\n        _1394 = _1364 > _990.fa_shadow_split.y;\n    }\n    else\n    {\n        _1394 = _1387;\n    }\n    if (_1394)\n    {\n        ci = 2;\n    }\n    bool _1398 = _1349 > 3;\n    bool _1405;\n    if (_1398)\n    {\n        _1405 = _1364 > _990.fa_shadow_split.z;\n    }\n    else\n    {\n        _1405 = _1398;\n    }\n    if (_1405)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1349)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1431 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _990, fa_shadow_tex);\n        s = _1431;\n        if (_1431 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_990.fa_shadow_cfg.y > 0.0)\n    {\n        float _1456;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1456 = fa_shadow_split_at(param_5, _990);\n        }\n        else\n        {\n            _1456 = _990.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1475 = _990.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _990) - _1456, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1486 = fast::clamp((_1364 - (fa_shadow_split_at(param_7, _990) - _1475)) / _1475, 0.0, 1.0);\n        if (_1486 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1349)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1507 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _990, fa_shadow_tex);\n                s2 = _1507;\n                if (_1507 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1486);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _286, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _990, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _286, fa_shadow_smp, gl_FragCoord, _990, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _990, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2439 = fa_light_sample(param, param_1, _286, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _3514 = _2439.color;\n    float _3516 = _2439.shadow;\n    if ((_2439.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2439.direction;\n        float _2453 = fa_shadow_factor(param_2, param_3, _286, fa_shadow_smp, gl_FragCoord, _990, fa_shadow_tex, fa_world_pos);\n        _3516 = _2453;\n        _3514 *= _2453;\n    }\n    return LightSample{ _2439.direction, _3514, _2439.attenuation, _3516, _2439._distance, _2439.type };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _990, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    bool _2470 = n < 0;\n    bool _2477;\n    if (!_2470)\n    {\n        _2477 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _2477 = _2470;\n    }\n    if (_2477)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, _286, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _2492 = fa_light_shadowed(param_1, param_2, param_3, _286, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _990, fa_shadow_tex, fa_world_pos);\n    return _2492;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1788 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1796 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1799 = int(_1788);\n    int _1802 = int(_1796);\n    float _1812 = _1796 - float(_1802);\n    int _1868 = (_1799 * 9) + _1802;\n    int _1888 = ((_1799 + 1) * 9) + _1802;\n    return mix(mix(_1863[_1868], _1863[_1868 + 1], _1812), mix(_1863[_1888], _1863[_1888 + 1], _1812), _1788 - float(_1799));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _3393 = false;\n    float _3394 = 1.0;\n    float _3395 = 1.0;\n    float _3396 = 1.0;\n    float _3397 = 0.0;\n    float _3398 = 0.0;\n    float _3399 = 0.0;\n    float _3400 = 0.0;\n    float _3402 = 1.0;\n    bool _3403 = false;\n    float3 _3404 = float3(0.0);\n    float _3405 = 1.0;\n    float _3406 = 1.0;\n    float _3407 = 1.0;\n    float _3408 = 0.0;\n    float _3409 = 0.0;\n    float3 _3410 = float3(1.0, 0.0, 0.0);\n    float3 _3411 = float3(0.0, 0.0, 1.0);\n    float _3412 = 1.0;\n    float _3413 = 1.0;\n    float _1942 = fast::clamp(s.specular, 0.0, 1.0);\n    float _1946 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _1951 = (_1942 != 1.0) || (_1946 != 1.5);\n    bool _1960;\n    if (!_1951)\n    {\n        _1960 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _1960 = _1951;\n    }\n    if (_1960)\n    {\n        float _1968 = (_1946 - 1.0) / (_1946 + 1.0);\n        f0 = mix(fast::min(float3(_1968 * _1968) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _1942, s.albedo, float3(metallic));\n        _3394 = mix(_1942, 1.0, metallic);\n        _3393 = true;\n    }\n    float _1996 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_1996 > 0.0)\n    {\n        float _2004 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3397 = _1996;\n        _3398 = _2004;\n        float _2011 = _2004 * _2004;\n        _3399 = _2011;\n        _3400 = _2011 * _2011;\n        float _2023 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3402 = _2023;\n        _3395 = 1.0 - (_1996 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2023, 0.0, 1.0), 5.0))));\n        _3393 = true;\n    }\n    float3 _2043 = fast::max(s.sheen_color, float3(0.0));\n    float _2052 = fast::max(_2043.x, fast::max(_2043.y, _2043.z));\n    if (_2052 > 0.0)\n    {\n        float _2060 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3403 = true;\n        _3404 = _2043;\n        _3405 = _2060;\n        _3406 = _2060 * _2060;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2060;\n        float _2077 = fa_sheen_albedo(param, param_1);\n        _3408 = _2077;\n        _3407 = 1.0 - fast::min(_2052 * _2077, 1.0);\n        _3393 = true;\n    }\n    _3396 = _3395 * _3407;\n    float _2096 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2096 != 0.0)\n    {\n        float3 _2111 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2111;\n        if (dot(_2111, _2111) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2129 = t;\n        float3 _2130 = fast::normalize(_2129);\n        t = _2130;\n        float3 _2155 = fast::normalize((_2130 * cos(s.anisotropy_rotation)) + ((cross(n, _2130) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3410 = _2155;\n        _3411 = cross(n, _2155);\n        float _2165 = roughness * roughness;\n        float _2171 = mix(_2165, 1.0, _2096 * _2096);\n        bool _2173 = _2096 > 0.0;\n        _3412 = _2173 ? _2171 : _2165;\n        _3413 = _2173 ? _2165 : _2171;\n        _3409 = _2096;\n        _3393 = true;\n    }\n    return FaLayers{ short(_3393), _3394, _3395, _3396, _3397, _3398, _3399, _3400, i.world_normal, _3402, short(_3403), _3404, _3405, _3406, _3407, _3408, _3409, _3410, _3411, _3412, _3413 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1720 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1723 = _1720.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1723 * _1723, exp2((-9.27999973297119140625) * ndv)) * _1723) + _1720.y)) + _1720.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _286, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_286.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _286.fa_env_horizon.w)).xyz;\n    }\n    float _1643 = rough * rough;\n    float _1673 = 0.60000002384185791015625 * _1643;\n    return mix(mix(_286.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_286.fa_env_horizon.xyz, _286.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1643)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1673, 0.0500000007450580596923828125 + _1673, d.y))), ((_286.fa_env_sky.xyz + _286.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1643 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _286, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2206;\n        if (L.aniso >= 0.0)\n        {\n            _2206 = L.b;\n        }\n        else\n        {\n            _2206 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2206, v), _2206), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2239 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _286, fa_env_smp, fa_env_tex) * ((f0 * _2239.x) + (float3(L.f90) * _2239.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _286, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2294 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _286, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _2294.x) + _2294.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _286, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1762 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _286, fa_env_smp, fa_env_tex) * ((f0 * _1762.x) + float3(_1762.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _286, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float _2333 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _2337 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _2344 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_2333));\n    float3 f0 = _2344;\n    float3 _2348 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2348;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2333;\n    float param_5 = _2337;\n    float3 param_6 = _2344;\n    FaLayers _2365 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2365.on)\n    {\n        FaLayers param_7 = _2365;\n        float3 param_8 = _2348;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2337;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _286, fa_env_smp, fa_env_tex) * s.occlusion;\n    }\n    float3 param_12 = _2348;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2337;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _286, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _990, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texturecube<float> fa_env_tex, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, constant fa_material& _2586)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(fa_cl_ndir, fa_cl_local); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _2535 = fa_light_unshadowed(param, param_1, _286, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n        float _2543 = dot(_2535.color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_2543 > bestPower)\n        {\n            bestPower = _2543;\n            best = n;\n        }\n    }\n    float3 lit = (_286.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2572 = fa_light(param_2, param_3, _286, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _990, fa_shadow_tex, fa_world_pos, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n        float _2580;\n        if (dot(s.normal, _2572.direction) > 0.5)\n        {\n            _2580 = 1.0;\n        }\n        else\n        {\n            _2580 = _2586.dark;\n        }\n        lit += ((s.albedo * _2572.color) * _2580);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _286, fa_env_smp, fa_env_tex) * _2586.skyAmount);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _990)\n{\n    if (_990.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1531 = int(_990.fa_shadow_cfg.x + 0.5);\n    float _1541 = dot(world - _990.fa_shadow_eye.xyz, _990.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1546 = _1531 > 0;\n    bool _1555;\n    if (_1546)\n    {\n        int param = _1531 - 1;\n        _1555 = _1541 <= fa_shadow_split_at(param, _990);\n    }\n    else\n    {\n        _1555 = _1546;\n    }\n    if (_1555)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1562 = _1531 > 1;\n        bool _1569;\n        if (_1562)\n        {\n            _1569 = _1541 > _990.fa_shadow_split.x;\n        }\n        else\n        {\n            _1569 = _1562;\n        }\n        if (_1569)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1575 = _1531 > 2;\n        bool _1582;\n        if (_1575)\n        {\n            _1582 = _1541 > _990.fa_shadow_split.y;\n        }\n        else\n        {\n            _1582 = _1575;\n        }\n        if (_1582)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1588 = _1531 > 3;\n        bool _1595;\n        if (_1588)\n        {\n            _1595 = _1541 > _990.fa_shadow_split.z;\n        }\n        else\n        {\n            _1595 = _1588;\n        }\n        if (_1595)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _286 [[buffer(1)]], constant fa_material& _2586 [[buffer(5)]], constant fa_shadows& _990 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3267 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3267 = -_3267;\n    }\n    float3 _2971 = fast::normalize(_286.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _286, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3267, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2971, short(gl_FrontFacing) };\n    Surface _2979 = fa_standard_surface(param_1, _286, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3298 = _2979.albedo;\n    float _3299 = _2979.alpha;\n    float3 _3300 = _2979.normal;\n    float _3301 = _2979.metallic;\n    float _3302 = _2979.roughness;\n    float _3303 = _2979.occlusion;\n    float3 _3304 = _2979.emission;\n    float _3305 = _2979.clearcoat;\n    float _3306 = _2979.clearcoat_roughness;\n    float3 _3307 = _2979.sheen_color;\n    float _3308 = _2979.sheen_roughness;\n    float _3309 = _2979.anisotropy;\n    float _3310 = _2979.anisotropy_rotation;\n    float _3311 = _2979.specular;\n    float _3312 = _2979.ior;\n    float3 _3313 = _2979.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3267, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2971, short(gl_FrontFacing) };\n    Surface param_3 = _2979;\n    surface(param_2, param_3);\n    _3298 = param_3.albedo;\n    _3299 = param_3.alpha;\n    _3300 = param_3.normal;\n    _3301 = param_3.metallic;\n    _3302 = param_3.roughness;\n    _3303 = param_3.occlusion;\n    _3304 = param_3.emission;\n    _3305 = param_3.clearcoat;\n    _3306 = param_3.clearcoat_roughness;\n    _3307 = param_3.sheen_color;\n    _3308 = param_3.sheen_roughness;\n    _3309 = param_3.anisotropy;\n    _3310 = param_3.anisotropy_rotation;\n    _3311 = param_3.specular;\n    _3312 = param_3.ior;\n    _3313 = param_3.specular_color;\n    float3 result;\n    if (_286.fa_emissive.w > 0.5)\n    {\n        result = _3298;\n    }\n    else\n    {\n        float3 _3000 = _3300;\n        float3 _3001 = fast::normalize(_3000);\n        _3300 = _3001;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _3267, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2971, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _3298, _3299, _3001, _3301, _3302, _3303, _3304, _3305, _3306, _3307, _3308, _3309, _3310, _3311, _3312, _3313 };\n        float3 _3012 = lighting(param_4, param_5, _286, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _990, fa_shadow_tex, in.fa_world_pos, fa_env_tex, fa_cl_ndir, fa_cl_slot, fa_cl_local, _2586);\n        result = _3012;\n    }\n    float3 _3016 = result;\n    float3 _3017 = _3016 + _3304;\n    result = _3017;\n    float3 param_6 = _3017;\n    float3 param_7 = in.fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7, _990);\n    bool _3026 = _286.fa_fog.w > 0.0;\n    bool _3033;\n    if (!_3026)\n    {\n        _3033 = _286.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3033 = _3026;\n    }\n    if (_3033)\n    {\n        float3 _3042 = in.fa_world_pos - _286.fa_camera_pos.xyz;\n        float _3048 = dot(_3042, _286.fa_fog_c.xyz);\n        bool _3052 = _286.fa_fog_c.w > 0.5;\n        float _3053;\n        if (_3052)\n        {\n            _3053 = _3048;\n        }\n        else\n        {\n            _3053 = length(_3042);\n        }\n        float _3065 = _3053 - _286.fa_fog_b.x;\n        if (_3065 > 0.0)\n        {\n            float _3074 = _286.fa_fog.w * _3065;\n            float tau = _3074 * _3074;\n            if (_286.fa_fog_b.y > 0.0)\n            {\n                float _3090;\n                if (_3052)\n                {\n                    _3090 = in.fa_world_pos.y - (_286.fa_fog_c.y * _3048);\n                }\n                else\n                {\n                    _3090 = _286.fa_camera_pos.y;\n                }\n                float _3111 = mix(_3090, in.fa_world_pos.y, fast::clamp(_286.fa_fog_b.x / _3053, 0.0, 1.0));\n                float _3115 = in.fa_world_pos.y - _3111;\n                float _3120 = _3111 - _286.fa_fog_b.z;\n                float _3125 = in.fa_world_pos.y - _286.fa_fog_b.z;\n                bool _3128 = _3120 <= 0.0;\n                bool _3129 = !_3128;\n                bool _3135;\n                if (_3129)\n                {\n                    _3135 = _286.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3135 = _3128;\n                }\n                float _3136;\n                if (_3135)\n                {\n                    _3136 = _286.fa_fog_b.y;\n                }\n                else\n                {\n                    _3136 = _286.fa_fog_b.y * exp(-fast::min(_286.fa_fog_b.w * _3120, 80.0));\n                }\n                bool _3163;\n                if (_3129)\n                {\n                    _3163 = _286.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3163 = _3128;\n                }\n                float _3164;\n                if (_3163)\n                {\n                    _3164 = _286.fa_fog_b.y * _3120;\n                }\n                else\n                {\n                    _3164 = (_286.fa_fog_b.y * (1.0 - exp(-fast::min(_286.fa_fog_b.w * _3120, 80.0)))) / _286.fa_fog_b.w;\n                }\n                bool _3189 = _3125 <= 0.0;\n                bool _3196;\n                if (!_3189)\n                {\n                    _3196 = _286.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3196 = _3189;\n                }\n                float _3197;\n                if (_3196)\n                {\n                    _3197 = _286.fa_fog_b.y * _3125;\n                }\n                else\n                {\n                    _3197 = (_286.fa_fog_b.y * (1.0 - exp(-fast::min(_286.fa_fog_b.w * _3125, 80.0)))) / _286.fa_fog_b.w;\n                }\n                float _3224;\n                if (abs(_3115) < 0.001000000047497451305389404296875)\n                {\n                    _3224 = _3136;\n                }\n                else\n                {\n                    _3224 = (_3197 - _3164) / _3115;\n                }\n                tau += (_3065 * fast::max(_3224, 0.0));\n            }\n            result = mix(result, _286.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3299);\n    return out;\n}\n\n",
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
            "inst_name": "_286",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_990",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2586",
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
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
          },
          {
            "slot": 8,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_389, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float skyAmount;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nconstant spvUnsafeArray<float, 63> _1863 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _759 = _286.fa_cl_info.x < 0.0;\n    bool _766;\n    if (!_759)\n    {\n        _766 = _286.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _766 = _759;\n    }\n    bool _774;\n    if (!_766)\n    {\n        _774 = _286.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _774 = _766;\n    }\n    bool _781;\n    if (!_774)\n    {\n        _781 = _286.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _781 = _774;\n    }\n    bool _788;\n    if (!_781)\n    {\n        _788 = _286.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _788 = _781;\n    }\n    if (_788)\n    {\n        return int2(0);\n    }\n    float4 _798 = float4(world_pos, 1.0);\n    float _805 = dot(_286.fa_cl_vpw, _798);\n    if (!(_805 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _827 = float2(dot(_286.fa_cl_vpx, _798), dot(_286.fa_cl_vpy, _798)) / float2(_805);\n    int _831 = int(_286.fa_cl_grid.x);\n    int _835 = int(_286.fa_cl_grid.y);\n    int param = (int(_286.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_286.fa_cl_fwd.xyz, world_pos) + _286.fa_cl_fwd.w, _286.fa_cl_grid.w) / _286.fa_cl_grid.w) * _286.fa_cl_grid.z)), 0, int(_286.fa_cl_info.y) - 1) * _835) + clamp(int(floor(((_827.y * 0.5) + 0.5) * _286.fa_cl_grid.y)), 0, _835 - 1)) * _831)) + clamp(int(floor(((_827.x * 0.5) + 0.5) * _286.fa_cl_grid.x)), 0, _831 - 1);\n    float4 _906 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_906.x), int(_906.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_286.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2411 = fa_cluster_lookup(param, _286, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _2411.x;\n    fa_cl_local = _2411.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2658 = fa_linear_to_srgb(param);\n        c = _2658;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2666 = fa_srgb_to_linear(param_1);\n            c = _2666;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _218;\n    if (bool(i.front_facing))\n    {\n        _218 = i.world_normal;\n    }\n    else\n    {\n        _218 = -i.world_normal;\n    }\n    float3 _242 = fast::normalize(i.world_tangent.xyz - (_218 * dot(_218, i.world_tangent.xyz)));\n    float3 _270 = fast::normalize(((_242 * m.x) + ((cross(_218, _242) * i.world_tangent.w) * m.y)) + (_218 * m.z));\n    float3 _273;\n    if (bool(i.front_facing))\n    {\n        _273 = _270;\n    }\n    else\n    {\n        _273 = -_270;\n    }\n    return _273;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _286, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _286.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2697 = fa_tex_fix(param_2, param_3);\n    float4 _3619 = base_t;\n    _3619.x = _2697.x;\n    _3619.y = _2697.y;\n    _3619.z = _2697.z;\n    base_t = _3619;\n    float4 _2711 = (_3619 * _286.fa_base_color) * i.vertex_color;\n    float3 _3543 = i.world_normal;\n    if (_286.fa_maps.z > 0.5)\n    {\n        float param_4 = _286.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2743 = fa_tex_fix(param_6, param_7);\n        float3 _2747 = (_2743 * 2.0) - float3(1.0);\n        float2 _2752 = _2747.xy * _286.fa_maps.x;\n        float3 _3627 = _2747;\n        _3627.x = _2752.x;\n        _3627.y = _2752.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3627;\n        _3543 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _286.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2780 = fa_tex_fix(param_12, param_13);\n    float4 _3630 = mrt;\n    _3630.x = _2780.x;\n    _3630.y = _2780.y;\n    _3630.z = _2780.z;\n    mrt = _3630;\n    float4 _2808 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _286.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2808.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2820 = fa_tex_fix(param_16, param_17);\n    float param_18 = _286.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2850 = fa_tex_fix(param_20, param_21);\n    float _3548 = _286.fa_layers_a.x;\n    float _3549 = _286.fa_layers_a.y;\n    float _3552 = _286.fa_layers_a.z;\n    float _3551 = _286.fa_layers_b.w;\n    float _3554 = _286.fa_layers_c.x;\n    if (_286.fa_layers_c.z > 0.5)\n    {\n        if (mod(_286.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3548 *= _2820.y;\n            _3549 *= _2820.z;\n            _3551 *= _2808.w;\n        }\n        if (_286.fa_layers_c.z > 1.5)\n        {\n            _3552 *= mrt.x;\n            _3554 *= mrt.w;\n        }\n    }\n    return Surface{ _2711.xyz, _2711.w, _3543, fast::clamp(_286.fa_pbr.x * _2780.z, 0.0, 1.0), fast::clamp(_286.fa_pbr.y * _2780.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_286.fa_maps.y * (_2820.x - 1.0)), _286.fa_emissive.xyz + (_286.fa_model_emissive.xyz * _2850), _3548, _3549, _286.fa_layers_b.xyz, _3551, _3552, _286.fa_layers_a.w, _3554, _286.fa_layers_c.y, _286.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(thread int& fa_cl_ndir, thread int& fa_cl_local)\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_no_light()\n{\n    return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, 0 };\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_286.fa_cl_info.x) + int(_286.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _286, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _286)\n{\n    return li * ((_286.fa_counts.y > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _367 = dot(d, right);\n    float _371 = dot(d, up);\n    float _382;\n    if (((_367 * _367) + (_371 * _371)) > 1.0000000133514319600180897396058e-10)\n    {\n        _382 = precise::atan2(_371, _367) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _382 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_382 - floor(_382)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _415 = fa_light_base(param, _286);\n    bool _419 = _286.fa_counts.y > 4.5;\n    int param_1 = _415;\n    float4 _423 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _415 + 1;\n    float4 _428 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _431 = _428.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _443 = _419 && (_431 > 2.5);\n    fa_light_is_area = _443;\n    bool _446 = _431 < 0.5;\n    float3 l;\n    if (_446)\n    {\n        l = fast::normalize(_423.xyz);\n        if (_419)\n        {\n            int param_3 = _415 + 6;\n            float4 _460 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_460.z > 0.5)\n            {\n                int param_4 = _415 + 4;\n                float4 _470 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _415 + 5;\n                float4 _476 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _460.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _470.xyz) * _470.w, (-dot(world_pos, _476.xyz)) * _476.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _508 = _423.xyz - world_pos;\n        float _510 = length(_508);\n        dist = _510;\n        l = _508 / float3(fast::max(_510, 9.9999997473787516355514526367188e-05));\n        float reach = _510;\n        if (_443)\n        {\n            int param_8 = _415 + 7;\n            reach = fast::max(dist - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n        }\n        float _542 = reach / fast::max(_423.w, 0.001000000047497451305389404296875);\n        float _548 = fast::clamp(1.0 - (_542 * _542), 0.0, 1.0);\n        atten = _548 * _548;\n        bool _556 = _431 < 2.5;\n        if ((_431 > 1.5) && _556)\n        {\n            int param_9 = _415 + 2;\n            float4 _564 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            float _574 = _564.w;\n            int param_10 = _415 + 3;\n            float4 _580 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            float _581 = _580.x;\n            float cos_inner = _581;\n            if (_581 > 1.5)\n            {\n                cos_inner = mix(_574, 1.0, 0.25);\n            }\n            atten *= smoothstep(_574, cos_inner, dot(-l, fast::normalize(_564.xyz)));\n        }\n        if (_419 && _556)\n        {\n            int param_11 = _415 + 6;\n            float4 _605 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            int param_12 = _415 + 7;\n            float4 _610 = fa_light_texel(param_12, fa_light_tex, fa_shadow_smp);\n            bool _613 = _605.z > 0.5;\n            bool _620;\n            if (!_613)\n            {\n                _620 = _610.z > 0.5;\n            }\n            else\n            {\n                _620 = _613;\n            }\n            if (_620)\n            {\n                int param_13 = _415 + 2;\n                float4 _627 = fa_light_texel(param_13, fa_light_tex, fa_shadow_smp);\n                float3 _631 = fast::normalize(_627.xyz);\n                int param_14 = _415 + 4;\n                float4 _636 = fa_light_texel(param_14, fa_light_tex, fa_shadow_smp);\n                int param_15 = _415 + 5;\n                float4 _641 = fa_light_texel(param_15, fa_light_tex, fa_shadow_smp);\n                if (_613)\n                {\n                    float3 _649 = -_508;\n                    float _656 = _627.w;\n                    float _672 = 0.5 / fast::max(dot(_649, _631) * (sqrt(fast::max(1.0 - (_656 * _656), 0.0)) / fast::max(_656, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    float2 param_16 = _605.xy;\n                    float2 param_17 = float2(0.5 + (dot(_649, _636.xyz) * _672), 0.5 - (dot(_649, _641.xyz) * _672));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17, fa_light_atlas, fa_env_smp);\n                }\n                if (_610.z > 0.5)\n                {\n                    float2 param_18 = _610.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _631;\n                    float3 param_21 = _636.xyz;\n                    float3 param_22 = _641.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22, fa_light_atlas, fa_env_smp);\n                }\n            }\n        }\n    }\n    float3 _3381 = _428.xyz * atten;\n    if (_419)\n    {\n        _3381 *= fa_light_tint;\n    }\n    int _741;\n    if (_446)\n    {\n        _741 = 0;\n    }\n    else\n    {\n        _741 = ((_431 > 1.5) && (_431 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _3381, atten, 1.0, dist, _741 };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_unshadowed(thread const int& n, thread const SurfaceInput& i, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    bool _2496 = n < 0;\n    bool _2503;\n    if (!_2496)\n    {\n        _2503 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _2503 = _2496;\n    }\n    if (_2503)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, _286, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    LightSample _2515 = fa_light_sample(param_1, param_2, _286, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    return _2515;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _990)\n{\n    float _980;\n    if (i == 0)\n    {\n        _980 = _990.fa_shadow_split.x;\n    }\n    else\n    {\n        float _996;\n        if (i == 1)\n        {\n            _996 = _990.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1004;\n            if (i == 2)\n            {\n                _1004 = _990.fa_shadow_split.z;\n            }\n            else\n            {\n                _1004 = _990.fa_shadow_split.w;\n            }\n            _996 = _1004;\n        }\n        _980 = _996;\n    }\n    return _980;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _968 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_968), sin(_968)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _990, texture2d<float> fa_shadow_tex)\n{\n    float _1042 = fast::max(_990.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1047 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1053 = sqrt(1.0 - (_1047 * _1047));\n    float _1061 = fast::min(_1053 / fast::max(_1047, 0.20000000298023223876953125), 4.0);\n    float _1066;\n    if (_990.fa_shadow_bias.y > 0.0)\n    {\n        _1066 = _990.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1066 = 1.5 * _990.fa_shadow_info[ci].x;\n    }\n    float4 _1091 = _990.fa_shadow_mat[ci] * float4(world + (n * (_1066 * _1053)), 1.0);\n    float _1098 = _1091.x;\n    bool _1101 = _1098 < _990.fa_shadow_rect[ci].x;\n    bool _1110;\n    if (!_1101)\n    {\n        _1110 = _1098 > _990.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1110 = _1101;\n    }\n    bool _1119;\n    if (!_1110)\n    {\n        _1119 = _1091.y < _990.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1119 = _1110;\n    }\n    bool _1128;\n    if (!_1119)\n    {\n        _1128 = _1091.y > _990.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1128 = _1119;\n    }\n    bool _1135;\n    if (!_1128)\n    {\n        _1135 = _1091.z > 1.0;\n    }\n    else\n    {\n        _1135 = _1128;\n    }\n    if (_1135)\n    {\n        return -1.0;\n    }\n    float _1143;\n    if (_990.fa_shadow_bias.x > 0.0)\n    {\n        _1143 = _990.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1143 = 1.5 * _990.fa_shadow_info[ci].x;\n    }\n    float _1162 = _1091.z - ((_1143 * (1.0 + (0.5 * _1061))) / _1042);\n    float _1171 = ((_990.fa_shadow_info[ci].x * fast::min(_1061, 3.0)) * 0.5) / _1042;\n    int _1180 = int(_990.fa_shadow_cfg.z + 0.5);\n    if (_1180 == 1)\n    {\n        float2 param = _1091.xy;\n        float4 param_1 = _990.fa_shadow_rect[ci];\n        float _1191 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1162 <= _1191);\n    }\n    float _1198 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1201 = _1180 == 2;\n    if (_1201)\n    {\n        float _1215 = fast::clamp(((_990.fa_shadow_cfg.w * _1042) * 0.25) / _990.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1198;\n            float2 _1234 = fa_shadow_vogel(param_2, param_3, param_4) * _1215;\n            float2 param_5 = _1091.xy + (_1234 * _990.fa_shadow_bias.zw);\n            float4 param_6 = _990.fa_shadow_rect[ci];\n            float _1245 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1245 < (_1162 - (length(_1234) * _1171)))\n            {\n                sum += _1245;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1162 - (sum / cnt), 0.0) * _1042) * _990.fa_shadow_cfg.w) / _990.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1289 = _1201 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1289; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1289;\n        float param_9 = _1198;\n        float2 _1308 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1091.xy + (_1308 * _990.fa_shadow_bias.zw);\n        float4 param_11 = _990.fa_shadow_rect[ci];\n        float _1319 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1162 - (length(_1308) * _1171)) <= _1319);\n    }\n    return lit / float(_1289);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _286, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _990, texture2d<float> fa_shadow_tex)\n{\n    if (_286.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1349 = int(_990.fa_shadow_cfg.x + 0.5);\n    if (_1349 < 1)\n    {\n        return 1.0;\n    }\n    float _1364 = dot(world - _990.fa_shadow_eye.xyz, _990.fa_shadow_fwd.xyz);\n    int param = _1349 - 1;\n    if (_1364 > fa_shadow_split_at(param, _990))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1376 = _1349 > 1;\n    bool _1383;\n    if (_1376)\n    {\n        _1383 = _1364 > _990.fa_shadow_split.x;\n    }\n    else\n    {\n        _1383 = _1376;\n    }\n    if (_1383)\n    {\n        ci = 1;\n    }\n    bool _1387 = _1349 > 2;\n    bool _1394;\n    if (_1387)\n    {\n        _1394 = _1364 > _990.fa_shadow_split.y;\n    }\n    else\n    {\n        _1394 = _1387;\n    }\n    if (_1394)\n    {\n        ci = 2;\n    }\n    bool _1398 = _1349 > 3;\n    bool _1405;\n    if (_1398)\n    {\n        _1405 = _1364 > _990.fa_shadow_split.z;\n    }\n    else\n    {\n        _1405 = _1398;\n    }\n    if (_1405)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1349)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1431 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _990, fa_shadow_tex);\n        s = _1431;\n        if (_1431 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_990.fa_shadow_cfg.y > 0.0)\n    {\n        float _1456;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1456 = fa_shadow_split_at(param_5, _990);\n        }\n        else\n        {\n            _1456 = _990.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1475 = _990.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _990) - _1456, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1486 = fast::clamp((_1364 - (fa_shadow_split_at(param_7, _990) - _1475)) / _1475, 0.0, 1.0);\n        if (_1486 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1349)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1507 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _990, fa_shadow_tex);\n                s2 = _1507;\n                if (_1507 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1486);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _286, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _990, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _286, fa_shadow_smp, gl_FragCoord, _990, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _990, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2439 = fa_light_sample(param, param_1, _286, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _3514 = _2439.color;\n    float _3516 = _2439.shadow;\n    if ((_2439.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2439.direction;\n        float _2453 = fa_shadow_factor(param_2, param_3, _286, fa_shadow_smp, gl_FragCoord, _990, fa_shadow_tex, fa_world_pos);\n        _3516 = _2453;\n        _3514 *= _2453;\n    }\n    return LightSample{ _2439.direction, _3514, _2439.attenuation, _3516, _2439._distance, _2439.type };\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& n, thread const SurfaceInput& i, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _990, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    bool _2470 = n < 0;\n    bool _2477;\n    if (!_2470)\n    {\n        _2477 = n >= fa_light_count(fa_cl_ndir, fa_cl_local);\n    }\n    else\n    {\n        _2477 = _2470;\n    }\n    if (_2477)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param, _286, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _2492 = fa_light_shadowed(param_1, param_2, param_3, _286, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _990, fa_shadow_tex, fa_world_pos);\n    return _2492;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1788 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1796 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1799 = int(_1788);\n    int _1802 = int(_1796);\n    float _1812 = _1796 - float(_1802);\n    int _1868 = (_1799 * 9) + _1802;\n    int _1888 = ((_1799 + 1) * 9) + _1802;\n    return mix(mix(_1863[_1868], _1863[_1868 + 1], _1812), mix(_1863[_1888], _1863[_1888 + 1], _1812), _1788 - float(_1799));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _3393 = false;\n    float _3394 = 1.0;\n    float _3395 = 1.0;\n    float _3396 = 1.0;\n    float _3397 = 0.0;\n    float _3398 = 0.0;\n    float _3399 = 0.0;\n    float _3400 = 0.0;\n    float _3402 = 1.0;\n    bool _3403 = false;\n    float3 _3404 = float3(0.0);\n    float _3405 = 1.0;\n    float _3406 = 1.0;\n    float _3407 = 1.0;\n    float _3408 = 0.0;\n    float _3409 = 0.0;\n    float3 _3410 = float3(1.0, 0.0, 0.0);\n    float3 _3411 = float3(0.0, 0.0, 1.0);\n    float _3412 = 1.0;\n    float _3413 = 1.0;\n    float _1942 = fast::clamp(s.specular, 0.0, 1.0);\n    float _1946 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _1951 = (_1942 != 1.0) || (_1946 != 1.5);\n    bool _1960;\n    if (!_1951)\n    {\n        _1960 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _1960 = _1951;\n    }\n    if (_1960)\n    {\n        float _1968 = (_1946 - 1.0) / (_1946 + 1.0);\n        f0 = mix(fast::min(float3(_1968 * _1968) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _1942, s.albedo, float3(metallic));\n        _3394 = mix(_1942, 1.0, metallic);\n        _3393 = true;\n    }\n    float _1996 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_1996 > 0.0)\n    {\n        float _2004 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3397 = _1996;\n        _3398 = _2004;\n        float _2011 = _2004 * _2004;\n        _3399 = _2011;\n        _3400 = _2011 * _2011;\n        float _2023 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3402 = _2023;\n        _3395 = 1.0 - (_1996 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2023, 0.0, 1.0), 5.0))));\n        _3393 = true;\n    }\n    float3 _2043 = fast::max(s.sheen_color, float3(0.0));\n    float _2052 = fast::max(_2043.x, fast::max(_2043.y, _2043.z));\n    if (_2052 > 0.0)\n    {\n        float _2060 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3403 = true;\n        _3404 = _2043;\n        _3405 = _2060;\n        _3406 = _2060 * _2060;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2060;\n        float _2077 = fa_sheen_albedo(param, param_1);\n        _3408 = _2077;\n        _3407 = 1.0 - fast::min(_2052 * _2077, 1.0);\n        _3393 = true;\n    }\n    _3396 = _3395 * _3407;\n    float _2096 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2096 != 0.0)\n    {\n        float3 _2111 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2111;\n        if (dot(_2111, _2111) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2129 = t;\n        float3 _2130 = fast::normalize(_2129);\n        t = _2130;\n        float3 _2155 = fast::normalize((_2130 * cos(s.anisotropy_rotation)) + ((cross(n, _2130) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3410 = _2155;\n        _3411 = cross(n, _2155);\n        float _2165 = roughness * roughness;\n        float _2171 = mix(_2165, 1.0, _2096 * _2096);\n        bool _2173 = _2096 > 0.0;\n        _3412 = _2173 ? _2171 : _2165;\n        _3413 = _2173 ? _2165 : _2171;\n        _3409 = _2096;\n        _3393 = true;\n    }\n    return FaLayers{ short(_3393), _3394, _3395, _3396, _3397, _3398, _3399, _3400, i.world_normal, _3402, short(_3403), _3404, _3405, _3406, _3407, _3408, _3409, _3410, _3411, _3412, _3413 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1720 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1723 = _1720.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1723 * _1723, exp2((-9.27999973297119140625) * ndv)) * _1723) + _1720.y)) + _1720.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _286, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_286.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _286.fa_env_horizon.w)).xyz;\n    }\n    float _1643 = rough * rough;\n    float _1673 = 0.60000002384185791015625 * _1643;\n    return mix(mix(_286.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_286.fa_env_horizon.xyz, _286.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1643)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1673, 0.0500000007450580596923828125 + _1673, d.y))), ((_286.fa_env_sky.xyz + _286.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1643 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _286, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2206;\n        if (L.aniso >= 0.0)\n        {\n            _2206 = L.b;\n        }\n        else\n        {\n            _2206 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2206, v), _2206), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2239 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _286, fa_env_smp, fa_env_tex) * ((f0 * _2239.x) + (float3(L.f90) * _2239.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _286, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2294 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _286, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _2294.x) + _2294.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _286, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1762 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _286, fa_env_smp, fa_env_tex) * ((f0 * _1762.x) + float3(_1762.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _286, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float _2333 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _2337 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _2344 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_2333));\n    float3 f0 = _2344;\n    float3 _2348 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _2348;\n    float3 param_3 = i.view_dir;\n    float param_4 = _2333;\n    float param_5 = _2337;\n    float3 param_6 = _2344;\n    FaLayers _2365 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2365.on)\n    {\n        FaLayers param_7 = _2365;\n        float3 param_8 = _2348;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _2337;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _286, fa_env_smp, fa_env_tex) * s.occlusion;\n    }\n    float3 param_12 = _2348;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _2337;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _286, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lighting(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _286, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _990, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texturecube<float> fa_env_tex, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local, constant fa_material& _2586)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(fa_cl_ndir, fa_cl_local); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _2535 = fa_light_unshadowed(param, param_1, _286, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n        float _2543 = dot(_2535.color, float3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_2543 > bestPower)\n        {\n            bestPower = _2543;\n            best = n;\n        }\n    }\n    float3 lit = (_286.fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2572 = fa_light(param_2, param_3, _286, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _990, fa_shadow_tex, fa_world_pos, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n        float _2580;\n        if (dot(s.normal, _2572.direction) > 0.5)\n        {\n            _2580 = 1.0;\n        }\n        else\n        {\n            _2580 = _2586.dark;\n        }\n        lit += ((s.albedo * _2572.color) * _2580);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5, _286, fa_env_smp, fa_env_tex) * _2586.skyAmount);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _990)\n{\n    if (_990.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1531 = int(_990.fa_shadow_cfg.x + 0.5);\n    float _1541 = dot(world - _990.fa_shadow_eye.xyz, _990.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1546 = _1531 > 0;\n    bool _1555;\n    if (_1546)\n    {\n        int param = _1531 - 1;\n        _1555 = _1541 <= fa_shadow_split_at(param, _990);\n    }\n    else\n    {\n        _1555 = _1546;\n    }\n    if (_1555)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1562 = _1531 > 1;\n        bool _1569;\n        if (_1562)\n        {\n            _1569 = _1541 > _990.fa_shadow_split.x;\n        }\n        else\n        {\n            _1569 = _1562;\n        }\n        if (_1569)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1575 = _1531 > 2;\n        bool _1582;\n        if (_1575)\n        {\n            _1582 = _1541 > _990.fa_shadow_split.y;\n        }\n        else\n        {\n            _1582 = _1575;\n        }\n        if (_1582)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1588 = _1531 > 3;\n        bool _1595;\n        if (_1588)\n        {\n            _1595 = _1541 > _990.fa_shadow_split.z;\n        }\n        else\n        {\n            _1595 = _1588;\n        }\n        if (_1595)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _286 [[buffer(1)]], constant fa_material& _2586 [[buffer(5)]], constant fa_shadows& _990 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3267 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3267 = -_3267;\n    }\n    float3 _2971 = fast::normalize(_286.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _286, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3267, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2971, short(gl_FrontFacing) };\n    Surface _2979 = fa_standard_surface(param_1, _286, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3298 = _2979.albedo;\n    float _3299 = _2979.alpha;\n    float3 _3300 = _2979.normal;\n    float _3301 = _2979.metallic;\n    float _3302 = _2979.roughness;\n    float _3303 = _2979.occlusion;\n    float3 _3304 = _2979.emission;\n    float _3305 = _2979.clearcoat;\n    float _3306 = _2979.clearcoat_roughness;\n    float3 _3307 = _2979.sheen_color;\n    float _3308 = _2979.sheen_roughness;\n    float _3309 = _2979.anisotropy;\n    float _3310 = _2979.anisotropy_rotation;\n    float _3311 = _2979.specular;\n    float _3312 = _2979.ior;\n    float3 _3313 = _2979.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3267, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2971, short(gl_FrontFacing) };\n    Surface param_3 = _2979;\n    surface(param_2, param_3);\n    _3298 = param_3.albedo;\n    _3299 = param_3.alpha;\n    _3300 = param_3.normal;\n    _3301 = param_3.metallic;\n    _3302 = param_3.roughness;\n    _3303 = param_3.occlusion;\n    _3304 = param_3.emission;\n    _3305 = param_3.clearcoat;\n    _3306 = param_3.clearcoat_roughness;\n    _3307 = param_3.sheen_color;\n    _3308 = param_3.sheen_roughness;\n    _3309 = param_3.anisotropy;\n    _3310 = param_3.anisotropy_rotation;\n    _3311 = param_3.specular;\n    _3312 = param_3.ior;\n    _3313 = param_3.specular_color;\n    float3 result;\n    if (_286.fa_emissive.w > 0.5)\n    {\n        result = _3298;\n    }\n    else\n    {\n        float3 _3000 = _3300;\n        float3 _3001 = fast::normalize(_3000);\n        _3300 = _3001;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _3267, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2971, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _3298, _3299, _3001, _3301, _3302, _3303, _3304, _3305, _3306, _3307, _3308, _3309, _3310, _3311, _3312, _3313 };\n        float3 _3012 = lighting(param_4, param_5, _286, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _990, fa_shadow_tex, in.fa_world_pos, fa_env_tex, fa_cl_ndir, fa_cl_slot, fa_cl_local, _2586);\n        result = _3012;\n    }\n    float3 _3016 = result;\n    float3 _3017 = _3016 + _3304;\n    result = _3017;\n    float3 param_6 = _3017;\n    float3 param_7 = in.fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7, _990);\n    bool _3026 = _286.fa_fog.w > 0.0;\n    bool _3033;\n    if (!_3026)\n    {\n        _3033 = _286.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3033 = _3026;\n    }\n    if (_3033)\n    {\n        float3 _3042 = in.fa_world_pos - _286.fa_camera_pos.xyz;\n        float _3048 = dot(_3042, _286.fa_fog_c.xyz);\n        bool _3052 = _286.fa_fog_c.w > 0.5;\n        float _3053;\n        if (_3052)\n        {\n            _3053 = _3048;\n        }\n        else\n        {\n            _3053 = length(_3042);\n        }\n        float _3065 = _3053 - _286.fa_fog_b.x;\n        if (_3065 > 0.0)\n        {\n            float _3074 = _286.fa_fog.w * _3065;\n            float tau = _3074 * _3074;\n            if (_286.fa_fog_b.y > 0.0)\n            {\n                float _3090;\n                if (_3052)\n                {\n                    _3090 = in.fa_world_pos.y - (_286.fa_fog_c.y * _3048);\n                }\n                else\n                {\n                    _3090 = _286.fa_camera_pos.y;\n                }\n                float _3111 = mix(_3090, in.fa_world_pos.y, fast::clamp(_286.fa_fog_b.x / _3053, 0.0, 1.0));\n                float _3115 = in.fa_world_pos.y - _3111;\n                float _3120 = _3111 - _286.fa_fog_b.z;\n                float _3125 = in.fa_world_pos.y - _286.fa_fog_b.z;\n                bool _3128 = _3120 <= 0.0;\n                bool _3129 = !_3128;\n                bool _3135;\n                if (_3129)\n                {\n                    _3135 = _286.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3135 = _3128;\n                }\n                float _3136;\n                if (_3135)\n                {\n                    _3136 = _286.fa_fog_b.y;\n                }\n                else\n                {\n                    _3136 = _286.fa_fog_b.y * exp(-fast::min(_286.fa_fog_b.w * _3120, 80.0));\n                }\n                bool _3163;\n                if (_3129)\n                {\n                    _3163 = _286.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3163 = _3128;\n                }\n                float _3164;\n                if (_3163)\n                {\n                    _3164 = _286.fa_fog_b.y * _3120;\n                }\n                else\n                {\n                    _3164 = (_286.fa_fog_b.y * (1.0 - exp(-fast::min(_286.fa_fog_b.w * _3120, 80.0)))) / _286.fa_fog_b.w;\n                }\n                bool _3189 = _3125 <= 0.0;\n                bool _3196;\n                if (!_3189)\n                {\n                    _3196 = _286.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3196 = _3189;\n                }\n                float _3197;\n                if (_3196)\n                {\n                    _3197 = _286.fa_fog_b.y * _3125;\n                }\n                else\n                {\n                    _3197 = (_286.fa_fog_b.y * (1.0 - exp(-fast::min(_286.fa_fog_b.w * _3125, 80.0)))) / _286.fa_fog_b.w;\n                }\n                float _3224;\n                if (abs(_3115) < 0.001000000047497451305389404296875)\n                {\n                    _3224 = _3136;\n                }\n                else\n                {\n                    _3224 = (_3197 - _3164) / _3115;\n                }\n                tau += (_3065 * fast::max(_3224, 0.0));\n            }\n            result = mix(result, _286.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3299);\n    return out;\n}\n\n",
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
            "inst_name": "_286",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_990",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2586",
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
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
          },
          {
            "slot": 8,
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
