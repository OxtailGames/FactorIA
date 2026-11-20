{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "738bdbaa5d236ca82c68b48e7af94b35c54ba5d6311eabf2bcbbc814ba3d221c",
  "slang": "metal_macos",
  "params": [
    "alphaCutoff"
  ],
  "textures": [
    "mask"
  ],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _274 = _160.world_pos;\n    fa_world_pos = _274;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_274, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nconstant spvUnsafeArray<float, 63> _1985 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _381, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _863 = _381.fa_cl_info.x < 0.0;\n    bool _870;\n    if (!_863)\n    {\n        _870 = _381.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _870 = _863;\n    }\n    bool _878;\n    if (!_870)\n    {\n        _878 = _381.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _878 = _870;\n    }\n    bool _885;\n    if (!_878)\n    {\n        _885 = _381.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _885 = _878;\n    }\n    bool _892;\n    if (!_885)\n    {\n        _892 = _381.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _892 = _885;\n    }\n    if (_892)\n    {\n        return int2(0);\n    }\n    float4 _902 = float4(world_pos, 1.0);\n    float _909 = dot(_381.fa_cl_vpw, _902);\n    if (!(_909 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _931 = float2(dot(_381.fa_cl_vpx, _902), dot(_381.fa_cl_vpy, _902)) / float2(_909);\n    int _935 = int(_381.fa_cl_grid.x);\n    int _939 = int(_381.fa_cl_grid.y);\n    int param = (int(_381.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_381.fa_cl_fwd.xyz, world_pos) + _381.fa_cl_fwd.w, _381.fa_cl_grid.w) / _381.fa_cl_grid.w) * _381.fa_cl_grid.z)), 0, int(_381.fa_cl_info.y) - 1) * _939) + clamp(int(floor(((_931.y * 0.5) + 0.5) * _381.fa_cl_grid.y)), 0, _939 - 1)) * _935)) + clamp(int(floor(((_931.x * 0.5) + 0.5) * _381.fa_cl_grid.x)), 0, _935 - 1);\n    float4 _1010 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1010.x), int(_1010.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _381, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_381.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2802 = fa_cluster_lookup(param, _381, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _2802.x;\n    fa_cl_local = _2802.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3727 = fa_linear_to_srgb(param);\n        c = _3727;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3735 = fa_srgb_to_linear(param_1);\n            c = _3735;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _313;\n    if (bool(i.front_facing))\n    {\n        _313 = i.world_normal;\n    }\n    else\n    {\n        _313 = -i.world_normal;\n    }\n    float3 _337 = fast::normalize(i.world_tangent.xyz - (_313 * dot(_313, i.world_tangent.xyz)));\n    float3 _365 = fast::normalize(((_337 * m.x) + ((cross(_313, _337) * i.world_tangent.w) * m.y)) + (_313 * m.z));\n    float3 _368;\n    if (bool(i.front_facing))\n    {\n        _368 = _365;\n    }\n    else\n    {\n        _368 = -_365;\n    }\n    return _368;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _381, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _381.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3766 = fa_tex_fix(param_2, param_3);\n    float4 _5007 = base_t;\n    _5007.x = _3766.x;\n    _5007.y = _3766.y;\n    _5007.z = _3766.z;\n    base_t = _5007;\n    float4 _3780 = (_5007 * _381.fa_base_color) * i.vertex_color;\n    float3 _4917 = i.world_normal;\n    if (_381.fa_maps.z > 0.5)\n    {\n        float param_4 = _381.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3812 = fa_tex_fix(param_6, param_7);\n        float3 _3815 = (_3812 * 2.0) - float3(1.0);\n        float2 _3820 = _3815.xy * _381.fa_maps.x;\n        float3 _5015 = _3815;\n        _5015.x = _3820.x;\n        _5015.y = _3820.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5015;\n        _4917 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _381.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3848 = fa_tex_fix(param_12, param_13);\n    float4 _5018 = mrt;\n    _5018.x = _3848.x;\n    _5018.y = _3848.y;\n    _5018.z = _3848.z;\n    mrt = _5018;\n    float4 _3876 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _381.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3876.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3888 = fa_tex_fix(param_16, param_17);\n    float param_18 = _381.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3918 = fa_tex_fix(param_20, param_21);\n    float _4922 = _381.fa_layers_a.x;\n    float _4923 = _381.fa_layers_a.y;\n    float _4926 = _381.fa_layers_a.z;\n    float _4925 = _381.fa_layers_b.w;\n    float _4928 = _381.fa_layers_c.x;\n    if (_381.fa_layers_c.z > 0.5)\n    {\n        if (mod(_381.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4922 *= _3888.y;\n            _4923 *= _3888.z;\n            _4925 *= _3876.w;\n        }\n        if (_381.fa_layers_c.z > 1.5)\n        {\n            _4926 *= mrt.x;\n            _4928 *= mrt.w;\n        }\n    }\n    return Surface{ _3780.xyz, _3780.w, _4917, fast::clamp(_381.fa_pbr.x * _3848.z, 0.0, 1.0), fast::clamp(_381.fa_pbr.y * _3848.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_381.fa_maps.y * (_3888.x - 1.0)), _381.fa_emissive.xyz + (_381.fa_model_emissive.xyz * _3918), _4922, _4923, _381.fa_layers_b.xyz, _4925, _4926, _381.fa_layers_a.w, _4928, _381.fa_layers_c.y, _381.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1910 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1918 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1921 = int(_1910);\n    int _1924 = int(_1918);\n    float _1934 = _1918 - float(_1924);\n    int _1990 = (_1921 * 9) + _1924;\n    int _2010 = ((_1921 + 1) * 9) + _1924;\n    return mix(mix(_1985[_1990], _1985[_1990 + 1], _1934), mix(_1985[_2010], _1985[_2010 + 1], _1934), _1910 - float(_1921));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4853 = false;\n    float _4854 = 1.0;\n    float _4855 = 1.0;\n    float _4856 = 1.0;\n    float _4857 = 0.0;\n    float _4858 = 0.0;\n    float _4859 = 0.0;\n    float _4860 = 0.0;\n    float _4862 = 1.0;\n    bool _4863 = false;\n    float3 _4864 = float3(0.0);\n    float _4865 = 1.0;\n    float _4866 = 1.0;\n    float _4867 = 1.0;\n    float _4868 = 0.0;\n    float _4869 = 0.0;\n    float3 _4870 = float3(1.0, 0.0, 0.0);\n    float3 _4871 = float3(0.0, 0.0, 1.0);\n    float _4872 = 1.0;\n    float _4873 = 1.0;\n    float _2064 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2068 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2073 = (_2064 != 1.0) || (_2068 != 1.5);\n    bool _2082;\n    if (!_2073)\n    {\n        _2082 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2082 = _2073;\n    }\n    if (_2082)\n    {\n        float _2090 = (_2068 - 1.0) / (_2068 + 1.0);\n        f0 = mix(fast::min(float3(_2090 * _2090) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2064, s.albedo, float3(metallic));\n        _4854 = mix(_2064, 1.0, metallic);\n        _4853 = true;\n    }\n    float _2118 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2118 > 0.0)\n    {\n        float _2126 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4857 = _2118;\n        _4858 = _2126;\n        float _2133 = _2126 * _2126;\n        _4859 = _2133;\n        _4860 = _2133 * _2133;\n        float _2145 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4862 = _2145;\n        _4855 = 1.0 - (_2118 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2145, 0.0, 1.0), 5.0))));\n        _4853 = true;\n    }\n    float3 _2165 = fast::max(s.sheen_color, float3(0.0));\n    float _2174 = fast::max(_2165.x, fast::max(_2165.y, _2165.z));\n    if (_2174 > 0.0)\n    {\n        float _2182 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4863 = true;\n        _4864 = _2165;\n        _4865 = _2182;\n        _4866 = _2182 * _2182;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2182;\n        float _2199 = fa_sheen_albedo(param, param_1);\n        _4868 = _2199;\n        _4867 = 1.0 - fast::min(_2174 * _2199, 1.0);\n        _4853 = true;\n    }\n    _4856 = _4855 * _4867;\n    float _2218 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2218 != 0.0)\n    {\n        float3 _2233 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2233;\n        if (dot(_2233, _2233) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2251 = t;\n        float3 _2252 = fast::normalize(_2251);\n        t = _2252;\n        float3 _2277 = fast::normalize((_2252 * cos(s.anisotropy_rotation)) + ((cross(n, _2252) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4870 = _2277;\n        _4871 = cross(n, _2277);\n        float _2287 = roughness * roughness;\n        float _2293 = mix(_2287, 1.0, _2218 * _2218);\n        bool _2295 = _2218 > 0.0;\n        _4872 = _2295 ? _2293 : _2287;\n        _4873 = _2295 ? _2287 : _2293;\n        _4869 = _2218;\n        _4853 = true;\n    }\n    return FaLayers{ short(_4853), _4854, _4855, _4856, _4857, _4858, _4859, _4860, i.world_normal, _4862, short(_4863), _4864, _4865, _4866, _4867, _4868, _4869, _4870, _4871, _4872, _4873 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _381, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_381.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _381.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _381, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_381.fa_cl_info.x) + int(_381.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _381, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _381, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _381)\n{\n    return li * ((_381.fa_counts.y > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _471 = dot(d, right);\n    float _475 = dot(d, up);\n    float _486;\n    if (((_471 * _471) + (_475 * _475)) > 1.0000000133514319600180897396058e-10)\n    {\n        _486 = precise::atan2(_475, _471) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _486 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_486 - floor(_486)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_mesh_fs_params& _381, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _519 = fa_light_base(param, _381);\n    bool _523 = _381.fa_counts.y > 4.5;\n    int param_1 = _519;\n    float4 _527 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _519 + 1;\n    float4 _532 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _535 = _532.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _547 = _523 && (_535 > 2.5);\n    fa_light_is_area = _547;\n    bool _550 = _535 < 0.5;\n    float3 l;\n    if (_550)\n    {\n        l = fast::normalize(_527.xyz);\n        if (_523)\n        {\n            int param_3 = _519 + 6;\n            float4 _564 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_564.z > 0.5)\n            {\n                int param_4 = _519 + 4;\n                float4 _574 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _519 + 5;\n                float4 _580 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _564.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _574.xyz) * _574.w, (-dot(world_pos, _580.xyz)) * _580.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _612 = _527.xyz - world_pos;\n        float _614 = length(_612);\n        dist = _614;\n        l = _612 / float3(fast::max(_614, 9.9999997473787516355514526367188e-05));\n        float reach = _614;\n        if (_547)\n        {\n            int param_8 = _519 + 7;\n            reach = fast::max(dist - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n        }\n        float _646 = reach / fast::max(_527.w, 0.001000000047497451305389404296875);\n        float _652 = fast::clamp(1.0 - (_646 * _646), 0.0, 1.0);\n        atten = _652 * _652;\n        bool _660 = _535 < 2.5;\n        if ((_535 > 1.5) && _660)\n        {\n            int param_9 = _519 + 2;\n            float4 _668 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            float _678 = _668.w;\n            int param_10 = _519 + 3;\n            float4 _684 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            float _685 = _684.x;\n            float cos_inner = _685;\n            if (_685 > 1.5)\n            {\n                cos_inner = mix(_678, 1.0, 0.25);\n            }\n            atten *= smoothstep(_678, cos_inner, dot(-l, fast::normalize(_668.xyz)));\n        }\n        if (_523 && _660)\n        {\n            int param_11 = _519 + 6;\n            float4 _709 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            int param_12 = _519 + 7;\n            float4 _714 = fa_light_texel(param_12, fa_light_tex, fa_shadow_smp);\n            bool _717 = _709.z > 0.5;\n            bool _724;\n            if (!_717)\n            {\n                _724 = _714.z > 0.5;\n            }\n            else\n            {\n                _724 = _717;\n            }\n            if (_724)\n            {\n                int param_13 = _519 + 2;\n                float4 _731 = fa_light_texel(param_13, fa_light_tex, fa_shadow_smp);\n                float3 _735 = fast::normalize(_731.xyz);\n                int param_14 = _519 + 4;\n                float4 _740 = fa_light_texel(param_14, fa_light_tex, fa_shadow_smp);\n                int param_15 = _519 + 5;\n                float4 _745 = fa_light_texel(param_15, fa_light_tex, fa_shadow_smp);\n                if (_717)\n                {\n                    float3 _753 = -_612;\n                    float _760 = _731.w;\n                    float _776 = 0.5 / fast::max(dot(_753, _735) * (sqrt(fast::max(1.0 - (_760 * _760), 0.0)) / fast::max(_760, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    float2 param_16 = _709.xy;\n                    float2 param_17 = float2(0.5 + (dot(_753, _740.xyz) * _776), 0.5 - (dot(_753, _745.xyz) * _776));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17, fa_light_atlas, fa_env_smp);\n                }\n                if (_714.z > 0.5)\n                {\n                    float2 param_18 = _714.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _735;\n                    float3 param_21 = _740.xyz;\n                    float3 param_22 = _745.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22, fa_light_atlas, fa_env_smp);\n                }\n            }\n        }\n    }\n    float3 _4841 = _532.xyz * atten;\n    if (_523)\n    {\n        _4841 *= fa_light_tint;\n    }\n    int _845;\n    if (_550)\n    {\n        _845 = 0;\n    }\n    else\n    {\n        _845 = ((_535 > 1.5) && (_535 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4841, atten, 1.0, dist, _845 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1094)\n{\n    float _1084;\n    if (i == 0)\n    {\n        _1084 = _1094.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1100;\n        if (i == 1)\n        {\n            _1100 = _1094.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1108;\n            if (i == 2)\n            {\n                _1108 = _1094.fa_shadow_split.z;\n            }\n            else\n            {\n                _1108 = _1094.fa_shadow_split.w;\n            }\n            _1100 = _1108;\n        }\n        _1084 = _1100;\n    }\n    return _1084;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1072 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1072), sin(_1072)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1094, texture2d<float> fa_shadow_tex)\n{\n    float _1146 = fast::max(_1094.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1151 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1157 = sqrt(1.0 - (_1151 * _1151));\n    float _1165 = fast::min(_1157 / fast::max(_1151, 0.20000000298023223876953125), 4.0);\n    float _1170;\n    if (_1094.fa_shadow_bias.y > 0.0)\n    {\n        _1170 = _1094.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1170 = 1.5 * _1094.fa_shadow_info[ci].x;\n    }\n    float4 _1195 = _1094.fa_shadow_mat[ci] * float4(world + (n * (_1170 * _1157)), 1.0);\n    float _1202 = _1195.x;\n    bool _1205 = _1202 < _1094.fa_shadow_rect[ci].x;\n    bool _1214;\n    if (!_1205)\n    {\n        _1214 = _1202 > _1094.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1214 = _1205;\n    }\n    bool _1223;\n    if (!_1214)\n    {\n        _1223 = _1195.y < _1094.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1223 = _1214;\n    }\n    bool _1232;\n    if (!_1223)\n    {\n        _1232 = _1195.y > _1094.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1232 = _1223;\n    }\n    bool _1239;\n    if (!_1232)\n    {\n        _1239 = _1195.z > 1.0;\n    }\n    else\n    {\n        _1239 = _1232;\n    }\n    if (_1239)\n    {\n        return -1.0;\n    }\n    float _1247;\n    if (_1094.fa_shadow_bias.x > 0.0)\n    {\n        _1247 = _1094.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1247 = 1.5 * _1094.fa_shadow_info[ci].x;\n    }\n    float _1266 = _1195.z - ((_1247 * (1.0 + (0.5 * _1165))) / _1146);\n    float _1275 = ((_1094.fa_shadow_info[ci].x * fast::min(_1165, 3.0)) * 0.5) / _1146;\n    int _1284 = int(_1094.fa_shadow_cfg.z + 0.5);\n    if (_1284 == 1)\n    {\n        float2 param = _1195.xy;\n        float4 param_1 = _1094.fa_shadow_rect[ci];\n        float _1295 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1266 <= _1295);\n    }\n    float _1302 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1305 = _1284 == 2;\n    if (_1305)\n    {\n        float _1319 = fast::clamp(((_1094.fa_shadow_cfg.w * _1146) * 0.25) / _1094.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1302;\n            float2 _1338 = fa_shadow_vogel(param_2, param_3, param_4) * _1319;\n            float2 param_5 = _1195.xy + (_1338 * _1094.fa_shadow_bias.zw);\n            float4 param_6 = _1094.fa_shadow_rect[ci];\n            float _1349 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1349 < (_1266 - (length(_1338) * _1275)))\n            {\n                sum += _1349;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1266 - (sum / cnt), 0.0) * _1146) * _1094.fa_shadow_cfg.w) / _1094.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1393 = _1305 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1393; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1393;\n        float param_9 = _1302;\n        float2 _1412 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1195.xy + (_1412 * _1094.fa_shadow_bias.zw);\n        float4 param_11 = _1094.fa_shadow_rect[ci];\n        float _1423 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1266 - (length(_1412) * _1275)) <= _1423);\n    }\n    return lit / float(_1393);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _381, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1094, texture2d<float> fa_shadow_tex)\n{\n    if (_381.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1453 = int(_1094.fa_shadow_cfg.x + 0.5);\n    if (_1453 < 1)\n    {\n        return 1.0;\n    }\n    float _1468 = dot(world - _1094.fa_shadow_eye.xyz, _1094.fa_shadow_fwd.xyz);\n    int param = _1453 - 1;\n    if (_1468 > fa_shadow_split_at(param, _1094))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1480 = _1453 > 1;\n    bool _1487;\n    if (_1480)\n    {\n        _1487 = _1468 > _1094.fa_shadow_split.x;\n    }\n    else\n    {\n        _1487 = _1480;\n    }\n    if (_1487)\n    {\n        ci = 1;\n    }\n    bool _1491 = _1453 > 2;\n    bool _1498;\n    if (_1491)\n    {\n        _1498 = _1468 > _1094.fa_shadow_split.y;\n    }\n    else\n    {\n        _1498 = _1491;\n    }\n    if (_1498)\n    {\n        ci = 2;\n    }\n    bool _1502 = _1453 > 3;\n    bool _1509;\n    if (_1502)\n    {\n        _1509 = _1468 > _1094.fa_shadow_split.z;\n    }\n    else\n    {\n        _1509 = _1502;\n    }\n    if (_1509)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1453)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1535 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1094, fa_shadow_tex);\n        s = _1535;\n        if (_1535 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1094.fa_shadow_cfg.y > 0.0)\n    {\n        float _1560;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1560 = fa_shadow_split_at(param_5, _1094);\n        }\n        else\n        {\n            _1560 = _1094.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1579 = _1094.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1094) - _1560, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1590 = fast::clamp((_1468 - (fa_shadow_split_at(param_7, _1094) - _1579)) / _1579, 0.0, 1.0);\n        if (_1590 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1453)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1611 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1094, fa_shadow_tex);\n                s2 = _1611;\n                if (_1611 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1590);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _381, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1094, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _381, fa_shadow_smp, gl_FragCoord, _1094, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _381, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _1094, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2830 = fa_light_sample(param, param_1, _381, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4897 = _2830.color;\n    float _4899 = _2830.shadow;\n    if ((_2830.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2830.direction;\n        float _2844 = fa_shadow_factor(param_2, param_3, _381, fa_shadow_smp, gl_FragCoord, _1094, fa_shadow_tex, fa_world_pos);\n        _4899 = _2844;\n        _4897 *= _2844;\n    }\n    return LightSample{ _2830.direction, _4897, _2830.attenuation, _4899, _2830._distance, _2830.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_tangent(thread const float3& n, thread const float3& v)\n{\n    float3 _2884 = v - (n * dot(v, n));\n    float3 t = _2884;\n    float _2888 = dot(_2884, _2884);\n    float l2 = _2888;\n    if (_2888 < 1.0000000133514319600180897396058e-10)\n    {\n        float3 _2898;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _2898 = cross(n, float3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _2898 = cross(n, float3(1.0, 0.0, 0.0));\n        }\n        t = _2898;\n        l2 = dot(_2898, _2898);\n    }\n    return t * rsqrt(l2);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_local(thread const float3& t1, thread const float3& n, thread const float3& p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_edge_vector(thread const float3& a, thread const float3& b)\n{\n    float _2933 = dot(a, a);\n    float _2937 = dot(b, b);\n    if ((_2933 < 1.0000000195414813782625560981111e-24) || (_2937 < 1.0000000195414813782625560981111e-24))\n    {\n        return float3(0.0);\n    }\n    float3 _2951 = a * rsqrt(_2933);\n    float3 _2956 = b * rsqrt(_2937);\n    float _2960 = dot(_2951, _2956);\n    float _2963 = abs(_2960);\n    float g = (((((((((((0.0416471660137176513671875 * _2963) - 0.1924748718738555908203125) * _2963) + 0.4179156124591827392578125) * _2963) - 0.616057217121124267578125) * _2963) + 0.777722418308258056640625) * _2963) - 0.999542415142059326171875) * _2963) + 1.570791721343994140625;\n    if (_2960 < 0.0)\n    {\n        g = (3.1415927410125732421875 * rsqrt(fast::max(1.0 - (_2960 * _2960), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_2951, _2956) * g;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_ltc_clip_edge(thread const float3& a, thread const float3& b, thread float3& sum, thread float3& leave, thread float3& enter, thread float2& seen)\n{\n    bool _3020 = a.z > 0.0;\n    bool _3024 = b.z > 0.0;\n    if (_3020 && _3024)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_3020 != _3024)\n        {\n            float3 _3059 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _3059.z = 0.0;\n            if (_3020)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _3059;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _3059;\n                seen.x = 1.0;\n            }\n            else\n            {\n                float3 param_4 = _3059;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _3059;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ltc_quad(thread const float4& abcd, thread const float3& p0, thread const float3& p1, thread const float3& p2, thread const float3& p3)\n{\n    float3 _3108 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _3134 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _3160 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _3186 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = float3(0.0);\n    float3 leave = float3(0.0);\n    float3 enter = float3(0.0);\n    float3 param = _3108;\n    float3 param_1 = _3134;\n    float3 param_2 = float3(0.0);\n    float3 param_3 = float3(0.0);\n    float3 param_4 = float3(0.0);\n    float2 param_5 = float2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _3134;\n    float3 param_7 = _3160;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _3160;\n    float3 param_13 = _3186;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _3186;\n    float3 param_19 = _3108;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ltc_rect(thread const float4& abcd, thread const float3& center, thread const float3& ex, thread const float3& ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_area_form(thread const float4& m, thread const float& shape, thread const float3& pc, thread const float3& ex, thread const float3& ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _3336 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    float3 _3360 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    float3 _3376 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    float4 param_4 = m;\n    float3 param_5 = _3336;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    float3 param_8 = _3360;\n    float4 param_9 = m;\n    float3 param_10 = _3336;\n    float3 param_11 = _3360;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    float3 param_13 = _3376;\n    float4 param_14 = m;\n    float3 param_15 = _3336;\n    float3 param_16 = _3376;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_ltc_uv(thread const float& roughness, thread const float& ndv)\n{\n    return ((float2(fast::clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(fast::clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + float2(0.5)) * float2(0.015625);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_shade(thread const int& li, thread const float3& world_pos, thread const float3& n, thread const float3& v, thread const float3& diffuse_color, thread const float3& f0, thread const float& roughness, thread const float& ndv, thread const float& window, constant fa_mesh_fs_params& _381, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    int param = li;\n    int _3434 = fa_light_base(param, _381);\n    int param_1 = _3434;\n    int param_2 = _3434 + 1;\n    int param_3 = _3434 + 2;\n    int param_4 = _3434 + 4;\n    float4 _3456 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n    int param_5 = _3434 + 5;\n    float4 _3461 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n    int param_6 = _3434 + 6;\n    float4 _3466 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    float _3467 = _3466.w;\n    float3 _3472 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).xyz - world_pos;\n    bool _3474 = _3467 < 1.5;\n    bool _3481;\n    if (_3474)\n    {\n        _3481 = dot(fast::normalize(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz), _3472) >= 0.0;\n    }\n    else\n    {\n        _3481 = _3474;\n    }\n    if (_3481)\n    {\n        return float3(0.0);\n    }\n    bool _3490 = (_3467 > 0.5) && _3474;\n    float _3494 = _3490 ? 1.0539000034332275390625 : 1.0;\n    float3 _3497 = _3456.xyz;\n    float _3499 = _3456.w;\n    float3 _3505 = _3461.xyz;\n    float _3507 = _3461.w;\n    float3 up = _3505 * (_3507 * _3494);\n    float _3513;\n    if (_3490)\n    {\n        _3513 = (3.1415927410125732421875 * _3499) * _3499;\n    }\n    else\n    {\n        _3513 = (4.0 * _3499) * _3507;\n    }\n    if (_3467 > 1.5)\n    {\n        float3 _3539 = cross(_3497, -_3472);\n        float3 perp = _3539;\n        float _3543 = dot(_3539, _3539);\n        float3 _3546;\n        if (_3543 > 1.0000000133514319600180897396058e-10)\n        {\n            _3546 = perp * rsqrt(_3543);\n        }\n        else\n        {\n            _3546 = _3505;\n        }\n        perp = _3546;\n        up = _3546 * _3507;\n    }\n    float _3567 = fast::max(_3513, 9.9999999747524270787835121154785e-07);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _3577 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _3577;\n    float3 param_10 = n;\n    float3 param_11 = _3472;\n    float3 _3585 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _3577;\n    float3 param_13 = n;\n    float3 param_14 = _3497 * (_3499 * _3494);\n    float3 _3593 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _3577;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _3601 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _3467;\n    float3 param_20 = _3585;\n    float3 param_21 = _3593;\n    float3 param_22 = _3601;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _3620 = fa_ltc_uv(param_23, param_24) * 64.0;\n    float2 param_25 = _3620;\n    float2 param_26 = _3620 + float2(64.0, 0.0);\n    float4 _3630 = fa_atlas_fetch(param_26, fa_light_atlas, fa_env_smp);\n    float4 param_27 = fa_atlas_fetch(param_25, fa_light_atlas, fa_env_smp);\n    float param_28 = _3467;\n    float3 param_29 = _3585;\n    float3 param_30 = _3593;\n    float3 param_31 = _3601;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _3630.x) + ((float3(1.0) - f0) * _3630.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2, fa_light_tex, fa_shadow_smp).xyz) * ((((3.1415927410125732421875 * dot(_3472, _3472)) + _3567) / _3567) * window);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _2445 = tdh / at;\n    float _2449 = bdh / ab;\n    float _2461 = ((_2445 * _2445) + (_2449 * _2449)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2461) * _2461);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _2542 = 1.0 / alpha;\n    return ((2.0 + _2542) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2542)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _2575 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2654 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2654) * _2654);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2575);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2575));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2727 = fast::max(dot(L.nc, l), 0.0);\n        float _2733 = fast::max(dot(L.nc, h), 0.0);\n        float _2742 = ((_2733 * _2733) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2742) * _2742)) * (0.5 / fast::max(mix((2.0 * _2727) * L.coat_ndv, _2727 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2727)) * _2727);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, constant fa_mesh_fs_params& _381, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _381) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1842 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1845 = _1842.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1845 * _1845, exp2((-9.27999973297119140625) * ndv)) * _1845) + _1842.y)) + _1842.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _381, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_381.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _381.fa_env_horizon.w)).xyz;\n    }\n    float _1747 = rough * rough;\n    float _1777 = 0.60000002384185791015625 * _1747;\n    return mix(mix(_381.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_381.fa_env_horizon.xyz, _381.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1747)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1777, 0.0500000007450580596923828125 + _1777, d.y))), ((_381.fa_env_sky.xyz + _381.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1747 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _381, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2328;\n        if (L.aniso >= 0.0)\n        {\n            _2328 = L.b;\n        }\n        else\n        {\n            _2328 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2328, v), _2328), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2361 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _381, fa_env_smp, fa_env_tex) * ((f0 * _2361.x) + (float3(L.f90) * _2361.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _381, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2416 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _381, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _2416.x) + _2416.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _381, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1884 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _381, fa_env_smp, fa_env_tex) * ((f0 * _1884.x) + float3(_1884.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1094)\n{\n    if (_1094.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1635 = int(_1094.fa_shadow_cfg.x + 0.5);\n    float _1645 = dot(world - _1094.fa_shadow_eye.xyz, _1094.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1650 = _1635 > 0;\n    bool _1659;\n    if (_1650)\n    {\n        int param = _1635 - 1;\n        _1659 = _1645 <= fa_shadow_split_at(param, _1094);\n    }\n    else\n    {\n        _1659 = _1650;\n    }\n    if (_1659)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1666 = _1635 > 1;\n        bool _1673;\n        if (_1666)\n        {\n            _1673 = _1645 > _1094.fa_shadow_split.x;\n        }\n        else\n        {\n            _1673 = _1666;\n        }\n        if (_1673)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1679 = _1635 > 2;\n        bool _1686;\n        if (_1679)\n        {\n            _1686 = _1645 > _1094.fa_shadow_split.y;\n        }\n        else\n        {\n            _1686 = _1679;\n        }\n        if (_1686)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1692 = _1635 > 3;\n        bool _1699;\n        if (_1692)\n        {\n            _1699 = _1645 > _1094.fa_shadow_split.z;\n        }\n        else\n        {\n            _1699 = _1692;\n        }\n        if (_1699)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _381 [[buffer(1)]], constant fa_material& _4058 [[buffer(5)]], constant fa_shadows& _1094 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> mask [[texture(6)]], texturecube<float> fa_env_tex [[texture(7)]], texturecube<float> fa_irr_tex [[texture(8)]], texture2d<float> fa_light_tex [[texture(9)]], texture2d<float> fa_light_atlas [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler mask_smp [[sampler(2)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4632 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4632 = -_4632;\n    }\n    float3 _4039 = fast::normalize(_381.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _381, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4632, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4039, short(gl_FrontFacing) };\n    Surface _4047 = fa_standard_surface(param_1, _381, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4663 = _4047.albedo;\n    float _4664 = _4047.alpha;\n    float3 _4665 = _4047.normal;\n    float _4666 = _4047.metallic;\n    float _4667 = _4047.roughness;\n    float _4668 = _4047.occlusion;\n    float3 _4669 = _4047.emission;\n    float _4670 = _4047.clearcoat;\n    float _4671 = _4047.clearcoat_roughness;\n    float3 _4672 = _4047.sheen_color;\n    float _4673 = _4047.sheen_roughness;\n    float _4674 = _4047.anisotropy;\n    float _4675 = _4047.anisotropy_rotation;\n    float _4676 = _4047.specular;\n    float _4677 = _4047.ior;\n    float3 _4678 = _4047.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4632, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4039, short(gl_FrontFacing) };\n    Surface param_3 = _4047;\n    surface(param_2, param_3, mask, mask_smp);\n    _4663 = param_3.albedo;\n    _4664 = param_3.alpha;\n    _4665 = param_3.normal;\n    _4666 = param_3.metallic;\n    _4667 = param_3.roughness;\n    _4668 = param_3.occlusion;\n    _4669 = param_3.emission;\n    _4670 = param_3.clearcoat;\n    _4671 = param_3.clearcoat_roughness;\n    _4672 = param_3.sheen_color;\n    _4673 = param_3.sheen_roughness;\n    _4674 = param_3.anisotropy;\n    _4675 = param_3.anisotropy_rotation;\n    _4676 = param_3.specular;\n    _4677 = param_3.ior;\n    _4678 = param_3.specular_color;\n    if (param_3.alpha < _4058.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    float3 result;\n    if (_381.fa_emissive.w > 0.5)\n    {\n        result = _4663;\n    }\n    else\n    {\n        float3 _4080 = fast::normalize(_4665);\n        float _4087 = fast::clamp(_4666, 0.0, 1.0);\n        float _4091 = fast::clamp(_4667, 0.0500000007450580596923828125, 1.0);\n        float _4095 = _4091 * _4091;\n        float _4099 = _4095 * _4095;\n        float _4104 = fast::max(dot(_4080, _4039), 9.9999997473787516355514526367188e-05);\n        float3 _4110 = _4663 * (1.0 - _4087);\n        float3 _4117 = mix(float3(0.039999999105930328369140625), _4663, float3(_4087));\n        float3 f0 = _4117;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _4632, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4039, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _4663, _4664, _4665, _4666, _4667, _4668, _4669, _4670, _4671, _4672, _4673, _4674, _4675, _4676, _4677, _4678 };\n        float3 param_6 = _4080;\n        float3 param_7 = _4039;\n        float param_8 = _4087;\n        float param_9 = _4091;\n        float3 param_10 = _4117;\n        FaLayers _4133 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _4080;\n        float3 lit = (fa_ambient_light(param_11, _381, fa_env_smp, fa_irr_tex) * _4110) * _4668;\n        if (_4133.on)\n        {\n            lit *= _4133.base_scale;\n        }\n        int _4155 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4155; ln++)\n        {\n            int param_12 = ln;\n            int _4168 = fa_cl_light(param_12, _381, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            int param_13 = _4168;\n            float3 param_14 = in.fa_world_pos;\n            float3 param_15 = _4632;\n            LightSample _4177 = fa_light_shadowed(param_13, param_14, param_15, _381, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _1094, fa_shadow_tex, in.fa_world_pos);\n            float _4185 = fast::max(dot(_4080, _4177.direction), 0.0);\n            float _4191 = _4177.attenuation * _4177.shadow;\n            float3 _4196 = fast::normalize(_4177.direction + _4039);\n            float _4201 = fast::max(dot(_4080, _4196), 0.0);\n            float _4206 = fast::max(dot(_4039, _4196), 0.0);\n            bool _4213;\n            if (fa_light_is_area)\n            {\n                _4213 = !_4133.on;\n            }\n            else\n            {\n                _4213 = fa_light_is_area;\n            }\n            if (_4213)\n            {\n                int param_16 = _4168;\n                float3 param_17 = in.fa_world_pos;\n                float3 param_18 = _4080;\n                float3 param_19 = _4039;\n                float3 param_20 = _4110;\n                float3 param_21 = f0;\n                float param_22 = _4091;\n                float param_23 = _4104;\n                float param_24 = _4191;\n                lit += fa_area_shade(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, _381, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp);\n            }\n            else\n            {\n                if (_4133.on)\n                {\n                    FaLayers param_25 = _4133;\n                    float3 param_26 = _4110;\n                    float3 param_27 = f0;\n                    float3 param_28 = _4080;\n                    float3 param_29 = _4039;\n                    float3 param_30 = _4177.direction;\n                    float3 param_31 = _4196;\n                    float param_32 = _4185;\n                    float param_33 = _4104;\n                    float param_34 = _4201;\n                    float param_35 = _4206;\n                    float param_36 = _4095;\n                    float param_37 = _4099;\n                    int param_38 = _4168;\n                    lit += (fa_layers_light(param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33, param_34, param_35, param_36, param_37) * ((fa_light_rgb(param_38, _381, fa_light_tex, fa_shadow_smp) * fa_light_tint) * _4191));\n                }\n                else\n                {\n                    float _4288 = ((_4201 * _4201) * (_4099 - 1.0)) + 1.0;\n                    int param_39 = _4168;\n                    lit += (((_4110 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _4206, 5.0))) * (((_4099 / ((3.1415927410125732421875 * _4288) * _4288)) * (0.5 / fast::max(mix((2.0 * _4185) * _4104, _4185 + _4104, _4095), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4185))) * (fa_light_rgb(param_39, _381, fa_light_tex, fa_shadow_smp) * fa_light_tint)) * (_4185 * _4191));\n                }\n            }\n        }\n        if (_4133.on)\n        {\n            FaLayers param_40 = _4133;\n            float3 param_41 = _4080;\n            float3 param_42 = _4039;\n            float3 param_43 = f0;\n            float param_44 = _4091;\n            lit += (fa_layers_ibl(param_40, param_41, param_42, param_43, param_44, _381, fa_env_smp, fa_env_tex) * _4668);\n        }\n        else\n        {\n            float3 param_45 = _4080;\n            float3 param_46 = _4039;\n            float3 param_47 = f0;\n            float param_48 = _4091;\n            lit += (fa_sky_reflection(param_45, param_46, param_47, param_48, _381, fa_env_smp, fa_env_tex) * _4668);\n        }\n        result = lit;\n    }\n    float3 _4383 = result;\n    float3 _4384 = _4383 + _4669;\n    result = _4384;\n    float3 param_49 = _4384;\n    float3 param_50 = in.fa_world_pos;\n    result = fa_shadow_debug(param_49, param_50, _1094);\n    bool _4393 = _381.fa_fog.w > 0.0;\n    bool _4400;\n    if (!_4393)\n    {\n        _4400 = _381.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4400 = _4393;\n    }\n    if (_4400)\n    {\n        float3 _4409 = in.fa_world_pos - _381.fa_camera_pos.xyz;\n        float _4415 = dot(_4409, _381.fa_fog_c.xyz);\n        bool _4419 = _381.fa_fog_c.w > 0.5;\n        float _4420;\n        if (_4419)\n        {\n            _4420 = _4415;\n        }\n        else\n        {\n            _4420 = length(_4409);\n        }\n        float _4432 = _4420 - _381.fa_fog_b.x;\n        if (_4432 > 0.0)\n        {\n            float _4441 = _381.fa_fog.w * _4432;\n            float tau = _4441 * _4441;\n            if (_381.fa_fog_b.y > 0.0)\n            {\n                float _4457;\n                if (_4419)\n                {\n                    _4457 = in.fa_world_pos.y - (_381.fa_fog_c.y * _4415);\n                }\n                else\n                {\n                    _4457 = _381.fa_camera_pos.y;\n                }\n                float _4478 = mix(_4457, in.fa_world_pos.y, fast::clamp(_381.fa_fog_b.x / _4420, 0.0, 1.0));\n                float _4482 = in.fa_world_pos.y - _4478;\n                float _4487 = _4478 - _381.fa_fog_b.z;\n                float _4492 = in.fa_world_pos.y - _381.fa_fog_b.z;\n                bool _4495 = _4487 <= 0.0;\n                bool _4496 = !_4495;\n                bool _4502;\n                if (_4496)\n                {\n                    _4502 = _381.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4502 = _4495;\n                }\n                float _4503;\n                if (_4502)\n                {\n                    _4503 = _381.fa_fog_b.y;\n                }\n                else\n                {\n                    _4503 = _381.fa_fog_b.y * exp(-fast::min(_381.fa_fog_b.w * _4487, 80.0));\n                }\n                bool _4530;\n                if (_4496)\n                {\n                    _4530 = _381.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4530 = _4495;\n                }\n                float _4531;\n                if (_4530)\n                {\n                    _4531 = _381.fa_fog_b.y * _4487;\n                }\n                else\n                {\n                    _4531 = (_381.fa_fog_b.y * (1.0 - exp(-fast::min(_381.fa_fog_b.w * _4487, 80.0)))) / _381.fa_fog_b.w;\n                }\n                bool _4556 = _4492 <= 0.0;\n                bool _4563;\n                if (!_4556)\n                {\n                    _4563 = _381.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4563 = _4556;\n                }\n                float _4564;\n                if (_4563)\n                {\n                    _4564 = _381.fa_fog_b.y * _4492;\n                }\n                else\n                {\n                    _4564 = (_381.fa_fog_b.y * (1.0 - exp(-fast::min(_381.fa_fog_b.w * _4492, 80.0)))) / _381.fa_fog_b.w;\n                }\n                float _4591;\n                if (abs(_4482) < 0.001000000047497451305389404296875)\n                {\n                    _4591 = _4503;\n                }\n                else\n                {\n                    _4591 = (_4564 - _4531) / _4482;\n                }\n                tau += (_4432 * fast::max(_4591, 0.0));\n            }\n            result = mix(result, _381.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4664);\n    return out;\n}\n\n",
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
            "inst_name": "_381",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1094",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_4058",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 6
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
              "msl_texture_n": 7
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
              "msl_texture_n": 8
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
              "msl_texture_n": 9
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
              "msl_texture_n": 10
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
          },
          {
            "slot": 10,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _395 = _273.world_pos;\n    fa_world_pos = _395;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_395, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nconstant spvUnsafeArray<float, 63> _1985 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _381, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _863 = _381.fa_cl_info.x < 0.0;\n    bool _870;\n    if (!_863)\n    {\n        _870 = _381.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _870 = _863;\n    }\n    bool _878;\n    if (!_870)\n    {\n        _878 = _381.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _878 = _870;\n    }\n    bool _885;\n    if (!_878)\n    {\n        _885 = _381.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _885 = _878;\n    }\n    bool _892;\n    if (!_885)\n    {\n        _892 = _381.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _892 = _885;\n    }\n    if (_892)\n    {\n        return int2(0);\n    }\n    float4 _902 = float4(world_pos, 1.0);\n    float _909 = dot(_381.fa_cl_vpw, _902);\n    if (!(_909 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _931 = float2(dot(_381.fa_cl_vpx, _902), dot(_381.fa_cl_vpy, _902)) / float2(_909);\n    int _935 = int(_381.fa_cl_grid.x);\n    int _939 = int(_381.fa_cl_grid.y);\n    int param = (int(_381.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_381.fa_cl_fwd.xyz, world_pos) + _381.fa_cl_fwd.w, _381.fa_cl_grid.w) / _381.fa_cl_grid.w) * _381.fa_cl_grid.z)), 0, int(_381.fa_cl_info.y) - 1) * _939) + clamp(int(floor(((_931.y * 0.5) + 0.5) * _381.fa_cl_grid.y)), 0, _939 - 1)) * _935)) + clamp(int(floor(((_931.x * 0.5) + 0.5) * _381.fa_cl_grid.x)), 0, _935 - 1);\n    float4 _1010 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1010.x), int(_1010.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _381, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_381.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2802 = fa_cluster_lookup(param, _381, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _2802.x;\n    fa_cl_local = _2802.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3727 = fa_linear_to_srgb(param);\n        c = _3727;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3735 = fa_srgb_to_linear(param_1);\n            c = _3735;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _313;\n    if (bool(i.front_facing))\n    {\n        _313 = i.world_normal;\n    }\n    else\n    {\n        _313 = -i.world_normal;\n    }\n    float3 _337 = fast::normalize(i.world_tangent.xyz - (_313 * dot(_313, i.world_tangent.xyz)));\n    float3 _365 = fast::normalize(((_337 * m.x) + ((cross(_313, _337) * i.world_tangent.w) * m.y)) + (_313 * m.z));\n    float3 _368;\n    if (bool(i.front_facing))\n    {\n        _368 = _365;\n    }\n    else\n    {\n        _368 = -_365;\n    }\n    return _368;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _381, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _381.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3766 = fa_tex_fix(param_2, param_3);\n    float4 _5007 = base_t;\n    _5007.x = _3766.x;\n    _5007.y = _3766.y;\n    _5007.z = _3766.z;\n    base_t = _5007;\n    float4 _3780 = (_5007 * _381.fa_base_color) * i.vertex_color;\n    float3 _4917 = i.world_normal;\n    if (_381.fa_maps.z > 0.5)\n    {\n        float param_4 = _381.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3812 = fa_tex_fix(param_6, param_7);\n        float3 _3815 = (_3812 * 2.0) - float3(1.0);\n        float2 _3820 = _3815.xy * _381.fa_maps.x;\n        float3 _5015 = _3815;\n        _5015.x = _3820.x;\n        _5015.y = _3820.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5015;\n        _4917 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _381.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3848 = fa_tex_fix(param_12, param_13);\n    float4 _5018 = mrt;\n    _5018.x = _3848.x;\n    _5018.y = _3848.y;\n    _5018.z = _3848.z;\n    mrt = _5018;\n    float4 _3876 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _381.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3876.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3888 = fa_tex_fix(param_16, param_17);\n    float param_18 = _381.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3918 = fa_tex_fix(param_20, param_21);\n    float _4922 = _381.fa_layers_a.x;\n    float _4923 = _381.fa_layers_a.y;\n    float _4926 = _381.fa_layers_a.z;\n    float _4925 = _381.fa_layers_b.w;\n    float _4928 = _381.fa_layers_c.x;\n    if (_381.fa_layers_c.z > 0.5)\n    {\n        if (mod(_381.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4922 *= _3888.y;\n            _4923 *= _3888.z;\n            _4925 *= _3876.w;\n        }\n        if (_381.fa_layers_c.z > 1.5)\n        {\n            _4926 *= mrt.x;\n            _4928 *= mrt.w;\n        }\n    }\n    return Surface{ _3780.xyz, _3780.w, _4917, fast::clamp(_381.fa_pbr.x * _3848.z, 0.0, 1.0), fast::clamp(_381.fa_pbr.y * _3848.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_381.fa_maps.y * (_3888.x - 1.0)), _381.fa_emissive.xyz + (_381.fa_model_emissive.xyz * _3918), _4922, _4923, _381.fa_layers_b.xyz, _4925, _4926, _381.fa_layers_a.w, _4928, _381.fa_layers_c.y, _381.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1910 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1918 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1921 = int(_1910);\n    int _1924 = int(_1918);\n    float _1934 = _1918 - float(_1924);\n    int _1990 = (_1921 * 9) + _1924;\n    int _2010 = ((_1921 + 1) * 9) + _1924;\n    return mix(mix(_1985[_1990], _1985[_1990 + 1], _1934), mix(_1985[_2010], _1985[_2010 + 1], _1934), _1910 - float(_1921));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4853 = false;\n    float _4854 = 1.0;\n    float _4855 = 1.0;\n    float _4856 = 1.0;\n    float _4857 = 0.0;\n    float _4858 = 0.0;\n    float _4859 = 0.0;\n    float _4860 = 0.0;\n    float _4862 = 1.0;\n    bool _4863 = false;\n    float3 _4864 = float3(0.0);\n    float _4865 = 1.0;\n    float _4866 = 1.0;\n    float _4867 = 1.0;\n    float _4868 = 0.0;\n    float _4869 = 0.0;\n    float3 _4870 = float3(1.0, 0.0, 0.0);\n    float3 _4871 = float3(0.0, 0.0, 1.0);\n    float _4872 = 1.0;\n    float _4873 = 1.0;\n    float _2064 = fast::clamp(s.specular, 0.0, 1.0);\n    float _2068 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _2073 = (_2064 != 1.0) || (_2068 != 1.5);\n    bool _2082;\n    if (!_2073)\n    {\n        _2082 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _2082 = _2073;\n    }\n    if (_2082)\n    {\n        float _2090 = (_2068 - 1.0) / (_2068 + 1.0);\n        f0 = mix(fast::min(float3(_2090 * _2090) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _2064, s.albedo, float3(metallic));\n        _4854 = mix(_2064, 1.0, metallic);\n        _4853 = true;\n    }\n    float _2118 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_2118 > 0.0)\n    {\n        float _2126 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4857 = _2118;\n        _4858 = _2126;\n        float _2133 = _2126 * _2126;\n        _4859 = _2133;\n        _4860 = _2133 * _2133;\n        float _2145 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4862 = _2145;\n        _4855 = 1.0 - (_2118 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _2145, 0.0, 1.0), 5.0))));\n        _4853 = true;\n    }\n    float3 _2165 = fast::max(s.sheen_color, float3(0.0));\n    float _2174 = fast::max(_2165.x, fast::max(_2165.y, _2165.z));\n    if (_2174 > 0.0)\n    {\n        float _2182 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4863 = true;\n        _4864 = _2165;\n        _4865 = _2182;\n        _4866 = _2182 * _2182;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2182;\n        float _2199 = fa_sheen_albedo(param, param_1);\n        _4868 = _2199;\n        _4867 = 1.0 - fast::min(_2174 * _2199, 1.0);\n        _4853 = true;\n    }\n    _4856 = _4855 * _4867;\n    float _2218 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_2218 != 0.0)\n    {\n        float3 _2233 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _2233;\n        if (dot(_2233, _2233) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _2251 = t;\n        float3 _2252 = fast::normalize(_2251);\n        t = _2252;\n        float3 _2277 = fast::normalize((_2252 * cos(s.anisotropy_rotation)) + ((cross(n, _2252) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4870 = _2277;\n        _4871 = cross(n, _2277);\n        float _2287 = roughness * roughness;\n        float _2293 = mix(_2287, 1.0, _2218 * _2218);\n        bool _2295 = _2218 > 0.0;\n        _4872 = _2295 ? _2293 : _2287;\n        _4873 = _2295 ? _2287 : _2293;\n        _4869 = _2218;\n        _4853 = true;\n    }\n    return FaLayers{ short(_4853), _4854, _4855, _4856, _4857, _4858, _4859, _4860, i.world_normal, _4862, short(_4863), _4864, _4865, _4866, _4867, _4868, _4869, _4870, _4871, _4872, _4873 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _381, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_381.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _381.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _381, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_381.fa_cl_info.x) + int(_381.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _381, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _381, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _381)\n{\n    return li * ((_381.fa_counts.y > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _471 = dot(d, right);\n    float _475 = dot(d, up);\n    float _486;\n    if (((_471 * _471) + (_475 * _475)) > 1.0000000133514319600180897396058e-10)\n    {\n        _486 = precise::atan2(_475, _471) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _486 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_486 - floor(_486)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_mesh_fs_params& _381, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _519 = fa_light_base(param, _381);\n    bool _523 = _381.fa_counts.y > 4.5;\n    int param_1 = _519;\n    float4 _527 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _519 + 1;\n    float4 _532 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _535 = _532.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _547 = _523 && (_535 > 2.5);\n    fa_light_is_area = _547;\n    bool _550 = _535 < 0.5;\n    float3 l;\n    if (_550)\n    {\n        l = fast::normalize(_527.xyz);\n        if (_523)\n        {\n            int param_3 = _519 + 6;\n            float4 _564 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_564.z > 0.5)\n            {\n                int param_4 = _519 + 4;\n                float4 _574 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _519 + 5;\n                float4 _580 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _564.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _574.xyz) * _574.w, (-dot(world_pos, _580.xyz)) * _580.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _612 = _527.xyz - world_pos;\n        float _614 = length(_612);\n        dist = _614;\n        l = _612 / float3(fast::max(_614, 9.9999997473787516355514526367188e-05));\n        float reach = _614;\n        if (_547)\n        {\n            int param_8 = _519 + 7;\n            reach = fast::max(dist - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n        }\n        float _646 = reach / fast::max(_527.w, 0.001000000047497451305389404296875);\n        float _652 = fast::clamp(1.0 - (_646 * _646), 0.0, 1.0);\n        atten = _652 * _652;\n        bool _660 = _535 < 2.5;\n        if ((_535 > 1.5) && _660)\n        {\n            int param_9 = _519 + 2;\n            float4 _668 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            float _678 = _668.w;\n            int param_10 = _519 + 3;\n            float4 _684 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            float _685 = _684.x;\n            float cos_inner = _685;\n            if (_685 > 1.5)\n            {\n                cos_inner = mix(_678, 1.0, 0.25);\n            }\n            atten *= smoothstep(_678, cos_inner, dot(-l, fast::normalize(_668.xyz)));\n        }\n        if (_523 && _660)\n        {\n            int param_11 = _519 + 6;\n            float4 _709 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            int param_12 = _519 + 7;\n            float4 _714 = fa_light_texel(param_12, fa_light_tex, fa_shadow_smp);\n            bool _717 = _709.z > 0.5;\n            bool _724;\n            if (!_717)\n            {\n                _724 = _714.z > 0.5;\n            }\n            else\n            {\n                _724 = _717;\n            }\n            if (_724)\n            {\n                int param_13 = _519 + 2;\n                float4 _731 = fa_light_texel(param_13, fa_light_tex, fa_shadow_smp);\n                float3 _735 = fast::normalize(_731.xyz);\n                int param_14 = _519 + 4;\n                float4 _740 = fa_light_texel(param_14, fa_light_tex, fa_shadow_smp);\n                int param_15 = _519 + 5;\n                float4 _745 = fa_light_texel(param_15, fa_light_tex, fa_shadow_smp);\n                if (_717)\n                {\n                    float3 _753 = -_612;\n                    float _760 = _731.w;\n                    float _776 = 0.5 / fast::max(dot(_753, _735) * (sqrt(fast::max(1.0 - (_760 * _760), 0.0)) / fast::max(_760, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    float2 param_16 = _709.xy;\n                    float2 param_17 = float2(0.5 + (dot(_753, _740.xyz) * _776), 0.5 - (dot(_753, _745.xyz) * _776));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17, fa_light_atlas, fa_env_smp);\n                }\n                if (_714.z > 0.5)\n                {\n                    float2 param_18 = _714.xy;\n                    float3 param_19 = -l;\n                    float3 param_20 = _735;\n                    float3 param_21 = _740.xyz;\n                    float3 param_22 = _745.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22, fa_light_atlas, fa_env_smp);\n                }\n            }\n        }\n    }\n    float3 _4841 = _532.xyz * atten;\n    if (_523)\n    {\n        _4841 *= fa_light_tint;\n    }\n    int _845;\n    if (_550)\n    {\n        _845 = 0;\n    }\n    else\n    {\n        _845 = ((_535 > 1.5) && (_535 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4841, atten, 1.0, dist, _845 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _1094)\n{\n    float _1084;\n    if (i == 0)\n    {\n        _1084 = _1094.fa_shadow_split.x;\n    }\n    else\n    {\n        float _1100;\n        if (i == 1)\n        {\n            _1100 = _1094.fa_shadow_split.y;\n        }\n        else\n        {\n            float _1108;\n            if (i == 2)\n            {\n                _1108 = _1094.fa_shadow_split.z;\n            }\n            else\n            {\n                _1108 = _1094.fa_shadow_split.w;\n            }\n            _1100 = _1108;\n        }\n        _1084 = _1100;\n    }\n    return _1084;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1072 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1072), sin(_1072)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1094, texture2d<float> fa_shadow_tex)\n{\n    float _1146 = fast::max(_1094.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _1151 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _1157 = sqrt(1.0 - (_1151 * _1151));\n    float _1165 = fast::min(_1157 / fast::max(_1151, 0.20000000298023223876953125), 4.0);\n    float _1170;\n    if (_1094.fa_shadow_bias.y > 0.0)\n    {\n        _1170 = _1094.fa_shadow_bias.y;\n    }\n    else\n    {\n        _1170 = 1.5 * _1094.fa_shadow_info[ci].x;\n    }\n    float4 _1195 = _1094.fa_shadow_mat[ci] * float4(world + (n * (_1170 * _1157)), 1.0);\n    float _1202 = _1195.x;\n    bool _1205 = _1202 < _1094.fa_shadow_rect[ci].x;\n    bool _1214;\n    if (!_1205)\n    {\n        _1214 = _1202 > _1094.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _1214 = _1205;\n    }\n    bool _1223;\n    if (!_1214)\n    {\n        _1223 = _1195.y < _1094.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _1223 = _1214;\n    }\n    bool _1232;\n    if (!_1223)\n    {\n        _1232 = _1195.y > _1094.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _1232 = _1223;\n    }\n    bool _1239;\n    if (!_1232)\n    {\n        _1239 = _1195.z > 1.0;\n    }\n    else\n    {\n        _1239 = _1232;\n    }\n    if (_1239)\n    {\n        return -1.0;\n    }\n    float _1247;\n    if (_1094.fa_shadow_bias.x > 0.0)\n    {\n        _1247 = _1094.fa_shadow_bias.x;\n    }\n    else\n    {\n        _1247 = 1.5 * _1094.fa_shadow_info[ci].x;\n    }\n    float _1266 = _1195.z - ((_1247 * (1.0 + (0.5 * _1165))) / _1146);\n    float _1275 = ((_1094.fa_shadow_info[ci].x * fast::min(_1165, 3.0)) * 0.5) / _1146;\n    int _1284 = int(_1094.fa_shadow_cfg.z + 0.5);\n    if (_1284 == 1)\n    {\n        float2 param = _1195.xy;\n        float4 param_1 = _1094.fa_shadow_rect[ci];\n        float _1295 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_1266 <= _1295);\n    }\n    float _1302 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1305 = _1284 == 2;\n    if (_1305)\n    {\n        float _1319 = fast::clamp(((_1094.fa_shadow_cfg.w * _1146) * 0.25) / _1094.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1302;\n            float2 _1338 = fa_shadow_vogel(param_2, param_3, param_4) * _1319;\n            float2 param_5 = _1195.xy + (_1338 * _1094.fa_shadow_bias.zw);\n            float4 param_6 = _1094.fa_shadow_rect[ci];\n            float _1349 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_1349 < (_1266 - (length(_1338) * _1275)))\n            {\n                sum += _1349;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_1266 - (sum / cnt), 0.0) * _1146) * _1094.fa_shadow_cfg.w) / _1094.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1393 = _1305 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1393; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1393;\n        float param_9 = _1302;\n        float2 _1412 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _1195.xy + (_1412 * _1094.fa_shadow_bias.zw);\n        float4 param_11 = _1094.fa_shadow_rect[ci];\n        float _1423 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_1266 - (length(_1412) * _1275)) <= _1423);\n    }\n    return lit / float(_1393);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _381, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1094, texture2d<float> fa_shadow_tex)\n{\n    if (_381.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1453 = int(_1094.fa_shadow_cfg.x + 0.5);\n    if (_1453 < 1)\n    {\n        return 1.0;\n    }\n    float _1468 = dot(world - _1094.fa_shadow_eye.xyz, _1094.fa_shadow_fwd.xyz);\n    int param = _1453 - 1;\n    if (_1468 > fa_shadow_split_at(param, _1094))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1480 = _1453 > 1;\n    bool _1487;\n    if (_1480)\n    {\n        _1487 = _1468 > _1094.fa_shadow_split.x;\n    }\n    else\n    {\n        _1487 = _1480;\n    }\n    if (_1487)\n    {\n        ci = 1;\n    }\n    bool _1491 = _1453 > 2;\n    bool _1498;\n    if (_1491)\n    {\n        _1498 = _1468 > _1094.fa_shadow_split.y;\n    }\n    else\n    {\n        _1498 = _1491;\n    }\n    if (_1498)\n    {\n        ci = 2;\n    }\n    bool _1502 = _1453 > 3;\n    bool _1509;\n    if (_1502)\n    {\n        _1509 = _1468 > _1094.fa_shadow_split.z;\n    }\n    else\n    {\n        _1509 = _1502;\n    }\n    if (_1509)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1453)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1535 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _1094, fa_shadow_tex);\n        s = _1535;\n        if (_1535 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_1094.fa_shadow_cfg.y > 0.0)\n    {\n        float _1560;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1560 = fa_shadow_split_at(param_5, _1094);\n        }\n        else\n        {\n            _1560 = _1094.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1579 = _1094.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _1094) - _1560, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1590 = fast::clamp((_1468 - (fa_shadow_split_at(param_7, _1094) - _1579)) / _1579, 0.0, 1.0);\n        if (_1590 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1453)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1611 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _1094, fa_shadow_tex);\n                s2 = _1611;\n                if (_1611 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1590);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _381, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _1094, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _381, fa_shadow_smp, gl_FragCoord, _1094, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _381, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _1094, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2830 = fa_light_sample(param, param_1, _381, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4897 = _2830.color;\n    float _4899 = _2830.shadow;\n    if ((_2830.type == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _2830.direction;\n        float _2844 = fa_shadow_factor(param_2, param_3, _381, fa_shadow_smp, gl_FragCoord, _1094, fa_shadow_tex, fa_world_pos);\n        _4899 = _2844;\n        _4897 *= _2844;\n    }\n    return LightSample{ _2830.direction, _4897, _2830.attenuation, _4899, _2830._distance, _2830.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_tangent(thread const float3& n, thread const float3& v)\n{\n    float3 _2884 = v - (n * dot(v, n));\n    float3 t = _2884;\n    float _2888 = dot(_2884, _2884);\n    float l2 = _2888;\n    if (_2888 < 1.0000000133514319600180897396058e-10)\n    {\n        float3 _2898;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _2898 = cross(n, float3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _2898 = cross(n, float3(1.0, 0.0, 0.0));\n        }\n        t = _2898;\n        l2 = dot(_2898, _2898);\n    }\n    return t * rsqrt(l2);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_local(thread const float3& t1, thread const float3& n, thread const float3& p)\n{\n    return float3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ltc_edge_vector(thread const float3& a, thread const float3& b)\n{\n    float _2933 = dot(a, a);\n    float _2937 = dot(b, b);\n    if ((_2933 < 1.0000000195414813782625560981111e-24) || (_2937 < 1.0000000195414813782625560981111e-24))\n    {\n        return float3(0.0);\n    }\n    float3 _2951 = a * rsqrt(_2933);\n    float3 _2956 = b * rsqrt(_2937);\n    float _2960 = dot(_2951, _2956);\n    float _2963 = abs(_2960);\n    float g = (((((((((((0.0416471660137176513671875 * _2963) - 0.1924748718738555908203125) * _2963) + 0.4179156124591827392578125) * _2963) - 0.616057217121124267578125) * _2963) + 0.777722418308258056640625) * _2963) - 0.999542415142059326171875) * _2963) + 1.570791721343994140625;\n    if (_2960 < 0.0)\n    {\n        g = (3.1415927410125732421875 * rsqrt(fast::max(1.0 - (_2960 * _2960), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_2951, _2956) * g;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_ltc_clip_edge(thread const float3& a, thread const float3& b, thread float3& sum, thread float3& leave, thread float3& enter, thread float2& seen)\n{\n    bool _3020 = a.z > 0.0;\n    bool _3024 = b.z > 0.0;\n    if (_3020 && _3024)\n    {\n        float3 param = a;\n        float3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_3020 != _3024)\n        {\n            float3 _3059 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _3059.z = 0.0;\n            if (_3020)\n            {\n                float3 param_2 = a;\n                float3 param_3 = _3059;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _3059;\n                seen.x = 1.0;\n            }\n            else\n            {\n                float3 param_4 = _3059;\n                float3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _3059;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ltc_quad(thread const float4& abcd, thread const float3& p0, thread const float3& p1, thread const float3& p2, thread const float3& p3)\n{\n    float3 _3108 = float3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    float3 _3134 = float3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    float3 _3160 = float3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    float3 _3186 = float3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    float3 sum = float3(0.0);\n    float3 leave = float3(0.0);\n    float3 enter = float3(0.0);\n    float3 param = _3108;\n    float3 param_1 = _3134;\n    float3 param_2 = float3(0.0);\n    float3 param_3 = float3(0.0);\n    float3 param_4 = float3(0.0);\n    float2 param_5 = float2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    float3 param_6 = _3134;\n    float3 param_7 = _3160;\n    float3 param_8 = param_2;\n    float3 param_9 = param_3;\n    float3 param_10 = param_4;\n    float2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    float3 param_12 = _3160;\n    float3 param_13 = _3186;\n    float3 param_14 = param_8;\n    float3 param_15 = param_9;\n    float3 param_16 = param_10;\n    float2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    float3 param_18 = _3186;\n    float3 param_19 = _3108;\n    float3 param_20 = param_14;\n    float3 param_21 = param_15;\n    float3 param_22 = param_16;\n    float2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        float3 param_24 = leave;\n        float3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ltc_rect(thread const float4& abcd, thread const float3& center, thread const float3& ex, thread const float3& ey)\n{\n    float4 param = abcd;\n    float3 param_1 = (center - ex) - ey;\n    float3 param_2 = (center + ex) - ey;\n    float3 param_3 = (center + ex) + ey;\n    float3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_area_form(thread const float4& m, thread const float& shape, thread const float3& pc, thread const float3& ex, thread const float3& ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        float4 param = m;\n        float3 param_1 = pc;\n        float3 param_2 = ex;\n        float3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    float3 _3336 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    float3 _3360 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    float3 _3376 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    float4 param_4 = m;\n    float3 param_5 = _3336;\n    float3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    float3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    float3 param_8 = _3360;\n    float4 param_9 = m;\n    float3 param_10 = _3336;\n    float3 param_11 = _3360;\n    float3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    float3 param_13 = _3376;\n    float4 param_14 = m;\n    float3 param_15 = _3336;\n    float3 param_16 = _3376;\n    float3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    float3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_ltc_uv(thread const float& roughness, thread const float& ndv)\n{\n    return ((float2(fast::clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(fast::clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + float2(0.5)) * float2(0.015625);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_shade(thread const int& li, thread const float3& world_pos, thread const float3& n, thread const float3& v, thread const float3& diffuse_color, thread const float3& f0, thread const float& roughness, thread const float& ndv, thread const float& window, constant fa_mesh_fs_params& _381, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    int param = li;\n    int _3434 = fa_light_base(param, _381);\n    int param_1 = _3434;\n    int param_2 = _3434 + 1;\n    int param_3 = _3434 + 2;\n    int param_4 = _3434 + 4;\n    float4 _3456 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n    int param_5 = _3434 + 5;\n    float4 _3461 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n    int param_6 = _3434 + 6;\n    float4 _3466 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    float _3467 = _3466.w;\n    float3 _3472 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).xyz - world_pos;\n    bool _3474 = _3467 < 1.5;\n    bool _3481;\n    if (_3474)\n    {\n        _3481 = dot(fast::normalize(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp).xyz), _3472) >= 0.0;\n    }\n    else\n    {\n        _3481 = _3474;\n    }\n    if (_3481)\n    {\n        return float3(0.0);\n    }\n    bool _3490 = (_3467 > 0.5) && _3474;\n    float _3494 = _3490 ? 1.0539000034332275390625 : 1.0;\n    float3 _3497 = _3456.xyz;\n    float _3499 = _3456.w;\n    float3 _3505 = _3461.xyz;\n    float _3507 = _3461.w;\n    float3 up = _3505 * (_3507 * _3494);\n    float _3513;\n    if (_3490)\n    {\n        _3513 = (3.1415927410125732421875 * _3499) * _3499;\n    }\n    else\n    {\n        _3513 = (4.0 * _3499) * _3507;\n    }\n    if (_3467 > 1.5)\n    {\n        float3 _3539 = cross(_3497, -_3472);\n        float3 perp = _3539;\n        float _3543 = dot(_3539, _3539);\n        float3 _3546;\n        if (_3543 > 1.0000000133514319600180897396058e-10)\n        {\n            _3546 = perp * rsqrt(_3543);\n        }\n        else\n        {\n            _3546 = _3505;\n        }\n        perp = _3546;\n        up = _3546 * _3507;\n    }\n    float _3567 = fast::max(_3513, 9.9999999747524270787835121154785e-07);\n    float3 param_7 = n;\n    float3 param_8 = v;\n    float3 _3577 = fa_ltc_tangent(param_7, param_8);\n    float3 param_9 = _3577;\n    float3 param_10 = n;\n    float3 param_11 = _3472;\n    float3 _3585 = fa_ltc_local(param_9, param_10, param_11);\n    float3 param_12 = _3577;\n    float3 param_13 = n;\n    float3 param_14 = _3497 * (_3499 * _3494);\n    float3 _3593 = fa_ltc_local(param_12, param_13, param_14);\n    float3 param_15 = _3577;\n    float3 param_16 = n;\n    float3 param_17 = up;\n    float3 _3601 = fa_ltc_local(param_15, param_16, param_17);\n    float4 param_18 = float4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _3467;\n    float3 param_20 = _3585;\n    float3 param_21 = _3593;\n    float3 param_22 = _3601;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    float2 _3620 = fa_ltc_uv(param_23, param_24) * 64.0;\n    float2 param_25 = _3620;\n    float2 param_26 = _3620 + float2(64.0, 0.0);\n    float4 _3630 = fa_atlas_fetch(param_26, fa_light_atlas, fa_env_smp);\n    float4 param_27 = fa_atlas_fetch(param_25, fa_light_atlas, fa_env_smp);\n    float param_28 = _3467;\n    float3 param_29 = _3585;\n    float3 param_30 = _3593;\n    float3 param_31 = _3601;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _3630.x) + ((float3(1.0) - f0) * _3630.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2, fa_light_tex, fa_shadow_smp).xyz) * ((((3.1415927410125732421875 * dot(_3472, _3472)) + _3567) / _3567) * window);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _2445 = tdh / at;\n    float _2449 = bdh / ab;\n    float _2461 = ((_2445 * _2445) + (_2449 * _2449)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2461) * _2461);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _2542 = 1.0 / alpha;\n    return ((2.0 + _2542) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2542)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _2575 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2654 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2654) * _2654);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2575);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2575));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2727 = fast::max(dot(L.nc, l), 0.0);\n        float _2733 = fast::max(dot(L.nc, h), 0.0);\n        float _2742 = ((_2733 * _2733) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2742) * _2742)) * (0.5 / fast::max(mix((2.0 * _2727) * L.coat_ndv, _2727 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2727)) * _2727);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, constant fa_mesh_fs_params& _381, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _381) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1842 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1845 = _1842.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1845 * _1845, exp2((-9.27999973297119140625) * ndv)) * _1845) + _1842.y)) + _1842.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _381, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_381.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _381.fa_env_horizon.w)).xyz;\n    }\n    float _1747 = rough * rough;\n    float _1777 = 0.60000002384185791015625 * _1747;\n    return mix(mix(_381.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_381.fa_env_horizon.xyz, _381.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1747)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1777, 0.0500000007450580596923828125 + _1777, d.y))), ((_381.fa_env_sky.xyz + _381.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1747 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _381, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _2328;\n        if (L.aniso >= 0.0)\n        {\n            _2328 = L.b;\n        }\n        else\n        {\n            _2328 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_2328, v), _2328), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _2361 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _381, fa_env_smp, fa_env_tex) * ((f0 * _2361.x) + (float3(L.f90) * _2361.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _381, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2416 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _381, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _2416.x) + _2416.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _381, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1884 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _381, fa_env_smp, fa_env_tex) * ((f0 * _1884.x) + float3(_1884.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _1094)\n{\n    if (_1094.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1635 = int(_1094.fa_shadow_cfg.x + 0.5);\n    float _1645 = dot(world - _1094.fa_shadow_eye.xyz, _1094.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1650 = _1635 > 0;\n    bool _1659;\n    if (_1650)\n    {\n        int param = _1635 - 1;\n        _1659 = _1645 <= fa_shadow_split_at(param, _1094);\n    }\n    else\n    {\n        _1659 = _1650;\n    }\n    if (_1659)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1666 = _1635 > 1;\n        bool _1673;\n        if (_1666)\n        {\n            _1673 = _1645 > _1094.fa_shadow_split.x;\n        }\n        else\n        {\n            _1673 = _1666;\n        }\n        if (_1673)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1679 = _1635 > 2;\n        bool _1686;\n        if (_1679)\n        {\n            _1686 = _1645 > _1094.fa_shadow_split.y;\n        }\n        else\n        {\n            _1686 = _1679;\n        }\n        if (_1686)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1692 = _1635 > 3;\n        bool _1699;\n        if (_1692)\n        {\n            _1699 = _1645 > _1094.fa_shadow_split.z;\n        }\n        else\n        {\n            _1699 = _1692;\n        }\n        if (_1699)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _381 [[buffer(1)]], constant fa_material& _4058 [[buffer(5)]], constant fa_shadows& _1094 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> mask [[texture(6)]], texturecube<float> fa_env_tex [[texture(7)]], texturecube<float> fa_irr_tex [[texture(8)]], texture2d<float> fa_light_tex [[texture(9)]], texture2d<float> fa_light_atlas [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler mask_smp [[sampler(2)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4632 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4632 = -_4632;\n    }\n    float3 _4039 = fast::normalize(_381.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _381, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4632, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4039, short(gl_FrontFacing) };\n    Surface _4047 = fa_standard_surface(param_1, _381, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4663 = _4047.albedo;\n    float _4664 = _4047.alpha;\n    float3 _4665 = _4047.normal;\n    float _4666 = _4047.metallic;\n    float _4667 = _4047.roughness;\n    float _4668 = _4047.occlusion;\n    float3 _4669 = _4047.emission;\n    float _4670 = _4047.clearcoat;\n    float _4671 = _4047.clearcoat_roughness;\n    float3 _4672 = _4047.sheen_color;\n    float _4673 = _4047.sheen_roughness;\n    float _4674 = _4047.anisotropy;\n    float _4675 = _4047.anisotropy_rotation;\n    float _4676 = _4047.specular;\n    float _4677 = _4047.ior;\n    float3 _4678 = _4047.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4632, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4039, short(gl_FrontFacing) };\n    Surface param_3 = _4047;\n    surface(param_2, param_3, mask, mask_smp);\n    _4663 = param_3.albedo;\n    _4664 = param_3.alpha;\n    _4665 = param_3.normal;\n    _4666 = param_3.metallic;\n    _4667 = param_3.roughness;\n    _4668 = param_3.occlusion;\n    _4669 = param_3.emission;\n    _4670 = param_3.clearcoat;\n    _4671 = param_3.clearcoat_roughness;\n    _4672 = param_3.sheen_color;\n    _4673 = param_3.sheen_roughness;\n    _4674 = param_3.anisotropy;\n    _4675 = param_3.anisotropy_rotation;\n    _4676 = param_3.specular;\n    _4677 = param_3.ior;\n    _4678 = param_3.specular_color;\n    if (param_3.alpha < _4058.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    float3 result;\n    if (_381.fa_emissive.w > 0.5)\n    {\n        result = _4663;\n    }\n    else\n    {\n        float3 _4080 = fast::normalize(_4665);\n        float _4087 = fast::clamp(_4666, 0.0, 1.0);\n        float _4091 = fast::clamp(_4667, 0.0500000007450580596923828125, 1.0);\n        float _4095 = _4091 * _4091;\n        float _4099 = _4095 * _4095;\n        float _4104 = fast::max(dot(_4080, _4039), 9.9999997473787516355514526367188e-05);\n        float3 _4110 = _4663 * (1.0 - _4087);\n        float3 _4117 = mix(float3(0.039999999105930328369140625), _4663, float3(_4087));\n        float3 f0 = _4117;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _4632, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4039, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _4663, _4664, _4665, _4666, _4667, _4668, _4669, _4670, _4671, _4672, _4673, _4674, _4675, _4676, _4677, _4678 };\n        float3 param_6 = _4080;\n        float3 param_7 = _4039;\n        float param_8 = _4087;\n        float param_9 = _4091;\n        float3 param_10 = _4117;\n        FaLayers _4133 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _4080;\n        float3 lit = (fa_ambient_light(param_11, _381, fa_env_smp, fa_irr_tex) * _4110) * _4668;\n        if (_4133.on)\n        {\n            lit *= _4133.base_scale;\n        }\n        int _4155 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4155; ln++)\n        {\n            int param_12 = ln;\n            int _4168 = fa_cl_light(param_12, _381, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            int param_13 = _4168;\n            float3 param_14 = in.fa_world_pos;\n            float3 param_15 = _4632;\n            LightSample _4177 = fa_light_shadowed(param_13, param_14, param_15, _381, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _1094, fa_shadow_tex, in.fa_world_pos);\n            float _4185 = fast::max(dot(_4080, _4177.direction), 0.0);\n            float _4191 = _4177.attenuation * _4177.shadow;\n            float3 _4196 = fast::normalize(_4177.direction + _4039);\n            float _4201 = fast::max(dot(_4080, _4196), 0.0);\n            float _4206 = fast::max(dot(_4039, _4196), 0.0);\n            bool _4213;\n            if (fa_light_is_area)\n            {\n                _4213 = !_4133.on;\n            }\n            else\n            {\n                _4213 = fa_light_is_area;\n            }\n            if (_4213)\n            {\n                int param_16 = _4168;\n                float3 param_17 = in.fa_world_pos;\n                float3 param_18 = _4080;\n                float3 param_19 = _4039;\n                float3 param_20 = _4110;\n                float3 param_21 = f0;\n                float param_22 = _4091;\n                float param_23 = _4104;\n                float param_24 = _4191;\n                lit += fa_area_shade(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, _381, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp);\n            }\n            else\n            {\n                if (_4133.on)\n                {\n                    FaLayers param_25 = _4133;\n                    float3 param_26 = _4110;\n                    float3 param_27 = f0;\n                    float3 param_28 = _4080;\n                    float3 param_29 = _4039;\n                    float3 param_30 = _4177.direction;\n                    float3 param_31 = _4196;\n                    float param_32 = _4185;\n                    float param_33 = _4104;\n                    float param_34 = _4201;\n                    float param_35 = _4206;\n                    float param_36 = _4095;\n                    float param_37 = _4099;\n                    int param_38 = _4168;\n                    lit += (fa_layers_light(param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33, param_34, param_35, param_36, param_37) * ((fa_light_rgb(param_38, _381, fa_light_tex, fa_shadow_smp) * fa_light_tint) * _4191));\n                }\n                else\n                {\n                    float _4288 = ((_4201 * _4201) * (_4099 - 1.0)) + 1.0;\n                    int param_39 = _4168;\n                    lit += (((_4110 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _4206, 5.0))) * (((_4099 / ((3.1415927410125732421875 * _4288) * _4288)) * (0.5 / fast::max(mix((2.0 * _4185) * _4104, _4185 + _4104, _4095), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4185))) * (fa_light_rgb(param_39, _381, fa_light_tex, fa_shadow_smp) * fa_light_tint)) * (_4185 * _4191));\n                }\n            }\n        }\n        if (_4133.on)\n        {\n            FaLayers param_40 = _4133;\n            float3 param_41 = _4080;\n            float3 param_42 = _4039;\n            float3 param_43 = f0;\n            float param_44 = _4091;\n            lit += (fa_layers_ibl(param_40, param_41, param_42, param_43, param_44, _381, fa_env_smp, fa_env_tex) * _4668);\n        }\n        else\n        {\n            float3 param_45 = _4080;\n            float3 param_46 = _4039;\n            float3 param_47 = f0;\n            float param_48 = _4091;\n            lit += (fa_sky_reflection(param_45, param_46, param_47, param_48, _381, fa_env_smp, fa_env_tex) * _4668);\n        }\n        result = lit;\n    }\n    float3 _4383 = result;\n    float3 _4384 = _4383 + _4669;\n    result = _4384;\n    float3 param_49 = _4384;\n    float3 param_50 = in.fa_world_pos;\n    result = fa_shadow_debug(param_49, param_50, _1094);\n    bool _4393 = _381.fa_fog.w > 0.0;\n    bool _4400;\n    if (!_4393)\n    {\n        _4400 = _381.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4400 = _4393;\n    }\n    if (_4400)\n    {\n        float3 _4409 = in.fa_world_pos - _381.fa_camera_pos.xyz;\n        float _4415 = dot(_4409, _381.fa_fog_c.xyz);\n        bool _4419 = _381.fa_fog_c.w > 0.5;\n        float _4420;\n        if (_4419)\n        {\n            _4420 = _4415;\n        }\n        else\n        {\n            _4420 = length(_4409);\n        }\n        float _4432 = _4420 - _381.fa_fog_b.x;\n        if (_4432 > 0.0)\n        {\n            float _4441 = _381.fa_fog.w * _4432;\n            float tau = _4441 * _4441;\n            if (_381.fa_fog_b.y > 0.0)\n            {\n                float _4457;\n                if (_4419)\n                {\n                    _4457 = in.fa_world_pos.y - (_381.fa_fog_c.y * _4415);\n                }\n                else\n                {\n                    _4457 = _381.fa_camera_pos.y;\n                }\n                float _4478 = mix(_4457, in.fa_world_pos.y, fast::clamp(_381.fa_fog_b.x / _4420, 0.0, 1.0));\n                float _4482 = in.fa_world_pos.y - _4478;\n                float _4487 = _4478 - _381.fa_fog_b.z;\n                float _4492 = in.fa_world_pos.y - _381.fa_fog_b.z;\n                bool _4495 = _4487 <= 0.0;\n                bool _4496 = !_4495;\n                bool _4502;\n                if (_4496)\n                {\n                    _4502 = _381.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4502 = _4495;\n                }\n                float _4503;\n                if (_4502)\n                {\n                    _4503 = _381.fa_fog_b.y;\n                }\n                else\n                {\n                    _4503 = _381.fa_fog_b.y * exp(-fast::min(_381.fa_fog_b.w * _4487, 80.0));\n                }\n                bool _4530;\n                if (_4496)\n                {\n                    _4530 = _381.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4530 = _4495;\n                }\n                float _4531;\n                if (_4530)\n                {\n                    _4531 = _381.fa_fog_b.y * _4487;\n                }\n                else\n                {\n                    _4531 = (_381.fa_fog_b.y * (1.0 - exp(-fast::min(_381.fa_fog_b.w * _4487, 80.0)))) / _381.fa_fog_b.w;\n                }\n                bool _4556 = _4492 <= 0.0;\n                bool _4563;\n                if (!_4556)\n                {\n                    _4563 = _381.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4563 = _4556;\n                }\n                float _4564;\n                if (_4563)\n                {\n                    _4564 = _381.fa_fog_b.y * _4492;\n                }\n                else\n                {\n                    _4564 = (_381.fa_fog_b.y * (1.0 - exp(-fast::min(_381.fa_fog_b.w * _4492, 80.0)))) / _381.fa_fog_b.w;\n                }\n                float _4591;\n                if (abs(_4482) < 0.001000000047497451305389404296875)\n                {\n                    _4591 = _4503;\n                }\n                else\n                {\n                    _4591 = (_4564 - _4531) / _4482;\n                }\n                tau += (_4432 * fast::max(_4591, 0.0));\n            }\n            result = mix(result, _381.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4664);\n    return out;\n}\n\n",
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
            "inst_name": "_381",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1094",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_4058",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 6
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
              "msl_texture_n": 7
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
              "msl_texture_n": 8
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
              "msl_texture_n": 9
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
              "msl_texture_n": 10
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
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
          },
          {
            "slot": 10,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _308 = _160.world_pos;\n    float4 _171 = float4(_308, 1.0);\n    fa_world_pos = _308;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _225, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _225.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _756 = base_t;\n    _756.x = _237.x;\n    _756.y = _237.y;\n    _756.z = _237.z;\n    base_t = _756;\n    float4 _253 = (_756 * _225.fa_base_color) * i.vertex_color;\n    float3 _719 = i.world_normal;\n    if (_225.fa_maps.z > 0.5)\n    {\n        float param_4 = _225.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0) - float3(1.0);\n        float2 _295 = _290.xy * _225.fa_maps.x;\n        float3 _764 = _290;\n        _764.x = _295.x;\n        _764.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _764;\n        _719 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _225.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _767 = mrt;\n    _767.x = _324.x;\n    _767.y = _324.y;\n    _767.z = _324.z;\n    mrt = _767;\n    float4 _354 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _225.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _724 = _225.fa_layers_a.x;\n    float _725 = _225.fa_layers_a.y;\n    float _728 = _225.fa_layers_a.z;\n    float _727 = _225.fa_layers_b.w;\n    float _730 = _225.fa_layers_c.x;\n    if (_225.fa_layers_c.z > 0.5)\n    {\n        if (mod(_225.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _724 *= _366.y;\n            _725 *= _366.z;\n            _727 *= _354.w;\n        }\n        if (_225.fa_layers_c.z > 1.5)\n        {\n            _728 *= mrt.x;\n            _730 *= mrt.w;\n        }\n    }\n    return Surface{ _253.xyz, _253.w, _719, fast::clamp(_225.fa_pbr.x * _324.z, 0.0, 1.0), fast::clamp(_225.fa_pbr.y * _324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_225.fa_maps.y * (_366.x - 1.0)), _225.fa_emissive.xyz + (_225.fa_model_emissive.xyz * _396), _724, _725, _225.fa_layers_b.xyz, _727, _728, _225.fa_layers_a.w, _730, _225.fa_layers_c.y, _225.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _225 [[buffer(1)]], constant fa_material& _546 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> mask [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _630 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _630 = -_630;\n    }\n    float3 _530 = fast::normalize(_225.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _630, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    Surface _535 = fa_standard_surface(param, fa_tex, fa_smp, _225, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _654 = _535.normal;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _630, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    Surface param_2 = _535;\n    surface(param_1, param_2, mask, mask_smp);\n    _654 = param_2.normal;\n    if (param_2.alpha < _546.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    float3 _556 = fast::normalize(_654);\n    float3 _571 = fast::normalize(float3(dot(in.fa_pre_r0, _556), dot(in.fa_pre_r1, _556), dot(in.fa_pre_r2, _556)));\n    float _583 = _571.z;\n    float2 e = _571.xy / float2((abs(_571.x) + abs(_571.y)) + abs(_583));\n    if (_583 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_225",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_546",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _429 = _273.world_pos;\n    float4 _284 = float4(_429, 1.0);\n    fa_world_pos = _429;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _225, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _225.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _756 = base_t;\n    _756.x = _237.x;\n    _756.y = _237.y;\n    _756.z = _237.z;\n    base_t = _756;\n    float4 _253 = (_756 * _225.fa_base_color) * i.vertex_color;\n    float3 _719 = i.world_normal;\n    if (_225.fa_maps.z > 0.5)\n    {\n        float param_4 = _225.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0) - float3(1.0);\n        float2 _295 = _290.xy * _225.fa_maps.x;\n        float3 _764 = _290;\n        _764.x = _295.x;\n        _764.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _764;\n        _719 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _225.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _767 = mrt;\n    _767.x = _324.x;\n    _767.y = _324.y;\n    _767.z = _324.z;\n    mrt = _767;\n    float4 _354 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _225.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _724 = _225.fa_layers_a.x;\n    float _725 = _225.fa_layers_a.y;\n    float _728 = _225.fa_layers_a.z;\n    float _727 = _225.fa_layers_b.w;\n    float _730 = _225.fa_layers_c.x;\n    if (_225.fa_layers_c.z > 0.5)\n    {\n        if (mod(_225.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _724 *= _366.y;\n            _725 *= _366.z;\n            _727 *= _354.w;\n        }\n        if (_225.fa_layers_c.z > 1.5)\n        {\n            _728 *= mrt.x;\n            _730 *= mrt.w;\n        }\n    }\n    return Surface{ _253.xyz, _253.w, _719, fast::clamp(_225.fa_pbr.x * _324.z, 0.0, 1.0), fast::clamp(_225.fa_pbr.y * _324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_225.fa_maps.y * (_366.x - 1.0)), _225.fa_emissive.xyz + (_225.fa_model_emissive.xyz * _396), _724, _725, _225.fa_layers_b.xyz, _727, _728, _225.fa_layers_a.w, _730, _225.fa_layers_c.y, _225.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _225 [[buffer(1)]], constant fa_material& _546 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> mask [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _630 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _630 = -_630;\n    }\n    float3 _530 = fast::normalize(_225.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _630, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    Surface _535 = fa_standard_surface(param, fa_tex, fa_smp, _225, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _654 = _535.normal;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _630, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    Surface param_2 = _535;\n    surface(param_1, param_2, mask, mask_smp);\n    _654 = param_2.normal;\n    if (param_2.alpha < _546.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    float3 _556 = fast::normalize(_654);\n    float3 _571 = fast::normalize(float3(dot(in.fa_pre_r0, _556), dot(in.fa_pre_r1, _556), dot(in.fa_pre_r2, _556)));\n    float _583 = _571.z;\n    float2 e = _571.xy / float2((abs(_571.x) + abs(_571.y)) + abs(_583));\n    if (_583 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_225",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_546",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _122)\n{\n    float3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * _122.fa_uv_scale.xy, color, position };\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _122 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _122);\n    float3 _239 = _190.world_pos;\n    out.fa_world_pos = _239;\n    out.fa_world_normal = _190.world_normal;\n    out.fa_world_tangent = _190.world_tangent;\n    out.fa_uv = _190.uv;\n    out.fa_vertex_color = _190.color;\n    out.gl_Position = _122.fa_light_vp * float4(_239, 1.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _225, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _225.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _690 = base_t;\n    _690.x = _237.x;\n    _690.y = _237.y;\n    _690.z = _237.z;\n    base_t = _690;\n    float4 _253 = (_690 * _225.fa_base_color) * i.vertex_color;\n    float3 _659 = i.world_normal;\n    if (_225.fa_maps.z > 0.5)\n    {\n        float param_4 = _225.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0) - float3(1.0);\n        float2 _295 = _290.xy * _225.fa_maps.x;\n        float3 _698 = _290;\n        _698.x = _295.x;\n        _698.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _698;\n        _659 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _225.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _701 = mrt;\n    _701.x = _324.x;\n    _701.y = _324.y;\n    _701.z = _324.z;\n    mrt = _701;\n    float4 _354 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _225.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _664 = _225.fa_layers_a.x;\n    float _665 = _225.fa_layers_a.y;\n    float _668 = _225.fa_layers_a.z;\n    float _667 = _225.fa_layers_b.w;\n    float _670 = _225.fa_layers_c.x;\n    if (_225.fa_layers_c.z > 0.5)\n    {\n        if (mod(_225.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _664 *= _366.y;\n            _665 *= _366.z;\n            _667 *= _354.w;\n        }\n        if (_225.fa_layers_c.z > 1.5)\n        {\n            _668 *= mrt.x;\n            _670 *= mrt.w;\n        }\n    }\n    return Surface{ _253.xyz, _253.w, _659, fast::clamp(_225.fa_pbr.x * _324.z, 0.0, 1.0), fast::clamp(_225.fa_pbr.y * _324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_225.fa_maps.y * (_366.x - 1.0)), _225.fa_emissive.xyz + (_225.fa_model_emissive.xyz * _396), _664, _665, _225.fa_layers_b.xyz, _667, _668, _225.fa_layers_a.w, _670, _225.fa_layers_c.y, _225.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _225 [[buffer(1)]], constant fa_material& _546 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> mask [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _570 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _570 = -_570;\n    }\n    float3 _530 = fast::normalize(_225.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _570, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _570, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _225, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, mask, mask_smp);\n    if (param_2.alpha < _546.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec2",
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
            "inst_name": "_122",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_546",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _174)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _165 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_174.fa_joint_rows[_165] * weights[i]);\n        r1 += (_174.fa_joint_rows[_165 + 1] * weights[i]);\n        r2 += (_174.fa_joint_rows[_165 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _127)\n{\n    float3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * _127.fa_uv_scale.xy, color, position };\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _127 [[buffer(0)]], constant fa_skin& _174 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _174);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData _311 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _127);\n    float3 _360 = _311.world_pos;\n    out.fa_world_pos = _360;\n    out.fa_world_normal = _311.world_normal;\n    out.fa_world_tangent = _311.world_tangent;\n    out.fa_uv = _311.uv;\n    out.fa_vertex_color = _311.color;\n    out.gl_Position = _127.fa_light_vp * float4(_360, 1.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _225, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _225.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _237 = fa_tex_fix(param_2, param_3);\n    float4 _690 = base_t;\n    _690.x = _237.x;\n    _690.y = _237.y;\n    _690.z = _237.z;\n    base_t = _690;\n    float4 _253 = (_690 * _225.fa_base_color) * i.vertex_color;\n    float3 _659 = i.world_normal;\n    if (_225.fa_maps.z > 0.5)\n    {\n        float param_4 = _225.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _290 = (_287 * 2.0) - float3(1.0);\n        float2 _295 = _290.xy * _225.fa_maps.x;\n        float3 _698 = _290;\n        _698.x = _295.x;\n        _698.y = _295.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _698;\n        _659 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _225.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _324 = fa_tex_fix(param_12, param_13);\n    float4 _701 = mrt;\n    _701.x = _324.x;\n    _701.y = _324.y;\n    _701.z = _324.z;\n    mrt = _701;\n    float4 _354 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _225.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _225.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _396 = fa_tex_fix(param_20, param_21);\n    float _664 = _225.fa_layers_a.x;\n    float _665 = _225.fa_layers_a.y;\n    float _668 = _225.fa_layers_a.z;\n    float _667 = _225.fa_layers_b.w;\n    float _670 = _225.fa_layers_c.x;\n    if (_225.fa_layers_c.z > 0.5)\n    {\n        if (mod(_225.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _664 *= _366.y;\n            _665 *= _366.z;\n            _667 *= _354.w;\n        }\n        if (_225.fa_layers_c.z > 1.5)\n        {\n            _668 *= mrt.x;\n            _670 *= mrt.w;\n        }\n    }\n    return Surface{ _253.xyz, _253.w, _659, fast::clamp(_225.fa_pbr.x * _324.z, 0.0, 1.0), fast::clamp(_225.fa_pbr.y * _324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_225.fa_maps.y * (_366.x - 1.0)), _225.fa_emissive.xyz + (_225.fa_model_emissive.xyz * _396), _664, _665, _225.fa_layers_b.xyz, _667, _668, _225.fa_layers_a.w, _670, _225.fa_layers_c.y, _225.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _225 [[buffer(1)]], constant fa_material& _546 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> mask [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _570 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _570 = -_570;\n    }\n    float3 _530 = fast::normalize(_225.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _570, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _570, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _530, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _225, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, mask, mask_smp);\n    if (param_2.alpha < _546.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec2",
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
            "inst_name": "_127",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_174",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_225",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_546",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    }
  }
}
