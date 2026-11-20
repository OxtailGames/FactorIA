{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "f33a36e751e8501a5c7167efe23b832a4315ec133394a3a234e9f06584552465",
  "slang": "metal_macos",
  "params": [
    "glow"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float3 fa_lm [[user(locn6)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _275 = _160.world_pos;\n    float4 _167 = float4(_275, 1.0);\n    fa_world_pos = _275;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_shadow_pos = _131.fa_light_vp * _167;\n    gl_Position = _131.fa_view_proj * _167;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float4 glow;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float3 fa_lm [[user(locn6)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _729 = fa_linear_to_srgb(param);\n        c = _729;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _737 = fa_srgb_to_linear(param_1);\n            c = _737;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _103;\n    if (bool(i.front_facing))\n    {\n        _103 = i.world_normal;\n    }\n    else\n    {\n        _103 = -i.world_normal;\n    }\n    float3 _127 = fast::normalize(i.world_tangent.xyz - (_103 * dot(_103, i.world_tangent.xyz)));\n    float3 _155 = fast::normalize(((_127 * m.x) + ((cross(_103, _127) * i.world_tangent.w) * m.y)) + (_103 * m.z));\n    float3 _158;\n    if (bool(i.front_facing))\n    {\n        _158 = _155;\n    }\n    else\n    {\n        _158 = -_155;\n    }\n    return _158;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _293, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _293.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _769 = fa_tex_fix(param_2, param_3);\n    float4 _1572 = base_t;\n    _1572.x = _769.x;\n    _1572.y = _769.y;\n    _1572.z = _769.z;\n    base_t = _1572;\n    float4 _783 = (_1572 * _293.fa_base_color) * i.vertex_color;\n    float3 _1540 = i.world_normal;\n    if (_293.fa_maps.z > 0.5)\n    {\n        float param_4 = _293.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _816 = fa_tex_fix(param_6, param_7);\n        float3 _819 = (_816 * 2.0) - float3(1.0);\n        float2 _824 = _819.xy * _293.fa_maps.x;\n        float3 _1580 = _819;\n        _1580.x = _824.x;\n        _1580.y = _824.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1580;\n        _1540 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _293.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _853 = fa_tex_fix(param_12, param_13);\n    float4 _1583 = mrt;\n    _1583.x = _853.x;\n    _1583.y = _853.y;\n    _1583.z = _853.z;\n    mrt = _1583;\n    float param_14 = _293.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _892 = fa_tex_fix(param_16, param_17);\n    float param_18 = _293.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _919 = fa_tex_fix(param_20, param_21);\n    return Surface{ _783.xyz, _783.w, _1540, fast::clamp(_293.fa_pbr.x * _853.z, 0.0, 1.0), fast::clamp(_293.fa_pbr.y * _853.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_293.fa_maps.y * (_892.x - 1.0)), _293.fa_emissive.xyz + (_293.fa_model_emissive.xyz * _919) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_material& _670)\n{\n    s.emission += (_670.glow.xyz * _670.glow.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _293, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_293.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _293.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _293, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _293, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _175)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _186 = _175.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_186)\n    {\n        l = fast::normalize(_175.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _204 = _175.fa_light_pos[li].xyz - world_pos;\n        float _206 = length(_204);\n        dist = _206;\n        l = _204 / float3(fast::max(_206, 9.9999997473787516355514526367188e-05));\n        float _222 = _206 / fast::max(_175.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _228 = fast::clamp(1.0 - (_222 * _222), 0.0, 1.0);\n        atten = _228 * _228;\n        if (_175.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_175.fa_light_dir[li].w, mix(_175.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_175.fa_light_dir[li].xyz)));\n        }\n    }\n    int _279;\n    if (_186)\n    {\n        _279 = 0;\n    }\n    else\n    {\n        _279 = (_175.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _175.fa_light_color[li].xyz * atten, atten, 1.0, dist, _279 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_pcf(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _293, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_293.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _306 = coord.xyz / float3(coord.w);\n    float3 p = _306;\n    float2 suv = (_306.xy * 0.5) + float2(0.5);\n    if (_293.fa_counts.z > 0.5)\n    {\n        float3 _1554 = p;\n        _1554.z = (_1554.z * 0.5) + 0.5;\n        p = _1554;\n    }\n    else\n    {\n        float2 _1557 = suv;\n        _1557.y = 1.0 - _1557.y;\n        suv = _1557;\n    }\n    bool _334 = suv.x < 0.0;\n    bool _341;\n    if (!_334)\n    {\n        _341 = suv.x > 1.0;\n    }\n    else\n    {\n        _341 = _334;\n    }\n    bool _348;\n    if (!_341)\n    {\n        _348 = suv.y < 0.0;\n    }\n    else\n    {\n        _348 = _341;\n    }\n    bool _355;\n    if (!_348)\n    {\n        _355 = suv.y > 1.0;\n    }\n    else\n    {\n        _355 = _348;\n    }\n    bool _362;\n    if (!_355)\n    {\n        _362 = p.z > 1.0;\n    }\n    else\n    {\n        _362 = _355;\n    }\n    if (_362)\n    {\n        return 1.0;\n    }\n    float _377 = _293.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _377) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _293.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _293, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2, _293, fa_shadow_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _175, constant fa_mesh_fs_params& _293, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _638 = fa_light_sample(param, param_1, _175);\n    float3 _1525 = _638.direction;\n    float3 _1520 = _638.color;\n    float _1527 = _638.attenuation;\n    float _1522 = _638.shadow;\n    int _1530 = _638.type;\n    if ((_1530 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1525;\n        float _652 = fa_shadow_factor(param_2, param_3, _293, fa_shadow_tex, fa_shadow_smp, fa_shadow_pos);\n        _1522 = _652;\n        _1520 = _175.fa_light_color[li].xyz * (_1527 * _652);\n    }\n    return LightSample{ _1525, _1520, _1527, _1522, _638._distance, _1530 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _574 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _577 = _574.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_577 * _577, exp2((-9.27999973297119140625) * ndv)) * _577) + _574.y)) + _574.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _293, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_293.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _293.fa_env_horizon.w)).xyz;\n    }\n    float _477 = rough * rough;\n    float _508 = 0.60000002384185791015625 * _477;\n    return mix(mix(_293.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_293.fa_env_horizon.xyz, _293.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _477)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _508, 0.0500000007450580596923828125 + _508, d.y))), ((_293.fa_env_sky.xyz + _293.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_477 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _293, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _616 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _293, fa_env_tex, fa_env_smp) * ((f0 * _616.x) + float3(_616.y));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _293 [[buffer(1)]], constant fa_lights& _175 [[buffer(2)]], constant fa_material& _670 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _1445 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1445 = -_1445;\n    }\n    float3 _985 = fast::normalize(_293.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1445, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _985, short(gl_FrontFacing) };\n    Surface _990 = fa_standard_surface(param, _293, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _1468 = _990.albedo;\n    float _1469 = _990.alpha;\n    float3 _1470 = _990.normal;\n    float _1471 = _990.metallic;\n    float _1472 = _990.roughness;\n    float _1473 = _990.occlusion;\n    float3 _1474 = _990.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1445, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _985, short(gl_FrontFacing) };\n    Surface param_2 = _990;\n    surface(param_1, param_2, _670);\n    _1468 = param_2.albedo;\n    _1469 = param_2.alpha;\n    _1470 = param_2.normal;\n    _1471 = param_2.metallic;\n    _1472 = param_2.roughness;\n    _1473 = param_2.occlusion;\n    _1474 = param_2.emission;\n    float3 result;\n    if (_293.fa_emissive.w > 0.5)\n    {\n        result = _1468;\n    }\n    else\n    {\n        float3 _1012 = fast::normalize(_1470);\n        float _1019 = fast::clamp(_1471, 0.0, 1.0);\n        float _1023 = fast::clamp(_1472, 0.0500000007450580596923828125, 1.0);\n        float _1027 = _1023 * _1023;\n        float _1031 = _1027 * _1027;\n        float _1036 = fast::max(dot(_1012, _985), 9.9999997473787516355514526367188e-05);\n        float3 _1042 = _1468 * (1.0 - _1019);\n        float3 _1050 = mix(float3(0.039999999105930328369140625), _1468, float3(_1019));\n        float3 param_3 = _1012;\n        float3 lit = (fa_indirect_diffuse(param_3, _293, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap) * _1042) * _1473;\n        int _1063 = int(_293.fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1063)\n            {\n                break;\n            }\n            int param_4 = li;\n            float3 param_5 = in.fa_world_pos;\n            float3 param_6 = _1445;\n            LightSample _1087 = fa_light_shadowed(param_4, param_5, param_6, _175, _293, fa_shadow_tex, fa_shadow_smp, in.fa_shadow_pos);\n            float3 _1503 = _1087.direction;\n            float _1095 = fast::max(dot(_1012, _1503), 0.0);\n            float3 _1106 = fast::normalize(_1503 + _985);\n            float _1111 = fast::max(dot(_1012, _1106), 0.0);\n            float _1124 = ((_1111 * _1111) * (_1031 - 1.0)) + 1.0;\n            lit += (((_1042 + (((_1050 + ((float3(1.0) - _1050) * powr(1.0 - fast::max(dot(_985, _1106), 0.0), 5.0))) * (((_1031 / ((3.1415927410125732421875 * _1124) * _1124)) * (0.5 / fast::max(mix((2.0 * _1095) * _1036, _1095 + _1036, _1027), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1095))) * _175.fa_light_color[li].xyz) * (_1095 * (_1087.attenuation * _1087.shadow)));\n        }\n        float3 param_7 = _1012;\n        float3 param_8 = _985;\n        float3 param_9 = _1050;\n        float param_10 = _1023;\n        float3 _1194 = lit;\n        float3 _1195 = _1194 + (fa_sky_reflection(param_7, param_8, param_9, param_10, _293, fa_env_tex, fa_env_smp) * _1473);\n        lit = _1195;\n        result = _1195;\n    }\n    result += _1474;\n    bool _1204 = _293.fa_fog.w > 0.0;\n    bool _1212;\n    if (!_1204)\n    {\n        _1212 = _293.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1212 = _1204;\n    }\n    if (_1212)\n    {\n        float3 _1221 = in.fa_world_pos - _293.fa_camera_pos.xyz;\n        float _1228 = dot(_1221, _293.fa_fog_c.xyz);\n        bool _1232 = _293.fa_fog_c.w > 0.5;\n        float _1233;\n        if (_1232)\n        {\n            _1233 = _1228;\n        }\n        else\n        {\n            _1233 = length(_1221);\n        }\n        float _1245 = _1233 - _293.fa_fog_b.x;\n        if (_1245 > 0.0)\n        {\n            float _1254 = _293.fa_fog.w * _1245;\n            float tau = _1254 * _1254;\n            if (_293.fa_fog_b.y > 0.0)\n            {\n                float _1270;\n                if (_1232)\n                {\n                    _1270 = in.fa_world_pos.y - (_293.fa_fog_c.y * _1228);\n                }\n                else\n                {\n                    _1270 = _293.fa_camera_pos.y;\n                }\n                float _1291 = mix(_1270, in.fa_world_pos.y, fast::clamp(_293.fa_fog_b.x / _1233, 0.0, 1.0));\n                float _1295 = in.fa_world_pos.y - _1291;\n                float _1300 = _1291 - _293.fa_fog_b.z;\n                float _1305 = in.fa_world_pos.y - _293.fa_fog_b.z;\n                bool _1308 = _1300 <= 0.0;\n                bool _1309 = !_1308;\n                bool _1315;\n                if (_1309)\n                {\n                    _1315 = _293.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1315 = _1308;\n                }\n                float _1316;\n                if (_1315)\n                {\n                    _1316 = _293.fa_fog_b.y;\n                }\n                else\n                {\n                    _1316 = _293.fa_fog_b.y * exp(-fast::min(_293.fa_fog_b.w * _1300, 80.0));\n                }\n                bool _1343;\n                if (_1309)\n                {\n                    _1343 = _293.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1343 = _1308;\n                }\n                float _1344;\n                if (_1343)\n                {\n                    _1344 = _293.fa_fog_b.y * _1300;\n                }\n                else\n                {\n                    _1344 = (_293.fa_fog_b.y * (1.0 - exp(-fast::min(_293.fa_fog_b.w * _1300, 80.0)))) / _293.fa_fog_b.w;\n                }\n                bool _1369 = _1305 <= 0.0;\n                bool _1376;\n                if (!_1369)\n                {\n                    _1376 = _293.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1376 = _1369;\n                }\n                float _1377;\n                if (_1376)\n                {\n                    _1377 = _293.fa_fog_b.y * _1305;\n                }\n                else\n                {\n                    _1377 = (_293.fa_fog_b.y * (1.0 - exp(-fast::min(_293.fa_fog_b.w * _1305, 80.0)))) / _293.fa_fog_b.w;\n                }\n                float _1404;\n                if (abs(_1295) < 0.001000000047497451305389404296875)\n                {\n                    _1404 = _1316;\n                }\n                else\n                {\n                    _1404 = (_1377 - _1344) / _1295;\n                }\n                tau += (_1245 * fast::max(_1404, 0.0));\n            }\n            result = mix(result, _293.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _1469);\n    return out;\n}\n\n",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_175",
            "msl_buffer_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_293",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_670",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float3 fa_lm [[user(locn6)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _396 = _273.world_pos;\n    float4 _280 = float4(_396, 1.0);\n    fa_world_pos = _396;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_shadow_pos = _136.fa_light_vp * _280;\n    gl_Position = _136.fa_view_proj * _280;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float4 glow;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float3 fa_lm [[user(locn6)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _729 = fa_linear_to_srgb(param);\n        c = _729;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _737 = fa_srgb_to_linear(param_1);\n            c = _737;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _103;\n    if (bool(i.front_facing))\n    {\n        _103 = i.world_normal;\n    }\n    else\n    {\n        _103 = -i.world_normal;\n    }\n    float3 _127 = fast::normalize(i.world_tangent.xyz - (_103 * dot(_103, i.world_tangent.xyz)));\n    float3 _155 = fast::normalize(((_127 * m.x) + ((cross(_103, _127) * i.world_tangent.w) * m.y)) + (_103 * m.z));\n    float3 _158;\n    if (bool(i.front_facing))\n    {\n        _158 = _155;\n    }\n    else\n    {\n        _158 = -_155;\n    }\n    return _158;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _293, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _293.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _769 = fa_tex_fix(param_2, param_3);\n    float4 _1572 = base_t;\n    _1572.x = _769.x;\n    _1572.y = _769.y;\n    _1572.z = _769.z;\n    base_t = _1572;\n    float4 _783 = (_1572 * _293.fa_base_color) * i.vertex_color;\n    float3 _1540 = i.world_normal;\n    if (_293.fa_maps.z > 0.5)\n    {\n        float param_4 = _293.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _816 = fa_tex_fix(param_6, param_7);\n        float3 _819 = (_816 * 2.0) - float3(1.0);\n        float2 _824 = _819.xy * _293.fa_maps.x;\n        float3 _1580 = _819;\n        _1580.x = _824.x;\n        _1580.y = _824.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1580;\n        _1540 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _293.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _853 = fa_tex_fix(param_12, param_13);\n    float4 _1583 = mrt;\n    _1583.x = _853.x;\n    _1583.y = _853.y;\n    _1583.z = _853.z;\n    mrt = _1583;\n    float param_14 = _293.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _892 = fa_tex_fix(param_16, param_17);\n    float param_18 = _293.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _919 = fa_tex_fix(param_20, param_21);\n    return Surface{ _783.xyz, _783.w, _1540, fast::clamp(_293.fa_pbr.x * _853.z, 0.0, 1.0), fast::clamp(_293.fa_pbr.y * _853.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_293.fa_maps.y * (_892.x - 1.0)), _293.fa_emissive.xyz + (_293.fa_model_emissive.xyz * _919) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_material& _670)\n{\n    s.emission += (_670.glow.xyz * _670.glow.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _293, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_293.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _293.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _293, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _293, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _175)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _186 = _175.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_186)\n    {\n        l = fast::normalize(_175.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _204 = _175.fa_light_pos[li].xyz - world_pos;\n        float _206 = length(_204);\n        dist = _206;\n        l = _204 / float3(fast::max(_206, 9.9999997473787516355514526367188e-05));\n        float _222 = _206 / fast::max(_175.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _228 = fast::clamp(1.0 - (_222 * _222), 0.0, 1.0);\n        atten = _228 * _228;\n        if (_175.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_175.fa_light_dir[li].w, mix(_175.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_175.fa_light_dir[li].xyz)));\n        }\n    }\n    int _279;\n    if (_186)\n    {\n        _279 = 0;\n    }\n    else\n    {\n        _279 = (_175.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _175.fa_light_color[li].xyz * atten, atten, 1.0, dist, _279 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_pcf(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _293, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_293.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _306 = coord.xyz / float3(coord.w);\n    float3 p = _306;\n    float2 suv = (_306.xy * 0.5) + float2(0.5);\n    if (_293.fa_counts.z > 0.5)\n    {\n        float3 _1554 = p;\n        _1554.z = (_1554.z * 0.5) + 0.5;\n        p = _1554;\n    }\n    else\n    {\n        float2 _1557 = suv;\n        _1557.y = 1.0 - _1557.y;\n        suv = _1557;\n    }\n    bool _334 = suv.x < 0.0;\n    bool _341;\n    if (!_334)\n    {\n        _341 = suv.x > 1.0;\n    }\n    else\n    {\n        _341 = _334;\n    }\n    bool _348;\n    if (!_341)\n    {\n        _348 = suv.y < 0.0;\n    }\n    else\n    {\n        _348 = _341;\n    }\n    bool _355;\n    if (!_348)\n    {\n        _355 = suv.y > 1.0;\n    }\n    else\n    {\n        _355 = _348;\n    }\n    bool _362;\n    if (!_355)\n    {\n        _362 = p.z > 1.0;\n    }\n    else\n    {\n        _362 = _355;\n    }\n    if (_362)\n    {\n        return 1.0;\n    }\n    float _377 = _293.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _377) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _293.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _293, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2, _293, fa_shadow_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_lights& _175, constant fa_mesh_fs_params& _293, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp, thread float4& fa_shadow_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _638 = fa_light_sample(param, param_1, _175);\n    float3 _1525 = _638.direction;\n    float3 _1520 = _638.color;\n    float _1527 = _638.attenuation;\n    float _1522 = _638.shadow;\n    int _1530 = _638.type;\n    if ((_1530 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1525;\n        float _652 = fa_shadow_factor(param_2, param_3, _293, fa_shadow_tex, fa_shadow_smp, fa_shadow_pos);\n        _1522 = _652;\n        _1520 = _175.fa_light_color[li].xyz * (_1527 * _652);\n    }\n    return LightSample{ _1525, _1520, _1527, _1522, _638._distance, _1530 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _574 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _577 = _574.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_577 * _577, exp2((-9.27999973297119140625) * ndv)) * _577) + _574.y)) + _574.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _293, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_293.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _293.fa_env_horizon.w)).xyz;\n    }\n    float _477 = rough * rough;\n    float _508 = 0.60000002384185791015625 * _477;\n    return mix(mix(_293.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_293.fa_env_horizon.xyz, _293.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _477)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _508, 0.0500000007450580596923828125 + _508, d.y))), ((_293.fa_env_sky.xyz + _293.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_477 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _293, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _616 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _293, fa_env_tex, fa_env_smp) * ((f0 * _616.x) + float3(_616.y));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _293 [[buffer(1)]], constant fa_lights& _175 [[buffer(2)]], constant fa_material& _670 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_lightmap [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _1445 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1445 = -_1445;\n    }\n    float3 _985 = fast::normalize(_293.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1445, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _985, short(gl_FrontFacing) };\n    Surface _990 = fa_standard_surface(param, _293, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _1468 = _990.albedo;\n    float _1469 = _990.alpha;\n    float3 _1470 = _990.normal;\n    float _1471 = _990.metallic;\n    float _1472 = _990.roughness;\n    float _1473 = _990.occlusion;\n    float3 _1474 = _990.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1445, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _985, short(gl_FrontFacing) };\n    Surface param_2 = _990;\n    surface(param_1, param_2, _670);\n    _1468 = param_2.albedo;\n    _1469 = param_2.alpha;\n    _1470 = param_2.normal;\n    _1471 = param_2.metallic;\n    _1472 = param_2.roughness;\n    _1473 = param_2.occlusion;\n    _1474 = param_2.emission;\n    float3 result;\n    if (_293.fa_emissive.w > 0.5)\n    {\n        result = _1468;\n    }\n    else\n    {\n        float3 _1012 = fast::normalize(_1470);\n        float _1019 = fast::clamp(_1471, 0.0, 1.0);\n        float _1023 = fast::clamp(_1472, 0.0500000007450580596923828125, 1.0);\n        float _1027 = _1023 * _1023;\n        float _1031 = _1027 * _1027;\n        float _1036 = fast::max(dot(_1012, _985), 9.9999997473787516355514526367188e-05);\n        float3 _1042 = _1468 * (1.0 - _1019);\n        float3 _1050 = mix(float3(0.039999999105930328369140625), _1468, float3(_1019));\n        float3 param_3 = _1012;\n        float3 lit = (fa_indirect_diffuse(param_3, _293, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap) * _1042) * _1473;\n        int _1063 = int(_293.fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1063)\n            {\n                break;\n            }\n            int param_4 = li;\n            float3 param_5 = in.fa_world_pos;\n            float3 param_6 = _1445;\n            LightSample _1087 = fa_light_shadowed(param_4, param_5, param_6, _175, _293, fa_shadow_tex, fa_shadow_smp, in.fa_shadow_pos);\n            float3 _1503 = _1087.direction;\n            float _1095 = fast::max(dot(_1012, _1503), 0.0);\n            float3 _1106 = fast::normalize(_1503 + _985);\n            float _1111 = fast::max(dot(_1012, _1106), 0.0);\n            float _1124 = ((_1111 * _1111) * (_1031 - 1.0)) + 1.0;\n            lit += (((_1042 + (((_1050 + ((float3(1.0) - _1050) * powr(1.0 - fast::max(dot(_985, _1106), 0.0), 5.0))) * (((_1031 / ((3.1415927410125732421875 * _1124) * _1124)) * (0.5 / fast::max(mix((2.0 * _1095) * _1036, _1095 + _1036, _1027), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1095))) * _175.fa_light_color[li].xyz) * (_1095 * (_1087.attenuation * _1087.shadow)));\n        }\n        float3 param_7 = _1012;\n        float3 param_8 = _985;\n        float3 param_9 = _1050;\n        float param_10 = _1023;\n        float3 _1194 = lit;\n        float3 _1195 = _1194 + (fa_sky_reflection(param_7, param_8, param_9, param_10, _293, fa_env_tex, fa_env_smp) * _1473);\n        lit = _1195;\n        result = _1195;\n    }\n    result += _1474;\n    bool _1204 = _293.fa_fog.w > 0.0;\n    bool _1212;\n    if (!_1204)\n    {\n        _1212 = _293.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1212 = _1204;\n    }\n    if (_1212)\n    {\n        float3 _1221 = in.fa_world_pos - _293.fa_camera_pos.xyz;\n        float _1228 = dot(_1221, _293.fa_fog_c.xyz);\n        bool _1232 = _293.fa_fog_c.w > 0.5;\n        float _1233;\n        if (_1232)\n        {\n            _1233 = _1228;\n        }\n        else\n        {\n            _1233 = length(_1221);\n        }\n        float _1245 = _1233 - _293.fa_fog_b.x;\n        if (_1245 > 0.0)\n        {\n            float _1254 = _293.fa_fog.w * _1245;\n            float tau = _1254 * _1254;\n            if (_293.fa_fog_b.y > 0.0)\n            {\n                float _1270;\n                if (_1232)\n                {\n                    _1270 = in.fa_world_pos.y - (_293.fa_fog_c.y * _1228);\n                }\n                else\n                {\n                    _1270 = _293.fa_camera_pos.y;\n                }\n                float _1291 = mix(_1270, in.fa_world_pos.y, fast::clamp(_293.fa_fog_b.x / _1233, 0.0, 1.0));\n                float _1295 = in.fa_world_pos.y - _1291;\n                float _1300 = _1291 - _293.fa_fog_b.z;\n                float _1305 = in.fa_world_pos.y - _293.fa_fog_b.z;\n                bool _1308 = _1300 <= 0.0;\n                bool _1309 = !_1308;\n                bool _1315;\n                if (_1309)\n                {\n                    _1315 = _293.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1315 = _1308;\n                }\n                float _1316;\n                if (_1315)\n                {\n                    _1316 = _293.fa_fog_b.y;\n                }\n                else\n                {\n                    _1316 = _293.fa_fog_b.y * exp(-fast::min(_293.fa_fog_b.w * _1300, 80.0));\n                }\n                bool _1343;\n                if (_1309)\n                {\n                    _1343 = _293.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1343 = _1308;\n                }\n                float _1344;\n                if (_1343)\n                {\n                    _1344 = _293.fa_fog_b.y * _1300;\n                }\n                else\n                {\n                    _1344 = (_293.fa_fog_b.y * (1.0 - exp(-fast::min(_293.fa_fog_b.w * _1300, 80.0)))) / _293.fa_fog_b.w;\n                }\n                bool _1369 = _1305 <= 0.0;\n                bool _1376;\n                if (!_1369)\n                {\n                    _1376 = _293.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1376 = _1369;\n                }\n                float _1377;\n                if (_1376)\n                {\n                    _1377 = _293.fa_fog_b.y * _1305;\n                }\n                else\n                {\n                    _1377 = (_293.fa_fog_b.y * (1.0 - exp(-fast::min(_293.fa_fog_b.w * _1305, 80.0)))) / _293.fa_fog_b.w;\n                }\n                float _1404;\n                if (abs(_1295) < 0.001000000047497451305389404296875)\n                {\n                    _1404 = _1316;\n                }\n                else\n                {\n                    _1404 = (_1377 - _1344) / _1295;\n                }\n                tau += (_1245 * fast::max(_1404, 0.0));\n            }\n            result = mix(result, _293.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _1469);\n    return out;\n}\n\n",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_175",
            "msl_buffer_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_293",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_670",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_material\n{\n    float4 glow;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _188 = fa_linear_to_srgb(param);\n        c = _188;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _197 = fa_srgb_to_linear(param_1);\n            c = _197;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _229, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _229.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _240 = fa_tex_fix(param_2, param_3);\n    float4 _599 = base_t;\n    _599.x = _240.x;\n    _599.y = _240.y;\n    _599.z = _240.z;\n    base_t = _599;\n    float4 _255 = (_599 * _229.fa_base_color) * i.vertex_color;\n    float3 _580 = i.world_normal;\n    if (_229.fa_maps.z > 0.5)\n    {\n        float param_4 = _229.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _288 = fa_tex_fix(param_6, param_7);\n        float3 _292 = (_288 * 2.0) - float3(1.0);\n        float2 _297 = _292.xy * _229.fa_maps.x;\n        float3 _607 = _292;\n        _607.x = _297.x;\n        _607.y = _297.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _607;\n        _580 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _229.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _326 = fa_tex_fix(param_12, param_13);\n    float4 _610 = mrt;\n    _610.x = _326.x;\n    _610.y = _326.y;\n    _610.z = _326.z;\n    mrt = _610;\n    float param_14 = _229.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _367 = fa_tex_fix(param_16, param_17);\n    float param_18 = _229.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _394 = fa_tex_fix(param_20, param_21);\n    return Surface{ _255.xyz, _255.w, _580, fast::clamp(_229.fa_pbr.x * _326.z, 0.0, 1.0), fast::clamp(_229.fa_pbr.y * _326.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_229.fa_maps.y * (_367.x - 1.0)), _229.fa_emissive.xyz + (_229.fa_model_emissive.xyz * _394) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_material& _124)\n{\n    s.emission += (_124.glow.xyz * _124.glow.w);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _229 [[buffer(1)]], constant fa_material& _124 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _527 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _527 = -_527;\n    }\n    float3 _440 = fast::normalize(_229.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _527, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _440, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _527, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _440, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _229, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, _124);\n    float3 _455 = fast::normalize(param_2.normal);\n    float3 _470 = fast::normalize(float3(dot(in.fa_pre_r0, _455), dot(in.fa_pre_r1, _455), dot(in.fa_pre_r2, _455)));\n    float _482 = _470.z;\n    float2 e = _470.xy / float2((abs(_470.x) + abs(_470.y)) + abs(_482));\n    if (_482 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_124",
            "msl_buffer_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_229",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_material\n{\n    float4 glow;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _188 = fa_linear_to_srgb(param);\n        c = _188;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _197 = fa_srgb_to_linear(param_1);\n            c = _197;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _229, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _229.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _240 = fa_tex_fix(param_2, param_3);\n    float4 _599 = base_t;\n    _599.x = _240.x;\n    _599.y = _240.y;\n    _599.z = _240.z;\n    base_t = _599;\n    float4 _255 = (_599 * _229.fa_base_color) * i.vertex_color;\n    float3 _580 = i.world_normal;\n    if (_229.fa_maps.z > 0.5)\n    {\n        float param_4 = _229.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _288 = fa_tex_fix(param_6, param_7);\n        float3 _292 = (_288 * 2.0) - float3(1.0);\n        float2 _297 = _292.xy * _229.fa_maps.x;\n        float3 _607 = _292;\n        _607.x = _297.x;\n        _607.y = _297.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _607;\n        _580 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _229.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _326 = fa_tex_fix(param_12, param_13);\n    float4 _610 = mrt;\n    _610.x = _326.x;\n    _610.y = _326.y;\n    _610.z = _326.z;\n    mrt = _610;\n    float param_14 = _229.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _367 = fa_tex_fix(param_16, param_17);\n    float param_18 = _229.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _394 = fa_tex_fix(param_20, param_21);\n    return Surface{ _255.xyz, _255.w, _580, fast::clamp(_229.fa_pbr.x * _326.z, 0.0, 1.0), fast::clamp(_229.fa_pbr.y * _326.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_229.fa_maps.y * (_367.x - 1.0)), _229.fa_emissive.xyz + (_229.fa_model_emissive.xyz * _394) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_material& _124)\n{\n    s.emission += (_124.glow.xyz * _124.glow.w);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _229 [[buffer(1)]], constant fa_material& _124 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _527 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _527 = -_527;\n    }\n    float3 _440 = fast::normalize(_229.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _527, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _440, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _527, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _440, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _229, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, _124);\n    float3 _455 = fast::normalize(param_2.normal);\n    float3 _470 = fast::normalize(float3(dot(in.fa_pre_r0, _455), dot(in.fa_pre_r1, _455), dot(in.fa_pre_r2, _455)));\n    float _482 = _470.z;\n    float2 e = _470.xy / float2((abs(_470.x) + abs(_470.y)) + abs(_482));\n    if (_482 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_124",
            "msl_buffer_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_229",
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
