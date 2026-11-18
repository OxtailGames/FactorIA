{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "5dd0da916b10a9a6f999383491342fc1c21819329ed9afcc0f9d0e7d6522a261",
  "slang": "metal_macos",
  "params": [
    "lift"
  ],
  "textures": [
    "height"
  ],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    float lift;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _158)\n{\n    float3 _101 = cross(model[1].xyz, model[2].xyz);\n    float _106 = (dot(model[0].xyz, _101) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_101 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _106, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _106), texcoord0 * _158.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _61)\n{\n    v.world_pos.y += (fa_vs_height.sample(fa_vs_height_smp, v.uv, level(0.0)).x * _61.lift);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _61, constant fa_mesh_vs_params& _158, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _158);\n    vertex0(param_6, fa_vs_height, fa_vs_height_smp, _61);\n    float4 _198 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = _158.fa_light_vp * _198;\n    gl_Position = _158.fa_view_proj * _198;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _158 [[buffer(0)]], constant fa_material_vs& _61 [[buffer(4)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, fa_vs_height, fa_vs_height_smp, _61, _158, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _208 = fa_linear_to_srgb(param);\n        c = _208;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _216 = fa_srgb_to_linear(param_1);\n            c = _216;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _68;\n    if (bool(i.front_facing))\n    {\n        _68 = i.world_normal;\n    }\n    else\n    {\n        _68 = -i.world_normal;\n    }\n    float3 _93 = fast::normalize(i.world_tangent.xyz - (_68 * dot(_68, i.world_tangent.xyz)));\n    float3 _121 = fast::normalize(((_93 * m.x) + ((cross(_68, _93) * i.world_tangent.w) * m.y)) + (_68 * m.z));\n    float3 _124;\n    if (bool(i.front_facing))\n    {\n        _124 = _121;\n    }\n    else\n    {\n        _124 = -_121;\n    }\n    return _124;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _241, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _241.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _252 = fa_tex_fix(param_2, param_3);\n    float4 _1334 = base_t;\n    _1334.x = _252.x;\n    _1334.y = _252.y;\n    _1334.z = _252.z;\n    base_t = _1334;\n    float4 _268 = (_1334 * _241.fa_base_color) * i.vertex_color;\n    float3 _1318 = i.world_normal;\n    if (_241.fa_maps.z > 0.5)\n    {\n        float param_4 = _241.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _301 = fa_tex_fix(param_6, param_7);\n        float3 _305 = (_301 * 2.0) - float3(1.0);\n        float2 _310 = _305.xy * _241.fa_maps.x;\n        float3 _1342 = _305;\n        _1342.x = _310.x;\n        _1342.y = _310.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1342;\n        _1318 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _241.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _339 = fa_tex_fix(param_12, param_13);\n    float4 _1345 = mrt;\n    _1345.x = _339.x;\n    _1345.y = _339.y;\n    _1345.z = _339.z;\n    mrt = _1345;\n    float param_14 = _241.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _380 = fa_tex_fix(param_16, param_17);\n    float param_18 = _241.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _407 = fa_tex_fix(param_20, param_21);\n    return Surface{ _268.xyz, _268.w, _1318, fast::clamp(_241.fa_pbr.x * _339.z, 0.0, 1.0), fast::clamp(_241.fa_pbr.y * _339.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_241.fa_maps.y * (_380.x - 1.0)), _241.fa_emissive.xyz + (_241.fa_model_emissive.xyz * _407) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> height, sampler height_smp)\n{\n    s.albedo *= mix(0.5, 1.0, height.sample(height_smp, i.uv).x);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _241, thread float4& fa_shadow_pos, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_241.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _429 = fa_shadow_pos.xyz / float3(fa_shadow_pos.w);\n    float3 p = _429;\n    float2 suv = (_429.xy * 0.5) + float2(0.5);\n    if (_241.fa_counts.z > 0.5)\n    {\n        float3 _1353 = p;\n        _1353.z = (_1353.z * 0.5) + 0.5;\n        p = _1353;\n    }\n    else\n    {\n        float2 _1356 = suv;\n        _1356.y = 1.0 - _1356.y;\n        suv = _1356;\n    }\n    bool _456 = suv.x < 0.0;\n    bool _463;\n    if (!_456)\n    {\n        _463 = suv.x > 1.0;\n    }\n    else\n    {\n        _463 = _456;\n    }\n    bool _470;\n    if (!_463)\n    {\n        _470 = suv.y < 0.0;\n    }\n    else\n    {\n        _470 = _463;\n    }\n    bool _477;\n    if (!_470)\n    {\n        _477 = suv.y > 1.0;\n    }\n    else\n    {\n        _477 = _470;\n    }\n    bool _484;\n    if (!_477)\n    {\n        _484 = p.z > 1.0;\n    }\n    else\n    {\n        _484 = _477;\n    }\n    if (_484)\n    {\n        return 1.0;\n    }\n    float _498 = _241.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _498) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _241.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _639 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _642 = _639.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_642 * _642, exp2((-9.27999973297119140625) * ndv)) * _642) + _639.y)) + _639.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _241)\n{\n    float _559 = rough * rough;\n    float _592 = 0.60000002384185791015625 * _559;\n    return mix(mix(_241.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_241.fa_env_horizon.xyz, _241.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _559)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _592, 0.0500000007450580596923828125 + _592, d.y))), ((_241.fa_env_sky.xyz + _241.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_559 * 0.60000002384185791015625));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _241 [[buffer(1)]], constant fa_lights& _805 [[buffer(2)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> height [[texture(6)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler height_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _1264 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1264 = -_1264;\n    }\n    float3 _703 = fast::normalize(_241.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1264, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _703, short(gl_FrontFacing) };\n    Surface _708 = fa_standard_surface(param, fa_tex, fa_smp, _241, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _1287 = _708.albedo;\n    float _1288 = _708.alpha;\n    float3 _1289 = _708.normal;\n    float _1290 = _708.metallic;\n    float _1291 = _708.roughness;\n    float _1292 = _708.occlusion;\n    float3 _1293 = _708.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1264, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _703, short(gl_FrontFacing) };\n    Surface param_2 = _708;\n    surface(param_1, param_2, height, height_smp);\n    _1287 = param_2.albedo;\n    _1288 = param_2.alpha;\n    _1289 = param_2.normal;\n    _1290 = param_2.metallic;\n    _1291 = param_2.roughness;\n    _1292 = param_2.occlusion;\n    _1293 = param_2.emission;\n    float3 result;\n    if (_241.fa_emissive.w > 0.5)\n    {\n        result = _1287;\n    }\n    else\n    {\n        float3 _730 = fast::normalize(_1289);\n        float _737 = fast::clamp(_1290, 0.0, 1.0);\n        float _741 = fast::clamp(_1291, 0.0500000007450580596923828125, 1.0);\n        float _745 = _741 * _741;\n        float _749 = _745 * _745;\n        float _755 = fast::max(dot(_730, _703), 9.9999997473787516355514526367188e-05);\n        float3 _761 = _1287 * (1.0 - _737);\n        float3 _769 = mix(float3(0.039999999105930328369140625), _1287, float3(_737));\n        float3 lit = (_241.fa_ambient.xyz * _761) * _1292;\n        int _782 = int(_241.fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _782)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _812 = _805.fa_light_color[li].w < 0.5;\n            if (_812)\n            {\n                l = fast::normalize(_805.fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _829 = _805.fa_light_pos[li].xyz - in.fa_world_pos;\n                float _831 = length(_829);\n                l = _829 / float3(fast::max(_831, 9.9999997473787516355514526367188e-05));\n                float _846 = _831 / fast::max(_805.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n                float _852 = fast::clamp(1.0 - (_846 * _846), 0.0, 1.0);\n                atten = _852 * _852;\n                if (_805.fa_light_color[li].w > 1.5)\n                {\n                    atten *= smoothstep(_805.fa_light_dir[li].w, mix(_805.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_805.fa_light_dir[li].xyz)));\n                }\n            }\n            float shadow = 1.0;\n            if (_812 && (li == 0))\n            {\n                float3 param_3 = _1264;\n                float3 param_4 = l;\n                shadow = fa_shadow_factor(param_3, param_4, _241, in.fa_shadow_pos, fa_shadow_tex, fa_shadow_smp);\n            }\n            float _898 = fast::max(dot(_730, l), 0.0);\n            float _900 = atten;\n            float _901 = _900 * shadow;\n            atten = _901;\n            float3 _906 = fast::normalize(l + _703);\n            float _911 = fast::max(dot(_730, _906), 0.0);\n            float _924 = ((_911 * _911) * (_749 - 1.0)) + 1.0;\n            lit += (((_761 + (((_769 + ((float3(1.0) - _769) * powr(1.0 - fast::max(dot(_703, _906), 0.0), 5.0))) * (((_749 / ((3.1415927410125732421875 * _924) * _924)) * (0.5 / fast::max(mix((2.0 * _898) * _755, _898 + _755, _745), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _898))) * _805.fa_light_color[li].xyz) * (_898 * _901));\n        }\n        float param_5 = _741;\n        float param_6 = _755;\n        float2 _992 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_703, _730);\n        float param_8 = _741;\n        float3 _1010 = lit;\n        float3 _1011 = _1010 + ((fa_environment(param_7, param_8, _241) * ((_769 * _992.x) + float3(_992.y))) * _1292);\n        lit = _1011;\n        result = _1011;\n    }\n    result += _1293;\n    bool _1020 = _241.fa_fog.w > 0.0;\n    bool _1028;\n    if (!_1020)\n    {\n        _1028 = _241.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1028 = _1020;\n    }\n    if (_1028)\n    {\n        float3 _1037 = in.fa_world_pos - _241.fa_camera_pos.xyz;\n        float _1044 = dot(_1037, _241.fa_fog_c.xyz);\n        bool _1048 = _241.fa_fog_c.w > 0.5;\n        float _1049;\n        if (_1048)\n        {\n            _1049 = _1044;\n        }\n        else\n        {\n            _1049 = length(_1037);\n        }\n        float _1061 = _1049 - _241.fa_fog_b.x;\n        if (_1061 > 0.0)\n        {\n            float _1070 = _241.fa_fog.w * _1061;\n            float tau = _1070 * _1070;\n            if (_241.fa_fog_b.y > 0.0)\n            {\n                float _1086;\n                if (_1048)\n                {\n                    _1086 = in.fa_world_pos.y - (_241.fa_fog_c.y * _1044);\n                }\n                else\n                {\n                    _1086 = _241.fa_camera_pos.y;\n                }\n                float _1107 = mix(_1086, in.fa_world_pos.y, fast::clamp(_241.fa_fog_b.x / _1049, 0.0, 1.0));\n                float _1111 = in.fa_world_pos.y - _1107;\n                float _1116 = _1107 - _241.fa_fog_b.z;\n                float _1121 = in.fa_world_pos.y - _241.fa_fog_b.z;\n                bool _1124 = _1116 <= 0.0;\n                bool _1125 = !_1124;\n                bool _1131;\n                if (_1125)\n                {\n                    _1131 = _241.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1131 = _1124;\n                }\n                float _1132;\n                if (_1131)\n                {\n                    _1132 = _241.fa_fog_b.y;\n                }\n                else\n                {\n                    _1132 = _241.fa_fog_b.y * exp(-fast::min(_241.fa_fog_b.w * _1116, 80.0));\n                }\n                bool _1159;\n                if (_1125)\n                {\n                    _1159 = _241.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1159 = _1124;\n                }\n                float _1160;\n                if (_1159)\n                {\n                    _1160 = _241.fa_fog_b.y * _1116;\n                }\n                else\n                {\n                    _1160 = (_241.fa_fog_b.y * (1.0 - exp(-fast::min(_241.fa_fog_b.w * _1116, 80.0)))) / _241.fa_fog_b.w;\n                }\n                bool _1185 = _1121 <= 0.0;\n                bool _1192;\n                if (!_1185)\n                {\n                    _1192 = _241.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1192 = _1185;\n                }\n                float _1193;\n                if (_1192)\n                {\n                    _1193 = _241.fa_fog_b.y * _1121;\n                }\n                else\n                {\n                    _1193 = (_241.fa_fog_b.y * (1.0 - exp(-fast::min(_241.fa_fog_b.w * _1121, 80.0)))) / _241.fa_fog_b.w;\n                }\n                float _1220;\n                if (abs(_1111) < 0.001000000047497451305389404296875)\n                {\n                    _1220 = _1132;\n                }\n                else\n                {\n                    _1220 = (_1193 - _1160) / _1111;\n                }\n                tau += (_1061 * fast::max(_1220, 0.0));\n            }\n            result = mix(result, _241.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _1288);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_61",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_158",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_241",
            "msl_buffer_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_805",
            "msl_buffer_n": 2
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
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 6
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    float lift;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _210)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _201 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_210.fa_joint_rows[_201] * weights[i]);\n        r1 += (_210.fa_joint_rows[_201 + 1] * weights[i]);\n        r2 += (_210.fa_joint_rows[_201 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _163)\n{\n    float3 _106 = cross(model[1].xyz, model[2].xyz);\n    float _111 = (dot(model[0].xyz, _106) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_106 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _111, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _111), texcoord0 * _163.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _66)\n{\n    v.world_pos.y += (fa_vs_height.sample(fa_vs_height_smp, v.uv, level(0.0)).x * _66.lift);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _66, constant fa_mesh_vs_params& _163, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _163);\n    vertex0(param_6, fa_vs_height, fa_vs_height_smp, _66);\n    float4 _311 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = _163.fa_light_vp * _311;\n    gl_Position = _163.fa_view_proj * _311;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _163 [[buffer(0)]], constant fa_skin& _210 [[buffer(3)]], constant fa_material_vs& _66 [[buffer(4)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _210);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, fa_vs_height, fa_vs_height_smp, _66, _163, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _208 = fa_linear_to_srgb(param);\n        c = _208;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _216 = fa_srgb_to_linear(param_1);\n            c = _216;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _68;\n    if (bool(i.front_facing))\n    {\n        _68 = i.world_normal;\n    }\n    else\n    {\n        _68 = -i.world_normal;\n    }\n    float3 _93 = fast::normalize(i.world_tangent.xyz - (_68 * dot(_68, i.world_tangent.xyz)));\n    float3 _121 = fast::normalize(((_93 * m.x) + ((cross(_68, _93) * i.world_tangent.w) * m.y)) + (_68 * m.z));\n    float3 _124;\n    if (bool(i.front_facing))\n    {\n        _124 = _121;\n    }\n    else\n    {\n        _124 = -_121;\n    }\n    return _124;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _241, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _241.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _252 = fa_tex_fix(param_2, param_3);\n    float4 _1334 = base_t;\n    _1334.x = _252.x;\n    _1334.y = _252.y;\n    _1334.z = _252.z;\n    base_t = _1334;\n    float4 _268 = (_1334 * _241.fa_base_color) * i.vertex_color;\n    float3 _1318 = i.world_normal;\n    if (_241.fa_maps.z > 0.5)\n    {\n        float param_4 = _241.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _301 = fa_tex_fix(param_6, param_7);\n        float3 _305 = (_301 * 2.0) - float3(1.0);\n        float2 _310 = _305.xy * _241.fa_maps.x;\n        float3 _1342 = _305;\n        _1342.x = _310.x;\n        _1342.y = _310.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1342;\n        _1318 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _241.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _339 = fa_tex_fix(param_12, param_13);\n    float4 _1345 = mrt;\n    _1345.x = _339.x;\n    _1345.y = _339.y;\n    _1345.z = _339.z;\n    mrt = _1345;\n    float param_14 = _241.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _380 = fa_tex_fix(param_16, param_17);\n    float param_18 = _241.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _407 = fa_tex_fix(param_20, param_21);\n    return Surface{ _268.xyz, _268.w, _1318, fast::clamp(_241.fa_pbr.x * _339.z, 0.0, 1.0), fast::clamp(_241.fa_pbr.y * _339.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_241.fa_maps.y * (_380.x - 1.0)), _241.fa_emissive.xyz + (_241.fa_model_emissive.xyz * _407) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> height, sampler height_smp)\n{\n    s.albedo *= mix(0.5, 1.0, height.sample(height_smp, i.uv).x);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _241, thread float4& fa_shadow_pos, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_241.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _429 = fa_shadow_pos.xyz / float3(fa_shadow_pos.w);\n    float3 p = _429;\n    float2 suv = (_429.xy * 0.5) + float2(0.5);\n    if (_241.fa_counts.z > 0.5)\n    {\n        float3 _1353 = p;\n        _1353.z = (_1353.z * 0.5) + 0.5;\n        p = _1353;\n    }\n    else\n    {\n        float2 _1356 = suv;\n        _1356.y = 1.0 - _1356.y;\n        suv = _1356;\n    }\n    bool _456 = suv.x < 0.0;\n    bool _463;\n    if (!_456)\n    {\n        _463 = suv.x > 1.0;\n    }\n    else\n    {\n        _463 = _456;\n    }\n    bool _470;\n    if (!_463)\n    {\n        _470 = suv.y < 0.0;\n    }\n    else\n    {\n        _470 = _463;\n    }\n    bool _477;\n    if (!_470)\n    {\n        _477 = suv.y > 1.0;\n    }\n    else\n    {\n        _477 = _470;\n    }\n    bool _484;\n    if (!_477)\n    {\n        _484 = p.z > 1.0;\n    }\n    else\n    {\n        _484 = _477;\n    }\n    if (_484)\n    {\n        return 1.0;\n    }\n    float _498 = _241.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _498) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _241.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _639 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _642 = _639.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_642 * _642, exp2((-9.27999973297119140625) * ndv)) * _642) + _639.y)) + _639.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _241)\n{\n    float _559 = rough * rough;\n    float _592 = 0.60000002384185791015625 * _559;\n    return mix(mix(_241.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_241.fa_env_horizon.xyz, _241.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _559)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _592, 0.0500000007450580596923828125 + _592, d.y))), ((_241.fa_env_sky.xyz + _241.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_559 * 0.60000002384185791015625));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _241 [[buffer(1)]], constant fa_lights& _805 [[buffer(2)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> height [[texture(6)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler height_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _1264 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1264 = -_1264;\n    }\n    float3 _703 = fast::normalize(_241.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1264, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _703, short(gl_FrontFacing) };\n    Surface _708 = fa_standard_surface(param, fa_tex, fa_smp, _241, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _1287 = _708.albedo;\n    float _1288 = _708.alpha;\n    float3 _1289 = _708.normal;\n    float _1290 = _708.metallic;\n    float _1291 = _708.roughness;\n    float _1292 = _708.occlusion;\n    float3 _1293 = _708.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1264, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _703, short(gl_FrontFacing) };\n    Surface param_2 = _708;\n    surface(param_1, param_2, height, height_smp);\n    _1287 = param_2.albedo;\n    _1288 = param_2.alpha;\n    _1289 = param_2.normal;\n    _1290 = param_2.metallic;\n    _1291 = param_2.roughness;\n    _1292 = param_2.occlusion;\n    _1293 = param_2.emission;\n    float3 result;\n    if (_241.fa_emissive.w > 0.5)\n    {\n        result = _1287;\n    }\n    else\n    {\n        float3 _730 = fast::normalize(_1289);\n        float _737 = fast::clamp(_1290, 0.0, 1.0);\n        float _741 = fast::clamp(_1291, 0.0500000007450580596923828125, 1.0);\n        float _745 = _741 * _741;\n        float _749 = _745 * _745;\n        float _755 = fast::max(dot(_730, _703), 9.9999997473787516355514526367188e-05);\n        float3 _761 = _1287 * (1.0 - _737);\n        float3 _769 = mix(float3(0.039999999105930328369140625), _1287, float3(_737));\n        float3 lit = (_241.fa_ambient.xyz * _761) * _1292;\n        int _782 = int(_241.fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _782)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _812 = _805.fa_light_color[li].w < 0.5;\n            if (_812)\n            {\n                l = fast::normalize(_805.fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _829 = _805.fa_light_pos[li].xyz - in.fa_world_pos;\n                float _831 = length(_829);\n                l = _829 / float3(fast::max(_831, 9.9999997473787516355514526367188e-05));\n                float _846 = _831 / fast::max(_805.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n                float _852 = fast::clamp(1.0 - (_846 * _846), 0.0, 1.0);\n                atten = _852 * _852;\n                if (_805.fa_light_color[li].w > 1.5)\n                {\n                    atten *= smoothstep(_805.fa_light_dir[li].w, mix(_805.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_805.fa_light_dir[li].xyz)));\n                }\n            }\n            float shadow = 1.0;\n            if (_812 && (li == 0))\n            {\n                float3 param_3 = _1264;\n                float3 param_4 = l;\n                shadow = fa_shadow_factor(param_3, param_4, _241, in.fa_shadow_pos, fa_shadow_tex, fa_shadow_smp);\n            }\n            float _898 = fast::max(dot(_730, l), 0.0);\n            float _900 = atten;\n            float _901 = _900 * shadow;\n            atten = _901;\n            float3 _906 = fast::normalize(l + _703);\n            float _911 = fast::max(dot(_730, _906), 0.0);\n            float _924 = ((_911 * _911) * (_749 - 1.0)) + 1.0;\n            lit += (((_761 + (((_769 + ((float3(1.0) - _769) * powr(1.0 - fast::max(dot(_703, _906), 0.0), 5.0))) * (((_749 / ((3.1415927410125732421875 * _924) * _924)) * (0.5 / fast::max(mix((2.0 * _898) * _755, _898 + _755, _745), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _898))) * _805.fa_light_color[li].xyz) * (_898 * _901));\n        }\n        float param_5 = _741;\n        float param_6 = _755;\n        float2 _992 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_703, _730);\n        float param_8 = _741;\n        float3 _1010 = lit;\n        float3 _1011 = _1010 + ((fa_environment(param_7, param_8, _241) * ((_769 * _992.x) + float3(_992.y))) * _1292);\n        lit = _1011;\n        result = _1011;\n    }\n    result += _1293;\n    bool _1020 = _241.fa_fog.w > 0.0;\n    bool _1028;\n    if (!_1020)\n    {\n        _1028 = _241.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1028 = _1020;\n    }\n    if (_1028)\n    {\n        float3 _1037 = in.fa_world_pos - _241.fa_camera_pos.xyz;\n        float _1044 = dot(_1037, _241.fa_fog_c.xyz);\n        bool _1048 = _241.fa_fog_c.w > 0.5;\n        float _1049;\n        if (_1048)\n        {\n            _1049 = _1044;\n        }\n        else\n        {\n            _1049 = length(_1037);\n        }\n        float _1061 = _1049 - _241.fa_fog_b.x;\n        if (_1061 > 0.0)\n        {\n            float _1070 = _241.fa_fog.w * _1061;\n            float tau = _1070 * _1070;\n            if (_241.fa_fog_b.y > 0.0)\n            {\n                float _1086;\n                if (_1048)\n                {\n                    _1086 = in.fa_world_pos.y - (_241.fa_fog_c.y * _1044);\n                }\n                else\n                {\n                    _1086 = _241.fa_camera_pos.y;\n                }\n                float _1107 = mix(_1086, in.fa_world_pos.y, fast::clamp(_241.fa_fog_b.x / _1049, 0.0, 1.0));\n                float _1111 = in.fa_world_pos.y - _1107;\n                float _1116 = _1107 - _241.fa_fog_b.z;\n                float _1121 = in.fa_world_pos.y - _241.fa_fog_b.z;\n                bool _1124 = _1116 <= 0.0;\n                bool _1125 = !_1124;\n                bool _1131;\n                if (_1125)\n                {\n                    _1131 = _241.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1131 = _1124;\n                }\n                float _1132;\n                if (_1131)\n                {\n                    _1132 = _241.fa_fog_b.y;\n                }\n                else\n                {\n                    _1132 = _241.fa_fog_b.y * exp(-fast::min(_241.fa_fog_b.w * _1116, 80.0));\n                }\n                bool _1159;\n                if (_1125)\n                {\n                    _1159 = _241.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1159 = _1124;\n                }\n                float _1160;\n                if (_1159)\n                {\n                    _1160 = _241.fa_fog_b.y * _1116;\n                }\n                else\n                {\n                    _1160 = (_241.fa_fog_b.y * (1.0 - exp(-fast::min(_241.fa_fog_b.w * _1116, 80.0)))) / _241.fa_fog_b.w;\n                }\n                bool _1185 = _1121 <= 0.0;\n                bool _1192;\n                if (!_1185)\n                {\n                    _1192 = _241.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1192 = _1185;\n                }\n                float _1193;\n                if (_1192)\n                {\n                    _1193 = _241.fa_fog_b.y * _1121;\n                }\n                else\n                {\n                    _1193 = (_241.fa_fog_b.y * (1.0 - exp(-fast::min(_241.fa_fog_b.w * _1121, 80.0)))) / _241.fa_fog_b.w;\n                }\n                float _1220;\n                if (abs(_1111) < 0.001000000047497451305389404296875)\n                {\n                    _1220 = _1132;\n                }\n                else\n                {\n                    _1220 = (_1193 - _1160) / _1111;\n                }\n                tau += (_1061 * fast::max(_1220, 0.0));\n            }\n            result = mix(result, _241.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _1288);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_66",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_163",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_210",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_241",
            "msl_buffer_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_805",
            "msl_buffer_n": 2
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
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 6
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    float lift;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _158)\n{\n    float3 _101 = cross(model[1].xyz, model[2].xyz);\n    float _106 = (dot(model[0].xyz, _101) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_101 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _106, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _106), texcoord0 * _158.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _61)\n{\n    v.world_pos.y += (fa_vs_height.sample(fa_vs_height_smp, v.uv, level(0.0)).x * _61.lift);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _61, constant fa_mesh_vs_params& _158, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _158);\n    vertex0(param_6, fa_vs_height, fa_vs_height_smp, _61);\n    float4 _202 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_158.fa_light_vp * _202).z;\n    fa_pre_r0 = float3(_158.fa_light_vp[0].x, _158.fa_light_vp[1].x, _158.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_158.fa_light_vp[0].y, _158.fa_light_vp[1].y, _158.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_158.fa_light_vp[0].z, _158.fa_light_vp[1].z, _158.fa_light_vp[2].z);\n    gl_Position = _158.fa_view_proj * _202;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _158 [[buffer(0)]], constant fa_material_vs& _61 [[buffer(4)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, fa_vs_height, fa_vs_height_smp, _61, _158, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _194 = fa_linear_to_srgb(param);\n        c = _194;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _202 = fa_srgb_to_linear(param_1);\n            c = _202;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _54;\n    if (bool(i.front_facing))\n    {\n        _54 = i.world_normal;\n    }\n    else\n    {\n        _54 = -i.world_normal;\n    }\n    float3 _79 = fast::normalize(i.world_tangent.xyz - (_54 * dot(_54, i.world_tangent.xyz)));\n    float3 _107 = fast::normalize(((_79 * m.x) + ((cross(_54, _79) * i.world_tangent.w) * m.y)) + (_54 * m.z));\n    float3 _110;\n    if (bool(i.front_facing))\n    {\n        _110 = _107;\n    }\n    else\n    {\n        _110 = -_107;\n    }\n    return _110;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _227, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _227.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _238 = fa_tex_fix(param_2, param_3);\n    float4 _595 = base_t;\n    _595.x = _238.x;\n    _595.y = _238.y;\n    _595.z = _238.z;\n    base_t = _595;\n    float4 _254 = (_595 * _227.fa_base_color) * i.vertex_color;\n    float3 _576 = i.world_normal;\n    if (_227.fa_maps.z > 0.5)\n    {\n        float param_4 = _227.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _291 = (_287 * 2.0) - float3(1.0);\n        float2 _296 = _291.xy * _227.fa_maps.x;\n        float3 _603 = _291;\n        _603.x = _296.x;\n        _603.y = _296.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _603;\n        _576 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _227.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _325 = fa_tex_fix(param_12, param_13);\n    float4 _606 = mrt;\n    _606.x = _325.x;\n    _606.y = _325.y;\n    _606.z = _325.z;\n    mrt = _606;\n    float param_14 = _227.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _227.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _393 = fa_tex_fix(param_20, param_21);\n    return Surface{ _254.xyz, _254.w, _576, fast::clamp(_227.fa_pbr.x * _325.z, 0.0, 1.0), fast::clamp(_227.fa_pbr.y * _325.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_227.fa_maps.y * (_366.x - 1.0)), _227.fa_emissive.xyz + (_227.fa_model_emissive.xyz * _393) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> height, sampler height_smp)\n{\n    s.albedo *= mix(0.5, 1.0, height.sample(height_smp, i.uv).x);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _227 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> height [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler height_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _523 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _523 = -_523;\n    }\n    float3 _438 = fast::normalize(_227.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _523, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _438, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _523, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _438, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _227, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, height, height_smp);\n    float3 _453 = fast::normalize(param_2.normal);\n    float3 _468 = fast::normalize(float3(dot(in.fa_pre_r0, _453), dot(in.fa_pre_r1, _453), dot(in.fa_pre_r2, _453)));\n    float _480 = _468.z;\n    float2 e = _468.xy / float2((abs(_468.x) + abs(_468.y)) + abs(_480));\n    if (_480 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_61",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_158",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_227",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
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
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    float lift;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _210)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _201 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_210.fa_joint_rows[_201] * weights[i]);\n        r1 += (_210.fa_joint_rows[_201 + 1] * weights[i]);\n        r2 += (_210.fa_joint_rows[_201 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _163)\n{\n    float3 _106 = cross(model[1].xyz, model[2].xyz);\n    float _111 = (dot(model[0].xyz, _106) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_106 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _111, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _111), texcoord0 * _163.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _66)\n{\n    v.world_pos.y += (fa_vs_height.sample(fa_vs_height_smp, v.uv, level(0.0)).x * _66.lift);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _66, constant fa_mesh_vs_params& _163, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _163);\n    vertex0(param_6, fa_vs_height, fa_vs_height_smp, _66);\n    float4 _315 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_163.fa_light_vp * _315).z;\n    fa_pre_r0 = float3(_163.fa_light_vp[0].x, _163.fa_light_vp[1].x, _163.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_163.fa_light_vp[0].y, _163.fa_light_vp[1].y, _163.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_163.fa_light_vp[0].z, _163.fa_light_vp[1].z, _163.fa_light_vp[2].z);\n    gl_Position = _163.fa_view_proj * _315;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _163 [[buffer(0)]], constant fa_skin& _210 [[buffer(3)]], constant fa_material_vs& _66 [[buffer(4)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _210);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, fa_vs_height, fa_vs_height_smp, _66, _163, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _194 = fa_linear_to_srgb(param);\n        c = _194;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _202 = fa_srgb_to_linear(param_1);\n            c = _202;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _54;\n    if (bool(i.front_facing))\n    {\n        _54 = i.world_normal;\n    }\n    else\n    {\n        _54 = -i.world_normal;\n    }\n    float3 _79 = fast::normalize(i.world_tangent.xyz - (_54 * dot(_54, i.world_tangent.xyz)));\n    float3 _107 = fast::normalize(((_79 * m.x) + ((cross(_54, _79) * i.world_tangent.w) * m.y)) + (_54 * m.z));\n    float3 _110;\n    if (bool(i.front_facing))\n    {\n        _110 = _107;\n    }\n    else\n    {\n        _110 = -_107;\n    }\n    return _110;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _227, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _227.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _238 = fa_tex_fix(param_2, param_3);\n    float4 _595 = base_t;\n    _595.x = _238.x;\n    _595.y = _238.y;\n    _595.z = _238.z;\n    base_t = _595;\n    float4 _254 = (_595 * _227.fa_base_color) * i.vertex_color;\n    float3 _576 = i.world_normal;\n    if (_227.fa_maps.z > 0.5)\n    {\n        float param_4 = _227.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _287 = fa_tex_fix(param_6, param_7);\n        float3 _291 = (_287 * 2.0) - float3(1.0);\n        float2 _296 = _291.xy * _227.fa_maps.x;\n        float3 _603 = _291;\n        _603.x = _296.x;\n        _603.y = _296.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _603;\n        _576 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _227.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _325 = fa_tex_fix(param_12, param_13);\n    float4 _606 = mrt;\n    _606.x = _325.x;\n    _606.y = _325.y;\n    _606.z = _325.z;\n    mrt = _606;\n    float param_14 = _227.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _227.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _393 = fa_tex_fix(param_20, param_21);\n    return Surface{ _254.xyz, _254.w, _576, fast::clamp(_227.fa_pbr.x * _325.z, 0.0, 1.0), fast::clamp(_227.fa_pbr.y * _325.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_227.fa_maps.y * (_366.x - 1.0)), _227.fa_emissive.xyz + (_227.fa_model_emissive.xyz * _393) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> height, sampler height_smp)\n{\n    s.albedo *= mix(0.5, 1.0, height.sample(height_smp, i.uv).x);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _227 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> height [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler height_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _523 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _523 = -_523;\n    }\n    float3 _438 = fast::normalize(_227.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _523, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _438, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _523, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _438, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _227, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, height, height_smp);\n    float3 _453 = fast::normalize(param_2.normal);\n    float3 _468 = fast::normalize(float3(dot(in.fa_pre_r0, _453), dot(in.fa_pre_r1, _453), dot(in.fa_pre_r2, _453)));\n    float _480 = _468.z;\n    float2 e = _468.xy / float2((abs(_468.x) + abs(_468.y)) + abs(_480));\n    if (_480 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_66",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_163",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_210",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_227",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
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
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    float lift;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _149)\n{\n    float3 _92 = cross(model[1].xyz, model[2].xyz);\n    float _97 = (dot(model[0].xyz, _92) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_92 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _97, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _97), texcoord0 * _149.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _52)\n{\n    v.world_pos.y += (fa_vs_height.sample(fa_vs_height_smp, v.uv, level(0.0)).x * _52.lift);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _149 [[buffer(0)]], constant fa_material_vs& _52 [[buffer(4)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _149);\n    vertex0(param_6, fa_vs_height, fa_vs_height_smp, _52);\n    out.gl_Position = _149.fa_light_vp * float4(param_6.world_pos, 1.0);\n    return out;\n}\n\n",
      "fs": "#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nfragment main0_out main0(float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_52",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_149",
            "msl_buffer_n": 0
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 6
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    float lift;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _201)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _192 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_201.fa_joint_rows[_192] * weights[i]);\n        r1 += (_201.fa_joint_rows[_192 + 1] * weights[i]);\n        r2 += (_201.fa_joint_rows[_192 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _154)\n{\n    float3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _102 = (dot(model[0].xyz, _97) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _102, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _102), texcoord0 * _154.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, texture2d<float> fa_vs_height, sampler fa_vs_height_smp, constant fa_material_vs& _57)\n{\n    v.world_pos.y += (fa_vs_height.sample(fa_vs_height_smp, v.uv, level(0.0)).x * _57.lift);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _154 [[buffer(0)]], constant fa_skin& _201 [[buffer(3)]], constant fa_material_vs& _57 [[buffer(4)]], texture2d<float> fa_vs_height [[texture(0)]], sampler fa_vs_height_smp [[sampler(6)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _201);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _154);\n    vertex0(param_8, fa_vs_height, fa_vs_height_smp, _57);\n    out.gl_Position = _154.fa_light_vp * float4(param_8.world_pos, 1.0);\n    return out;\n}\n\n",
      "fs": "#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nfragment main0_out main0(float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_57",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_154",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_201",
            "msl_buffer_n": 3
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 6
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          }
        ]
      }
    }
  }
}
