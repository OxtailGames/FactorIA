{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "fc5698cd941e0af057040ef4c307a7106b1e2971cc74f7501935817daedb7ce8",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3349[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1344 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1351;\n    if (!_1344)\n    {\n        _1351 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1351 = _1344;\n    }\n    bool _1359;\n    if (!_1351)\n    {\n        _1359 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1359 = _1351;\n    }\n    bool _1366;\n    if (!_1359)\n    {\n        _1366 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1366 = _1359;\n    }\n    bool _1373;\n    if (!_1366)\n    {\n        _1373 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1373 = _1366;\n    }\n    if (_1373)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1383 = vec4(world_pos, 1.0);\n    float _1389 = dot(fa_mesh_fs_params[16], _1383);\n    if (!(_1389 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1411 = vec2(dot(fa_mesh_fs_params[14], _1383), dot(fa_mesh_fs_params[15], _1383)) / vec2(_1389);\n    int _1415 = int(fa_mesh_fs_params[18].x);\n    int _1419 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1419) + clamp(int(floor(((_1411.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1419 - 1)) * _1415)) + clamp(int(floor(((_1411.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1415 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1495 = fa_cluster_texel(param);\n    return ivec2(int(_1495.x), int(_1495.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3891 = fa_cluster_lookup(param);\n    fa_cl_slot = _3891.x;\n    fa_cl_local = _3891.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4203 = fa_linear_to_srgb(param);\n        c = _4203;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4211 = fa_srgb_to_linear(param_1);\n            c = _4211;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _297;\n    if (i.front_facing)\n    {\n        _297 = i.world_normal;\n    }\n    else\n    {\n        _297 = -i.world_normal;\n    }\n    vec3 _321 = normalize(i.world_tangent.xyz - (_297 * dot(_297, i.world_tangent.xyz)));\n    vec3 _349 = normalize(((_321 * m.x) + ((cross(_297, _321) * i.world_tangent.w) * m.y)) + (_297 * m.z));\n    vec3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4242 = fa_tex_fix(param_2, param_3);\n    vec4 _5265 = base_t;\n    _5265.x = _4242.x;\n    _5265.y = _4242.y;\n    _5265.z = _4242.z;\n    base_t = _5265;\n    vec4 _4256 = (_5265 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5117 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4288 = fa_tex_fix(param_6, param_7);\n        vec3 _4291 = (_4288 * 2.0) - vec3(1.0);\n        vec2 _4296 = _4291.xy * fa_mesh_fs_params[6].x;\n        vec3 _5273 = _4291;\n        _5273.x = _4296.x;\n        _5273.y = _4296.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5273;\n        _5117 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4324 = fa_tex_fix(param_12, param_13);\n    vec4 _5276 = mrt;\n    _5276.x = _4324.x;\n    _5276.y = _4324.y;\n    _5276.z = _4324.z;\n    mrt = _5276;\n    vec4 _4352 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4352.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4363 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4393 = fa_tex_fix(param_20, param_21);\n    float _5122 = fa_mesh_fs_params[20].x;\n    float _5123 = fa_mesh_fs_params[20].y;\n    float _5126 = fa_mesh_fs_params[20].z;\n    float _5125 = fa_mesh_fs_params[21].w;\n    float _5128 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5122 *= _4363.y;\n            _5123 *= _4363.z;\n            _5125 *= _4352.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5126 *= mrt.x;\n            _5128 *= mrt.w;\n        }\n    }\n    return Surface(_4256.xyz, _4256.w, _5117, clamp(fa_mesh_fs_params[5].x * _4324.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4363.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4393), _5122, _5123, fa_mesh_fs_params[21].xyz, _5125, _5126, fa_mesh_fs_params[20].w, _5128, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1575 = rect.zw - rect.xy;\n    vec2 _1579 = _1575 * atlas;\n    vec2 _1583 = ddx * _1579;\n    vec2 _1587 = ddy * _1579;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1575), clamp(0.5 * log2(max(max(dot(_1583, _1583), dot(_1587, _1587)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1620 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1627;\n    if (!_1620)\n    {\n        _1627 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1627 = _1620;\n    }\n    if (_1627)\n    {\n        return;\n    }\n    vec3 _1633 = dFdx(world_pos);\n    vec3 _1636 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1640 = fa_cluster_texel(param);\n    int _1644 = int(_1640.w);\n    if (_1644 < 1)\n    {\n        return;\n    }\n    int _1654 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1654;\n    vec4 _1658 = fa_light_texel(param_1);\n    vec2 _1661 = _1658.yz;\n    int _1665 = int(_1658.w);\n    int param_2 = _1654 + 1;\n    vec4 _1670 = fa_light_texel(param_2);\n    float _1671 = _1670.x;\n    int _1677 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1681 = int(_1640.z);\n    vec3 _1946;\n    for (int k = 0; k < _1644; k++)\n    {\n        int _1694 = _1681 + k;\n        int param_3 = _1665 + (_1694 >> 2);\n        int _1711 = (_1654 + 2) + (int(fa_light_texel(param_3)[_1694 & 3]) * 7);\n        int param_4 = _1711 + 6;\n        vec4 _1716 = fa_light_texel(param_4);\n        if (((int(_1716.w + 0.5) >> _1677) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1711;\n        vec4 _1731 = fa_light_texel(param_5);\n        int param_6 = _1711 + 1;\n        vec4 _1736 = fa_light_texel(param_6);\n        int param_7 = _1711 + 2;\n        vec4 _1741 = fa_light_texel(param_7);\n        vec3 _1744 = _1731.xyz;\n        float _1749 = dot(_1744, world_pos) + _1731.w;\n        vec3 _1751 = _1736.xyz;\n        float _1756 = dot(_1751, world_pos) + _1736.w;\n        vec3 _1758 = _1741.xyz;\n        float _1763 = dot(_1758, world_pos) + _1741.w;\n        bool _1768 = abs(_1749) > 0.5;\n        bool _1776;\n        if (!_1768)\n        {\n            _1776 = abs(_1756) > 0.5;\n        }\n        else\n        {\n            _1776 = _1768;\n        }\n        bool _1784;\n        if (!_1776)\n        {\n            _1784 = abs(_1763) > 0.5;\n        }\n        else\n        {\n            _1784 = _1776;\n        }\n        if (_1784)\n        {\n            continue;\n        }\n        float _1799 = clamp(dot(geo_normal, normalize(_1758)) * _1716.z, 0.0, 1.0);\n        if (_1799 <= 0.0)\n        {\n            continue;\n        }\n        float _1819 = (clamp((0.5 - abs(_1763)) * 10.0, 0.0, 1.0) * _1799) * _1716.x;\n        vec2 _1827 = vec2(_1749 + 0.5, 0.5 - _1756);\n        vec2 _1837 = vec2(dot(_1744, _1633), dot(_1751, _1633));\n        vec2 _1847 = vec2(dot(_1744, _1636), dot(_1751, _1636));\n        int param_8 = _1711 + 5;\n        vec4 _1852 = fa_light_texel(param_8);\n        int param_9 = _1711 + 3;\n        vec4 _1857 = fa_light_texel(param_9);\n        int param_10 = _1711 + 4;\n        vec4 _1862 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1852.xyz;\n        bool _1872 = _1857.z > _1857.x;\n        if (_1872)\n        {\n            vec4 param_11 = _1857;\n            vec2 param_12 = _1827;\n            vec2 param_13 = _1661;\n            vec2 param_14 = _1837;\n            vec2 param_15 = _1847;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1671 > 0.5) && (_1671 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1898 = fa_dc_to_linear(param_16);\n                vec4 _5197 = tx;\n                _5197.x = _1898.x;\n                _5197.y = _1898.y;\n                _5197.z = _1898.z;\n                tx = _5197;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1819 * tex_a) * _1852.w, 0.0, 1.0)));\n        if (_1862.z > _1862.x)\n        {\n            vec4 param_17 = _1862;\n            vec2 param_18 = _1827;\n            vec2 param_19 = _1661;\n            vec2 param_20 = _1837;\n            vec2 param_21 = _1847;\n            vec4 _1942 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1671 > 1.5)\n            {\n                vec3 param_22 = _1942.xyz;\n                vec3 _1952 = fa_dc_to_srgb(param_22);\n                _1946 = _1952;\n            }\n            else\n            {\n                _1946 = _1942.xyz;\n            }\n            vec3 _1961 = (_1946 * 2.0) - vec3(1.0);\n            vec2 _1966 = _1961.xy * _1716.y;\n            vec3 _1988 = (normalize(_1744) * _1966.x) + (normalize(_1751) * _1966.y);\n            vec3 _1991 = normalize(normal);\n            normal = normalize(mix(_1991, normalize((_1991 * max(_1961.z, 0.0500000007450580596923828125)) + (_1988 - (_1991 * dot(_1991, _1988)))), vec3(clamp(_1819 * (_1872 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _593 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _606 = (c - (ru * hx)) - p;\n        vec3 _612 = ru * (2.0 * hx);\n        float _618 = max(dot(_612, _612), 9.9999999392252902907785028219223e-09);\n        float _622 = dot(_606, _612);\n        float t = clamp((-_622) / _618, 0.0, 1.0);\n        if (_593)\n        {\n            float _637 = dot(r, _612);\n            float _643 = _618 - (_637 * _637);\n            if (abs(_643) > (9.9999997473787516355514526367188e-06 * _618))\n            {\n                t = clamp(((dot(r, _606) * _637) - _622) / _643, 0.0, 1.0);\n            }\n        }\n        return (p + _606) + (_612 * t);\n    }\n    vec3 q = p;\n    float _675 = dot(r, axis);\n    bool _683;\n    if (_593)\n    {\n        _683 = abs(_675) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _683 = _593;\n    }\n    if (_683)\n    {\n        float _693 = dot(c - p, axis) / _675;\n        if (_693 > 0.0)\n        {\n            q = p + (r * _693);\n        }\n    }\n    vec3 _706 = q - c;\n    vec2 xy = vec2(dot(_706, ru), dot(_706, uu));\n    if (shape > 0.5)\n    {\n        float _721 = length(xy);\n        if (_721 > hx)\n        {\n            xy *= (hx / _721);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _541;\n        if (_518 >= _514.z)\n        {\n            _541 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _541 = (d.z > 0.0) ? 4 : 5;\n        }\n        _528 = _541;\n    }\n    return _528;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _467 = dot(d, right);\n    float _471 = dot(d, up);\n    float _482;\n    if (((_467 * _467) + (_471 * _471)) > 1.0000000133514319600180897396058e-10)\n    {\n        _482 = atan(_471, _467) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _482 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_482 - floor(_482)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _759 = fa_light_base(param);\n    bool _763 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _759;\n    vec4 _767 = fa_light_texel(param_1);\n    int param_2 = _759 + 1;\n    vec4 _772 = fa_light_texel(param_2);\n    float _775 = _772.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _787 = _763 && (_775 > 2.5);\n    fa_light_is_area = _787;\n    bool _789 = _775 < 0.5;\n    vec3 l;\n    if (_789)\n    {\n        l = normalize(_767.xyz);\n        if (_763)\n        {\n            int param_3 = _759 + 6;\n            vec4 _803 = fa_light_texel(param_3);\n            if (_803.z > 0.5)\n            {\n                int param_4 = _759 + 4;\n                vec4 _813 = fa_light_texel(param_4);\n                int param_5 = _759 + 5;\n                vec4 _818 = fa_light_texel(param_5);\n                vec2 param_6 = _803.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _813.xyz) * _813.w, (-dot(world_pos, _818.xyz)) * _818.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _848 = _767.xyz;\n        vec3 _850 = _848 - world_pos;\n        vec3 to_light = _850;\n        float _853 = length(_850);\n        float reach = _853;\n        bool front = true;\n        if (_787)\n        {\n            int param_8 = _759 + 7;\n            reach = max(_853 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _759 + 4;\n            vec4 _877 = fa_light_texel(param_9);\n            int param_10 = _759 + 5;\n            vec4 _882 = fa_light_texel(param_10);\n            int param_11 = _759 + 6;\n            vec4 _887 = fa_light_texel(param_11);\n            float _888 = _887.w;\n            int param_12 = _759 + 2;\n            vec3 _895 = normalize(fa_light_texel(param_12).xyz);\n            bool _897 = _888 > 1.5;\n            bool _905;\n            if (!_897)\n            {\n                _905 = dot(_895, to_light) < 0.0;\n            }\n            else\n            {\n                _905 = _897;\n            }\n            front = _905;\n            vec3 r = vec3(0.0);\n            vec3 _914 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _918 = dot(n, n) > 0.5;\n            bool _926;\n            if (_918)\n            {\n                _926 = dot(_914, _914) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _926 = _918;\n            }\n            if (_926)\n            {\n                r = reflect(-normalize(_914), normalize(n));\n            }\n            vec3 param_13 = _848;\n            vec3 param_14 = _895;\n            vec3 param_15 = _877.xyz;\n            vec3 param_16 = _882.xyz;\n            float param_17 = _877.w;\n            float param_18 = _882.w;\n            float param_19 = _888;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _962 = length(to_light);\n        dist = _962;\n        l = to_light / vec3(max(_962, 9.9999997473787516355514526367188e-05));\n        float _976 = reach / max(_767.w, 0.001000000047497451305389404296875);\n        float _982 = clamp(1.0 - (_976 * _976), 0.0, 1.0);\n        float _984;\n        if (front)\n        {\n            _984 = _982 * _982;\n        }\n        else\n        {\n            _984 = 0.0;\n        }\n        atten = _984;\n        bool _995 = _775 < 2.5;\n        if ((_775 > 1.5) && _995)\n        {\n            int param_22 = _759 + 2;\n            vec4 _1003 = fa_light_texel(param_22);\n            float _1013 = _1003.w;\n            int param_23 = _759 + 3;\n            vec4 _1018 = fa_light_texel(param_23);\n            float _1019 = _1018.x;\n            float cos_inner = _1019;\n            if (_1019 > 1.5)\n            {\n                cos_inner = mix(_1013, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1013, cos_inner, dot(-l, normalize(_1003.xyz)));\n        }\n        if (_763 && (_775 < 1.5))\n        {\n            int param_24 = _759 + 6;\n            vec4 _1043 = fa_light_texel(param_24);\n            if (_1043.z > 0.5)\n            {\n                vec3 _1051 = -to_light;\n                int param_25 = _759 + 4;\n                int param_26 = _759 + 5;\n                vec3 _1065 = fa_light_texel(param_25).xyz;\n                vec3 _1069 = fa_light_texel(param_26).xyz;\n                vec3 _1078 = vec3(dot(_1051, _1065), dot(_1051, _1069), dot(_1051, cross(_1065, _1069)));\n                vec3 param_27 = _1078;\n                int _1082 = fa_cube_face(param_27);\n                int param_28 = _1082;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1109 = vec2(dot(_1078, cross(param_29, param_30)), dot(_1078, param_30)) / vec2(max(dot(_1078, param_29), 9.9999997473787516355514526367188e-05));\n                int _1113 = _1082 / 3;\n                vec2 param_31 = _1043.xy + (vec2(float(_1082 - (_1113 * 3)), float(_1113)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1109.x), 0.5 - (0.5 * _1109.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _759 + 7;\n            vec4 _1143 = fa_light_texel(param_33);\n            if (_1143.z > 0.5)\n            {\n                int param_34 = _759 + 2;\n                int param_35 = _759 + 4;\n                int param_36 = _759 + 5;\n                vec2 param_37 = _1143.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_763 && _995)\n            {\n                int param_42 = _759 + 6;\n                vec4 _1190 = fa_light_texel(param_42);\n                int param_43 = _759 + 7;\n                vec4 _1195 = fa_light_texel(param_43);\n                bool _1198 = _1190.z > 0.5;\n                bool _1205;\n                if (!_1198)\n                {\n                    _1205 = _1195.z > 0.5;\n                }\n                else\n                {\n                    _1205 = _1198;\n                }\n                if (_1205)\n                {\n                    int param_44 = _759 + 2;\n                    vec4 _1212 = fa_light_texel(param_44);\n                    vec3 _1216 = normalize(_1212.xyz);\n                    int param_45 = _759 + 4;\n                    vec4 _1221 = fa_light_texel(param_45);\n                    int param_46 = _759 + 5;\n                    vec4 _1226 = fa_light_texel(param_46);\n                    if (_1198)\n                    {\n                        vec3 _1234 = -to_light;\n                        float _1241 = _1212.w;\n                        float _1257 = 0.5 / max(dot(_1234, _1216) * (sqrt(max(1.0 - (_1241 * _1241), 0.0)) / max(_1241, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1190.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1234, _1221.xyz) * _1257), 0.5 - (dot(_1234, _1226.xyz) * _1257));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1195.z > 0.5)\n                    {\n                        vec2 param_49 = _1195.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1216;\n                        vec3 param_52 = _1221.xyz;\n                        vec3 param_53 = _1226.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4942 = _772.xyz * atten;\n    if (_763)\n    {\n        _4942 *= fa_light_tint;\n    }\n    int _1326;\n    if (_789)\n    {\n        _1326 = 0;\n    }\n    else\n    {\n        _1326 = ((_775 > 1.5) && (_775 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4942, atten, 1.0, dist, _1326);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4034 = n < 0;\n    bool _4041;\n    if (!_4034)\n    {\n        _4041 = n >= fa_light_count();\n    }\n    else\n    {\n        _4041 = _4034;\n    }\n    if (_4041)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4049 = fa_cl_light(param);\n    bool _4052 = fa_lm.z > 0.5;\n    bool _4058;\n    if (_4052)\n    {\n        int param_1 = _4049;\n        _4058 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _4058 = _4052;\n    }\n    if (_4058)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4049;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _4071 = fa_light_sample_n(param_2, param_3, param_4);\n    return _4071;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2063;\n    if (i == 0)\n    {\n        _2063 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2079;\n        if (i == 1)\n        {\n            _2079 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2087;\n            if (i == 2)\n            {\n                _2087 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2087 = fa_shadows[24].w;\n            }\n            _2079 = _2087;\n        }\n        _2063 = _2079;\n    }\n    return _2063;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2120 = fa_shadow_depth(param, param_1);\n    float _2124;\n    if (conv.x < 0.5)\n    {\n        _2124 = _2120;\n    }\n    else\n    {\n        _2124 = (conv.y * conv.z) / (conv.z - (_2120 * (conv.z - conv.y)));\n    }\n    return _2124;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2051 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2051), sin(_2051)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2170 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2179;\n        if (k < 0.0)\n        {\n            _2179 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2179 = k;\n        }\n        float _2199 = clamp((_2179 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2170;\n            vec2 _2218 = fa_shadow_vogel(param_3, param_4, param_5) * _2199;\n            vec2 param_6 = uv + (_2218 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2230 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2230 < (zr - (length(_2218) * plane)))\n            {\n                sum += _2230;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2256 = sum / cnt;\n        float _2266;\n        if (k < 0.0)\n        {\n            _2266 = (-k) / max(_2256, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2266 = k;\n        }\n        radius = clamp(((max(zr - _2256, 0.0) * unit) * _2266) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2288 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2288; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2288;\n        float param_11 = _2170;\n        vec2 _2307 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2307 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2307) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2288);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2349 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2354 = clamp(dot(n, l), 0.0, 1.0);\n    float _2360 = sqrt(1.0 - (_2354 * _2354));\n    float _2367 = min(_2360 / max(_2354, 0.20000000298023223876953125), 4.0);\n    float _2372;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2372 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2372 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2397 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2372 * _2360)), 1.0);\n    float _2404 = _2397.x;\n    bool _2407 = _2404 < fa_shadows[ci * 1 + 16].x;\n    bool _2416;\n    if (!_2407)\n    {\n        _2416 = _2404 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2416 = _2407;\n    }\n    bool _2425;\n    if (!_2416)\n    {\n        _2425 = _2397.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2425 = _2416;\n    }\n    bool _2434;\n    if (!_2425)\n    {\n        _2434 = _2397.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2434 = _2425;\n    }\n    bool _2441;\n    if (!_2434)\n    {\n        _2441 = _2397.z > 1.0;\n    }\n    else\n    {\n        _2441 = _2434;\n    }\n    if (_2441)\n    {\n        return -1.0;\n    }\n    float _2449;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2449 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2449 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2397.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2397.z - ((_2449 * (1.0 + (0.5 * _2367))) / _2349);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2349;\n    float param_5 = _2349 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2367, 3.0)) * 0.5) / _2349;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2837 = int(fa_shadows[25].x + 0.5);\n    if (_2837 < 1)\n    {\n        return 1.0;\n    }\n    float _2852 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2837 - 1;\n    if (_2852 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2864 = _2837 > 1;\n    bool _2871;\n    if (_2864)\n    {\n        _2871 = _2852 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2871 = _2864;\n    }\n    if (_2871)\n    {\n        ci = 1;\n    }\n    bool _2875 = _2837 > 2;\n    bool _2882;\n    if (_2875)\n    {\n        _2882 = _2852 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2882 = _2875;\n    }\n    if (_2882)\n    {\n        ci = 2;\n    }\n    bool _2886 = _2837 > 3;\n    bool _2893;\n    if (_2886)\n    {\n        _2893 = _2852 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2893 = _2886;\n    }\n    if (_2893)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2837)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2919 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2919;\n        if (_2919 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2944;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2944 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2944 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2963 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2944, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2974 = clamp((_2852 - (fa_shadow_split_at(param_7) - _2963)) / _2963, 0.0, 1.0);\n        if (_2974 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2837)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2995 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2995;\n                if (_2995 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2974);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _2507 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2514;\n    if (!_2507)\n    {\n        _2514 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2514 = _2507;\n    }\n    if (_2514)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2527 = fa_light_texel(param);\n    float _2528 = _2527.x;\n    if (_2528 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2537 = int(_2528 + 0.5);\n    int param_1 = _2537;\n    vec4 _2541 = fa_light_texel(param_1);\n    int param_2 = _2537 + 1;\n    vec4 _2546 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2549 = _2541.y;\n    if (_2549 > 0.0)\n    {\n        float _2566 = 1.0 - smoothstep(0.75 * _2549, _2549, length(world - fa_shadows[27].xyz));\n        fade = _2566;\n        if (_2566 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2541.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        vec3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2595 = (_2537 + 2) + (face * 6);\n    int param_6 = _2595;\n    int param_7 = _2595 + 1;\n    int param_8 = _2595 + 3;\n    vec4 _2609 = fa_light_texel(param_8);\n    int param_9 = _2595 + 4;\n    vec4 _2614 = fa_light_texel(param_9);\n    int param_10 = _2595 + 5;\n    vec4 _2619 = fa_light_texel(param_10);\n    float _2631 = _2619.x * max(dot(_2609, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2636 = clamp(dot(n, l), 0.0, 1.0);\n    float _2659 = clamp(dot(n, _2609.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2683 = min(sqrt(1.0 - (_2659 * _2659)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2609, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2686 = _2546.y;\n    float _2688;\n    if (_2686 > 0.0)\n    {\n        _2688 = _2686;\n    }\n    else\n    {\n        _2688 = 1.5 * _2631;\n    }\n    vec4 _2708 = vec4(world + (n * (_2688 * sqrt(1.0 - (_2636 * _2636)))), 1.0);\n    float _2712 = dot(_2609, _2708);\n    float _2715 = _2619.y;\n    if (_2712 < _2715)\n    {\n        return 1.0;\n    }\n    vec2 _2730 = vec2(dot(fa_light_texel(param_6), _2708), dot(fa_light_texel(param_7), _2708)) / vec2(_2712);\n    float _2732 = _2730.x;\n    bool _2735 = _2732 < _2614.x;\n    bool _2744;\n    if (!_2735)\n    {\n        _2744 = _2732 > _2614.z;\n    }\n    else\n    {\n        _2744 = _2735;\n    }\n    bool _2753;\n    if (!_2744)\n    {\n        _2753 = _2730.y < _2614.y;\n    }\n    else\n    {\n        _2753 = _2744;\n    }\n    bool _2762;\n    if (!_2753)\n    {\n        _2762 = _2730.y > _2614.w;\n    }\n    else\n    {\n        _2762 = _2753;\n    }\n    if (_2762)\n    {\n        return 1.0;\n    }\n    float _2768 = _2546.x;\n    float _2770;\n    if (_2768 > 0.0)\n    {\n        _2770 = _2768;\n    }\n    else\n    {\n        _2770 = 1.5 * _2631;\n    }\n    vec2 param_13 = _2730;\n    vec4 param_14 = _2614;\n    float param_15 = _2712 - (_2770 * (1.0 + (0.5 * _2683)));\n    float param_16 = _2631;\n    float param_17 = 1.0;\n    float param_18 = _2619.z * 0.25;\n    float param_19 = (_2631 * min(_2683, 3.0)) * 0.5;\n    vec3 param_20 = vec3(1.0, _2715, _2619.z);\n    int param_21 = int(_2541.z + 0.5);\n    float param_22 = _2541.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3918 = fa_lm.z > 0.5;\n    bool _3924;\n    if (_3918)\n    {\n        int param = li;\n        _3924 = fa_light_baked(param);\n    }\n    else\n    {\n        _3924 = _3918;\n    }\n    if (_3924)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3948 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5088 = _3948.color;\n    float _5090 = _3948.shadow;\n    if ((_3948.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3948.direction;\n        float _3962 = fa_shadow_factor(param_5, param_6);\n        _5090 = _3962;\n        _5088 *= _3962;\n    }\n    else\n    {\n        bool _3973 = _3948.type != 0;\n        bool _3979;\n        if (_3973)\n        {\n            _3979 = _3948.attenuation > 0.0;\n        }\n        else\n        {\n            _3979 = _3973;\n        }\n        if (_3979)\n        {\n            int param_7 = li;\n            vec3 param_8 = world_pos;\n            vec3 param_9 = gn;\n            vec3 param_10 = _3948.direction;\n            float _3991 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _5090 = _3991;\n            _5088 *= _3991;\n        }\n    }\n    return LightSample(_3948.direction, _5088, _3948.attenuation, _5090, _3948._distance, _3948.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4008 = n < 0;\n    bool _4015;\n    if (!_4008)\n    {\n        _4015 = n >= fa_light_count();\n    }\n    else\n    {\n        _4015 = _4008;\n    }\n    if (_4015)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _4030 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4030;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3274 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3282 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3285 = int(_3274);\n    int _3288 = int(_3282);\n    float _3298 = _3282 - float(_3288);\n    int _3354 = (_3285 * 9) + _3288;\n    int _3374 = ((_3285 + 1) * 9) + _3288;\n    return mix(mix(_3349[_3354], _3349[_3354 + 1], _3298), mix(_3349[_3374], _3349[_3374 + 1], _3298), _3274 - float(_3285));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4954 = false;\n    float _4955 = 1.0;\n    float _4956 = 1.0;\n    float _4957 = 1.0;\n    float _4958 = 0.0;\n    float _4959 = 0.0;\n    float _4960 = 0.0;\n    float _4961 = 0.0;\n    float _4963 = 1.0;\n    bool _4964 = false;\n    vec3 _4965 = vec3(0.0);\n    float _4966 = 1.0;\n    float _4967 = 1.0;\n    float _4968 = 1.0;\n    float _4969 = 0.0;\n    float _4970 = 0.0;\n    vec3 _4971 = vec3(1.0, 0.0, 0.0);\n    vec3 _4972 = vec3(0.0, 0.0, 1.0);\n    float _4973 = 1.0;\n    float _4974 = 1.0;\n    float _3425 = clamp(s.specular, 0.0, 1.0);\n    float _3429 = clamp(s.ior, 1.0, 3.0);\n    bool _3434 = (_3425 != 1.0) || (_3429 != 1.5);\n    bool _3443;\n    if (!_3434)\n    {\n        _3443 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3443 = _3434;\n    }\n    if (_3443)\n    {\n        float _3451 = (_3429 - 1.0) / (_3429 + 1.0);\n        f0 = mix(min(vec3(_3451 * _3451) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3425, s.albedo, vec3(metallic));\n        _4955 = mix(_3425, 1.0, metallic);\n        _4954 = true;\n    }\n    float _3478 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3478 > 0.0)\n    {\n        float _3486 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4958 = _3478;\n        _4959 = _3486;\n        float _3493 = _3486 * _3486;\n        _4960 = _3493;\n        _4961 = _3493 * _3493;\n        float _3505 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4963 = _3505;\n        _4956 = 1.0 - (_3478 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3505, 0.0, 1.0), 5.0))));\n        _4954 = true;\n    }\n    vec3 _3525 = max(s.sheen_color, vec3(0.0));\n    float _3534 = max(_3525.x, max(_3525.y, _3525.z));\n    if (_3534 > 0.0)\n    {\n        float _3542 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4964 = true;\n        _4965 = _3525;\n        _4966 = _3542;\n        _4967 = _3542 * _3542;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3542;\n        float _3559 = fa_sheen_albedo(param, param_1);\n        _4969 = _3559;\n        _4968 = 1.0 - min(_3534 * _3559, 1.0);\n        _4954 = true;\n    }\n    _4957 = _4956 * _4968;\n    float _3578 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3578 != 0.0)\n    {\n        vec3 _3593 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3593;\n        if (dot(_3593, _3593) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3605 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3605.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3605.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3605.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3609 = t;\n        vec3 _3610 = normalize(_3609);\n        t = _3610;\n        vec3 _3635 = normalize((_3610 * cos(s.anisotropy_rotation)) + ((cross(n, _3610) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4971 = _3635;\n        _4972 = cross(n, _3635);\n        float _3645 = roughness * roughness;\n        float _3651 = mix(_3645, 1.0, _3578 * _3578);\n        bool _3653 = _3578 > 0.0;\n        _4973 = _3653 ? _3651 : _3645;\n        _4974 = _3653 ? _3645 : _3651;\n        _4970 = _3578;\n        _4954 = true;\n    }\n    return FaLayers(_4954, _4955, _4956, _4957, _4958, _4959, _4960, _4961, i.world_normal, _4963, _4964, _4965, _4966, _4967, _4968, _4969, _4970, _4971, _4972, _4973, _4974);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3206 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3209 = _3206.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3209 * _3209, exp2((-9.27999973297119140625) * ndv)) * _3209) + _3206.y)) + _3206.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3130 = rough * rough;\n    float _3160 = 0.60000002384185791015625 * _3130;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3130)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3160, 0.0500000007450580596923828125 + _3160, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3130 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3686;\n        if (L.aniso >= 0.0)\n        {\n            _3686 = L.b;\n        }\n        else\n        {\n            _3686 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3686, v), _3686), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3719 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3719.x) + (vec3(L.f90) * _3719.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3774 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3774.x) + _3774.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3248 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3248.x) + vec3(_3248.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3813 = clamp(s.metallic, 0.0, 1.0);\n    float _3817 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _3824 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_3813));\n    vec3 f0 = _3824;\n    vec3 _3828 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _3828;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _3813;\n    float param_5 = _3817;\n    vec3 param_6 = _3824;\n    FaLayers _3845 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3845.on)\n    {\n        FaLayers param_7 = _3845;\n        vec3 param_8 = _3828;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _3817;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _3828;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _3817;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4091 = fa_light_unshadowed(param, param_1);\n        float _4099 = dot(_4091.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_4099 > bestPower)\n        {\n            bestPower = _4099;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4128 = fa_light(param_2, param_3);\n        float _4136;\n        if (dot(s.normal, _4128.direction) > 0.5)\n        {\n            _4136 = 1.0;\n        }\n        else\n        {\n            _4136 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _4128.color) * _4136);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3019 = int(fa_shadows[25].x + 0.5);\n    float _3029 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3034 = _3019 > 0;\n    bool _3043;\n    if (_3034)\n    {\n        int param = _3019 - 1;\n        _3043 = _3029 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3043 = _3034;\n    }\n    if (_3043)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3049 = _3019 > 1;\n        bool _3056;\n        if (_3049)\n        {\n            _3056 = _3029 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3056 = _3049;\n        }\n        if (_3056)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3062 = _3019 > 2;\n        bool _3069;\n        if (_3062)\n        {\n            _3069 = _3029 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3069 = _3062;\n        }\n        if (_3069)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3075 = _3019 > 3;\n        bool _3082;\n        if (_3075)\n        {\n            _3082 = _3029 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3082 = _3075;\n        }\n        if (_3082)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4828 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4828 = -_4828;\n    }\n    vec3 _4514 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4828, fa_world_tangent, fa_uv, fa_vertex_color, _4514, gl_FrontFacing);\n    Surface _4522 = fa_standard_surface(param_1);\n    vec3 _4859 = _4522.albedo;\n    float _4860 = _4522.alpha;\n    vec3 _4861 = _4522.normal;\n    float _4862 = _4522.metallic;\n    float _4863 = _4522.roughness;\n    float _4864 = _4522.occlusion;\n    vec3 _4865 = _4522.emission;\n    float _4866 = _4522.clearcoat;\n    float _4867 = _4522.clearcoat_roughness;\n    vec3 _4868 = _4522.sheen_color;\n    float _4869 = _4522.sheen_roughness;\n    float _4870 = _4522.anisotropy;\n    float _4871 = _4522.anisotropy_rotation;\n    float _4872 = _4522.specular;\n    float _4873 = _4522.ior;\n    vec3 _4874 = _4522.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4828, fa_world_tangent, fa_uv, fa_vertex_color, _4514, gl_FrontFacing);\n    Surface param_3 = _4522;\n    surface(param_2, param_3);\n    _4859 = param_3.albedo;\n    _4860 = param_3.alpha;\n    _4861 = param_3.normal;\n    _4862 = param_3.metallic;\n    _4863 = param_3.roughness;\n    _4864 = param_3.occlusion;\n    _4865 = param_3.emission;\n    _4866 = param_3.clearcoat;\n    _4867 = param_3.clearcoat_roughness;\n    _4868 = param_3.sheen_color;\n    _4869 = param_3.sheen_roughness;\n    _4870 = param_3.anisotropy;\n    _4871 = param_3.anisotropy_rotation;\n    _4872 = param_3.specular;\n    _4873 = param_3.ior;\n    _4874 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4828;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4859 = param_6;\n    _4861 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4859;\n    }\n    else\n    {\n        vec3 _4560 = _4861;\n        vec3 _4561 = normalize(_4560);\n        _4861 = _4561;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _4828, fa_world_tangent, fa_uv, fa_vertex_color, _4514, gl_FrontFacing);\n        Surface param_9 = Surface(_4859, _4860, _4561, _4862, _4863, _4864, _4865, _4866, _4867, _4868, _4869, _4870, _4871, _4872, _4873, _4874);\n        vec3 _4572 = lighting(param_8, param_9);\n        result = _4572;\n    }\n    vec3 _4576 = result;\n    vec3 _4577 = _4576 + _4865;\n    result = _4577;\n    vec3 param_10 = _4577;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _4586 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4593;\n    if (!_4586)\n    {\n        _4593 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4593 = _4586;\n    }\n    if (_4593)\n    {\n        vec3 _4602 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4608 = dot(_4602, fa_mesh_fs_params[9].xyz);\n        bool _4612 = fa_mesh_fs_params[9].w > 0.5;\n        float _4613;\n        if (_4612)\n        {\n            _4613 = _4608;\n        }\n        else\n        {\n            _4613 = length(_4602);\n        }\n        float _4625 = _4613 - fa_mesh_fs_params[8].x;\n        if (_4625 > 0.0)\n        {\n            float _4634 = fa_mesh_fs_params[7].w * _4625;\n            float tau = _4634 * _4634;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4650;\n                if (_4612)\n                {\n                    _4650 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4608);\n                }\n                else\n                {\n                    _4650 = fa_mesh_fs_params[0].y;\n                }\n                float _4671 = mix(_4650, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4613, 0.0, 1.0));\n                float _4675 = fa_world_pos.y - _4671;\n                float _4680 = _4671 - fa_mesh_fs_params[8].z;\n                float _4685 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4688 = _4680 <= 0.0;\n                bool _4689 = !_4688;\n                bool _4695;\n                if (_4689)\n                {\n                    _4695 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4695 = _4688;\n                }\n                float _4696;\n                if (_4695)\n                {\n                    _4696 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4696 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4680, 80.0));\n                }\n                bool _4723;\n                if (_4689)\n                {\n                    _4723 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4723 = _4688;\n                }\n                float _4724;\n                if (_4723)\n                {\n                    _4724 = fa_mesh_fs_params[8].y * _4680;\n                }\n                else\n                {\n                    _4724 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4680, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4749 = _4685 <= 0.0;\n                bool _4756;\n                if (!_4749)\n                {\n                    _4756 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4756 = _4749;\n                }\n                float _4757;\n                if (_4756)\n                {\n                    _4757 = fa_mesh_fs_params[8].y * _4685;\n                }\n                else\n                {\n                    _4757 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4685, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4784;\n                if (abs(_4675) < 0.001000000047497451305389404296875)\n                {\n                    _4784 = _4696;\n                }\n                else\n                {\n                    _4784 = (_4757 - _4724) / _4675;\n                }\n                tau += (_4625 * max(_4784, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4860);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_365",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2073",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_4142",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
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
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
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
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3349[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1344 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1351;\n    if (!_1344)\n    {\n        _1351 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1351 = _1344;\n    }\n    bool _1359;\n    if (!_1351)\n    {\n        _1359 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1359 = _1351;\n    }\n    bool _1366;\n    if (!_1359)\n    {\n        _1366 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1366 = _1359;\n    }\n    bool _1373;\n    if (!_1366)\n    {\n        _1373 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1373 = _1366;\n    }\n    if (_1373)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1383 = vec4(world_pos, 1.0);\n    float _1389 = dot(fa_mesh_fs_params[16], _1383);\n    if (!(_1389 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1411 = vec2(dot(fa_mesh_fs_params[14], _1383), dot(fa_mesh_fs_params[15], _1383)) / vec2(_1389);\n    int _1415 = int(fa_mesh_fs_params[18].x);\n    int _1419 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1419) + clamp(int(floor(((_1411.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1419 - 1)) * _1415)) + clamp(int(floor(((_1411.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1415 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1495 = fa_cluster_texel(param);\n    return ivec2(int(_1495.x), int(_1495.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3891 = fa_cluster_lookup(param);\n    fa_cl_slot = _3891.x;\n    fa_cl_local = _3891.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4203 = fa_linear_to_srgb(param);\n        c = _4203;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4211 = fa_srgb_to_linear(param_1);\n            c = _4211;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _297;\n    if (i.front_facing)\n    {\n        _297 = i.world_normal;\n    }\n    else\n    {\n        _297 = -i.world_normal;\n    }\n    vec3 _321 = normalize(i.world_tangent.xyz - (_297 * dot(_297, i.world_tangent.xyz)));\n    vec3 _349 = normalize(((_321 * m.x) + ((cross(_297, _321) * i.world_tangent.w) * m.y)) + (_297 * m.z));\n    vec3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4242 = fa_tex_fix(param_2, param_3);\n    vec4 _5265 = base_t;\n    _5265.x = _4242.x;\n    _5265.y = _4242.y;\n    _5265.z = _4242.z;\n    base_t = _5265;\n    vec4 _4256 = (_5265 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5117 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4288 = fa_tex_fix(param_6, param_7);\n        vec3 _4291 = (_4288 * 2.0) - vec3(1.0);\n        vec2 _4296 = _4291.xy * fa_mesh_fs_params[6].x;\n        vec3 _5273 = _4291;\n        _5273.x = _4296.x;\n        _5273.y = _4296.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5273;\n        _5117 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4324 = fa_tex_fix(param_12, param_13);\n    vec4 _5276 = mrt;\n    _5276.x = _4324.x;\n    _5276.y = _4324.y;\n    _5276.z = _4324.z;\n    mrt = _5276;\n    vec4 _4352 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4352.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4363 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4393 = fa_tex_fix(param_20, param_21);\n    float _5122 = fa_mesh_fs_params[20].x;\n    float _5123 = fa_mesh_fs_params[20].y;\n    float _5126 = fa_mesh_fs_params[20].z;\n    float _5125 = fa_mesh_fs_params[21].w;\n    float _5128 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5122 *= _4363.y;\n            _5123 *= _4363.z;\n            _5125 *= _4352.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5126 *= mrt.x;\n            _5128 *= mrt.w;\n        }\n    }\n    return Surface(_4256.xyz, _4256.w, _5117, clamp(fa_mesh_fs_params[5].x * _4324.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4324.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4363.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4393), _5122, _5123, fa_mesh_fs_params[21].xyz, _5125, _5126, fa_mesh_fs_params[20].w, _5128, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1575 = rect.zw - rect.xy;\n    vec2 _1579 = _1575 * atlas;\n    vec2 _1583 = ddx * _1579;\n    vec2 _1587 = ddy * _1579;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1575), clamp(0.5 * log2(max(max(dot(_1583, _1583), dot(_1587, _1587)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1620 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1627;\n    if (!_1620)\n    {\n        _1627 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1627 = _1620;\n    }\n    if (_1627)\n    {\n        return;\n    }\n    vec3 _1633 = dFdx(world_pos);\n    vec3 _1636 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1640 = fa_cluster_texel(param);\n    int _1644 = int(_1640.w);\n    if (_1644 < 1)\n    {\n        return;\n    }\n    int _1654 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1654;\n    vec4 _1658 = fa_light_texel(param_1);\n    vec2 _1661 = _1658.yz;\n    int _1665 = int(_1658.w);\n    int param_2 = _1654 + 1;\n    vec4 _1670 = fa_light_texel(param_2);\n    float _1671 = _1670.x;\n    int _1677 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1681 = int(_1640.z);\n    vec3 _1946;\n    for (int k = 0; k < _1644; k++)\n    {\n        int _1694 = _1681 + k;\n        int param_3 = _1665 + (_1694 >> 2);\n        int _1711 = (_1654 + 2) + (int(fa_light_texel(param_3)[_1694 & 3]) * 7);\n        int param_4 = _1711 + 6;\n        vec4 _1716 = fa_light_texel(param_4);\n        if (((int(_1716.w + 0.5) >> _1677) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1711;\n        vec4 _1731 = fa_light_texel(param_5);\n        int param_6 = _1711 + 1;\n        vec4 _1736 = fa_light_texel(param_6);\n        int param_7 = _1711 + 2;\n        vec4 _1741 = fa_light_texel(param_7);\n        vec3 _1744 = _1731.xyz;\n        float _1749 = dot(_1744, world_pos) + _1731.w;\n        vec3 _1751 = _1736.xyz;\n        float _1756 = dot(_1751, world_pos) + _1736.w;\n        vec3 _1758 = _1741.xyz;\n        float _1763 = dot(_1758, world_pos) + _1741.w;\n        bool _1768 = abs(_1749) > 0.5;\n        bool _1776;\n        if (!_1768)\n        {\n            _1776 = abs(_1756) > 0.5;\n        }\n        else\n        {\n            _1776 = _1768;\n        }\n        bool _1784;\n        if (!_1776)\n        {\n            _1784 = abs(_1763) > 0.5;\n        }\n        else\n        {\n            _1784 = _1776;\n        }\n        if (_1784)\n        {\n            continue;\n        }\n        float _1799 = clamp(dot(geo_normal, normalize(_1758)) * _1716.z, 0.0, 1.0);\n        if (_1799 <= 0.0)\n        {\n            continue;\n        }\n        float _1819 = (clamp((0.5 - abs(_1763)) * 10.0, 0.0, 1.0) * _1799) * _1716.x;\n        vec2 _1827 = vec2(_1749 + 0.5, 0.5 - _1756);\n        vec2 _1837 = vec2(dot(_1744, _1633), dot(_1751, _1633));\n        vec2 _1847 = vec2(dot(_1744, _1636), dot(_1751, _1636));\n        int param_8 = _1711 + 5;\n        vec4 _1852 = fa_light_texel(param_8);\n        int param_9 = _1711 + 3;\n        vec4 _1857 = fa_light_texel(param_9);\n        int param_10 = _1711 + 4;\n        vec4 _1862 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1852.xyz;\n        bool _1872 = _1857.z > _1857.x;\n        if (_1872)\n        {\n            vec4 param_11 = _1857;\n            vec2 param_12 = _1827;\n            vec2 param_13 = _1661;\n            vec2 param_14 = _1837;\n            vec2 param_15 = _1847;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1671 > 0.5) && (_1671 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1898 = fa_dc_to_linear(param_16);\n                vec4 _5197 = tx;\n                _5197.x = _1898.x;\n                _5197.y = _1898.y;\n                _5197.z = _1898.z;\n                tx = _5197;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1819 * tex_a) * _1852.w, 0.0, 1.0)));\n        if (_1862.z > _1862.x)\n        {\n            vec4 param_17 = _1862;\n            vec2 param_18 = _1827;\n            vec2 param_19 = _1661;\n            vec2 param_20 = _1837;\n            vec2 param_21 = _1847;\n            vec4 _1942 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1671 > 1.5)\n            {\n                vec3 param_22 = _1942.xyz;\n                vec3 _1952 = fa_dc_to_srgb(param_22);\n                _1946 = _1952;\n            }\n            else\n            {\n                _1946 = _1942.xyz;\n            }\n            vec3 _1961 = (_1946 * 2.0) - vec3(1.0);\n            vec2 _1966 = _1961.xy * _1716.y;\n            vec3 _1988 = (normalize(_1744) * _1966.x) + (normalize(_1751) * _1966.y);\n            vec3 _1991 = normalize(normal);\n            normal = normalize(mix(_1991, normalize((_1991 * max(_1961.z, 0.0500000007450580596923828125)) + (_1988 - (_1991 * dot(_1991, _1988)))), vec3(clamp(_1819 * (_1872 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _593 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _606 = (c - (ru * hx)) - p;\n        vec3 _612 = ru * (2.0 * hx);\n        float _618 = max(dot(_612, _612), 9.9999999392252902907785028219223e-09);\n        float _622 = dot(_606, _612);\n        float t = clamp((-_622) / _618, 0.0, 1.0);\n        if (_593)\n        {\n            float _637 = dot(r, _612);\n            float _643 = _618 - (_637 * _637);\n            if (abs(_643) > (9.9999997473787516355514526367188e-06 * _618))\n            {\n                t = clamp(((dot(r, _606) * _637) - _622) / _643, 0.0, 1.0);\n            }\n        }\n        return (p + _606) + (_612 * t);\n    }\n    vec3 q = p;\n    float _675 = dot(r, axis);\n    bool _683;\n    if (_593)\n    {\n        _683 = abs(_675) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _683 = _593;\n    }\n    if (_683)\n    {\n        float _693 = dot(c - p, axis) / _675;\n        if (_693 > 0.0)\n        {\n            q = p + (r * _693);\n        }\n    }\n    vec3 _706 = q - c;\n    vec2 xy = vec2(dot(_706, ru), dot(_706, uu));\n    if (shape > 0.5)\n    {\n        float _721 = length(xy);\n        if (_721 > hx)\n        {\n            xy *= (hx / _721);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _541;\n        if (_518 >= _514.z)\n        {\n            _541 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _541 = (d.z > 0.0) ? 4 : 5;\n        }\n        _528 = _541;\n    }\n    return _528;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _467 = dot(d, right);\n    float _471 = dot(d, up);\n    float _482;\n    if (((_467 * _467) + (_471 * _471)) > 1.0000000133514319600180897396058e-10)\n    {\n        _482 = atan(_471, _467) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _482 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_482 - floor(_482)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _759 = fa_light_base(param);\n    bool _763 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _759;\n    vec4 _767 = fa_light_texel(param_1);\n    int param_2 = _759 + 1;\n    vec4 _772 = fa_light_texel(param_2);\n    float _775 = _772.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _787 = _763 && (_775 > 2.5);\n    fa_light_is_area = _787;\n    bool _789 = _775 < 0.5;\n    vec3 l;\n    if (_789)\n    {\n        l = normalize(_767.xyz);\n        if (_763)\n        {\n            int param_3 = _759 + 6;\n            vec4 _803 = fa_light_texel(param_3);\n            if (_803.z > 0.5)\n            {\n                int param_4 = _759 + 4;\n                vec4 _813 = fa_light_texel(param_4);\n                int param_5 = _759 + 5;\n                vec4 _818 = fa_light_texel(param_5);\n                vec2 param_6 = _803.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _813.xyz) * _813.w, (-dot(world_pos, _818.xyz)) * _818.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _848 = _767.xyz;\n        vec3 _850 = _848 - world_pos;\n        vec3 to_light = _850;\n        float _853 = length(_850);\n        float reach = _853;\n        bool front = true;\n        if (_787)\n        {\n            int param_8 = _759 + 7;\n            reach = max(_853 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _759 + 4;\n            vec4 _877 = fa_light_texel(param_9);\n            int param_10 = _759 + 5;\n            vec4 _882 = fa_light_texel(param_10);\n            int param_11 = _759 + 6;\n            vec4 _887 = fa_light_texel(param_11);\n            float _888 = _887.w;\n            int param_12 = _759 + 2;\n            vec3 _895 = normalize(fa_light_texel(param_12).xyz);\n            bool _897 = _888 > 1.5;\n            bool _905;\n            if (!_897)\n            {\n                _905 = dot(_895, to_light) < 0.0;\n            }\n            else\n            {\n                _905 = _897;\n            }\n            front = _905;\n            vec3 r = vec3(0.0);\n            vec3 _914 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _918 = dot(n, n) > 0.5;\n            bool _926;\n            if (_918)\n            {\n                _926 = dot(_914, _914) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _926 = _918;\n            }\n            if (_926)\n            {\n                r = reflect(-normalize(_914), normalize(n));\n            }\n            vec3 param_13 = _848;\n            vec3 param_14 = _895;\n            vec3 param_15 = _877.xyz;\n            vec3 param_16 = _882.xyz;\n            float param_17 = _877.w;\n            float param_18 = _882.w;\n            float param_19 = _888;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _962 = length(to_light);\n        dist = _962;\n        l = to_light / vec3(max(_962, 9.9999997473787516355514526367188e-05));\n        float _976 = reach / max(_767.w, 0.001000000047497451305389404296875);\n        float _982 = clamp(1.0 - (_976 * _976), 0.0, 1.0);\n        float _984;\n        if (front)\n        {\n            _984 = _982 * _982;\n        }\n        else\n        {\n            _984 = 0.0;\n        }\n        atten = _984;\n        bool _995 = _775 < 2.5;\n        if ((_775 > 1.5) && _995)\n        {\n            int param_22 = _759 + 2;\n            vec4 _1003 = fa_light_texel(param_22);\n            float _1013 = _1003.w;\n            int param_23 = _759 + 3;\n            vec4 _1018 = fa_light_texel(param_23);\n            float _1019 = _1018.x;\n            float cos_inner = _1019;\n            if (_1019 > 1.5)\n            {\n                cos_inner = mix(_1013, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1013, cos_inner, dot(-l, normalize(_1003.xyz)));\n        }\n        if (_763 && (_775 < 1.5))\n        {\n            int param_24 = _759 + 6;\n            vec4 _1043 = fa_light_texel(param_24);\n            if (_1043.z > 0.5)\n            {\n                vec3 _1051 = -to_light;\n                int param_25 = _759 + 4;\n                int param_26 = _759 + 5;\n                vec3 _1065 = fa_light_texel(param_25).xyz;\n                vec3 _1069 = fa_light_texel(param_26).xyz;\n                vec3 _1078 = vec3(dot(_1051, _1065), dot(_1051, _1069), dot(_1051, cross(_1065, _1069)));\n                vec3 param_27 = _1078;\n                int _1082 = fa_cube_face(param_27);\n                int param_28 = _1082;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1109 = vec2(dot(_1078, cross(param_29, param_30)), dot(_1078, param_30)) / vec2(max(dot(_1078, param_29), 9.9999997473787516355514526367188e-05));\n                int _1113 = _1082 / 3;\n                vec2 param_31 = _1043.xy + (vec2(float(_1082 - (_1113 * 3)), float(_1113)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1109.x), 0.5 - (0.5 * _1109.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _759 + 7;\n            vec4 _1143 = fa_light_texel(param_33);\n            if (_1143.z > 0.5)\n            {\n                int param_34 = _759 + 2;\n                int param_35 = _759 + 4;\n                int param_36 = _759 + 5;\n                vec2 param_37 = _1143.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_763 && _995)\n            {\n                int param_42 = _759 + 6;\n                vec4 _1190 = fa_light_texel(param_42);\n                int param_43 = _759 + 7;\n                vec4 _1195 = fa_light_texel(param_43);\n                bool _1198 = _1190.z > 0.5;\n                bool _1205;\n                if (!_1198)\n                {\n                    _1205 = _1195.z > 0.5;\n                }\n                else\n                {\n                    _1205 = _1198;\n                }\n                if (_1205)\n                {\n                    int param_44 = _759 + 2;\n                    vec4 _1212 = fa_light_texel(param_44);\n                    vec3 _1216 = normalize(_1212.xyz);\n                    int param_45 = _759 + 4;\n                    vec4 _1221 = fa_light_texel(param_45);\n                    int param_46 = _759 + 5;\n                    vec4 _1226 = fa_light_texel(param_46);\n                    if (_1198)\n                    {\n                        vec3 _1234 = -to_light;\n                        float _1241 = _1212.w;\n                        float _1257 = 0.5 / max(dot(_1234, _1216) * (sqrt(max(1.0 - (_1241 * _1241), 0.0)) / max(_1241, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1190.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1234, _1221.xyz) * _1257), 0.5 - (dot(_1234, _1226.xyz) * _1257));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1195.z > 0.5)\n                    {\n                        vec2 param_49 = _1195.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1216;\n                        vec3 param_52 = _1221.xyz;\n                        vec3 param_53 = _1226.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4942 = _772.xyz * atten;\n    if (_763)\n    {\n        _4942 *= fa_light_tint;\n    }\n    int _1326;\n    if (_789)\n    {\n        _1326 = 0;\n    }\n    else\n    {\n        _1326 = ((_775 > 1.5) && (_775 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4942, atten, 1.0, dist, _1326);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4034 = n < 0;\n    bool _4041;\n    if (!_4034)\n    {\n        _4041 = n >= fa_light_count();\n    }\n    else\n    {\n        _4041 = _4034;\n    }\n    if (_4041)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4049 = fa_cl_light(param);\n    bool _4052 = fa_lm.z > 0.5;\n    bool _4058;\n    if (_4052)\n    {\n        int param_1 = _4049;\n        _4058 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _4058 = _4052;\n    }\n    if (_4058)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4049;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _4071 = fa_light_sample_n(param_2, param_3, param_4);\n    return _4071;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2063;\n    if (i == 0)\n    {\n        _2063 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2079;\n        if (i == 1)\n        {\n            _2079 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2087;\n            if (i == 2)\n            {\n                _2087 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2087 = fa_shadows[24].w;\n            }\n            _2079 = _2087;\n        }\n        _2063 = _2079;\n    }\n    return _2063;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2120 = fa_shadow_depth(param, param_1);\n    float _2124;\n    if (conv.x < 0.5)\n    {\n        _2124 = _2120;\n    }\n    else\n    {\n        _2124 = (conv.y * conv.z) / (conv.z - (_2120 * (conv.z - conv.y)));\n    }\n    return _2124;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2051 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2051), sin(_2051)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2170 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2179;\n        if (k < 0.0)\n        {\n            _2179 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2179 = k;\n        }\n        float _2199 = clamp((_2179 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2170;\n            vec2 _2218 = fa_shadow_vogel(param_3, param_4, param_5) * _2199;\n            vec2 param_6 = uv + (_2218 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2230 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2230 < (zr - (length(_2218) * plane)))\n            {\n                sum += _2230;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2256 = sum / cnt;\n        float _2266;\n        if (k < 0.0)\n        {\n            _2266 = (-k) / max(_2256, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2266 = k;\n        }\n        radius = clamp(((max(zr - _2256, 0.0) * unit) * _2266) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2288 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2288; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2288;\n        float param_11 = _2170;\n        vec2 _2307 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2307 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2307) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2288);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2349 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2354 = clamp(dot(n, l), 0.0, 1.0);\n    float _2360 = sqrt(1.0 - (_2354 * _2354));\n    float _2367 = min(_2360 / max(_2354, 0.20000000298023223876953125), 4.0);\n    float _2372;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2372 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2372 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2397 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2372 * _2360)), 1.0);\n    float _2404 = _2397.x;\n    bool _2407 = _2404 < fa_shadows[ci * 1 + 16].x;\n    bool _2416;\n    if (!_2407)\n    {\n        _2416 = _2404 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2416 = _2407;\n    }\n    bool _2425;\n    if (!_2416)\n    {\n        _2425 = _2397.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2425 = _2416;\n    }\n    bool _2434;\n    if (!_2425)\n    {\n        _2434 = _2397.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2434 = _2425;\n    }\n    bool _2441;\n    if (!_2434)\n    {\n        _2441 = _2397.z > 1.0;\n    }\n    else\n    {\n        _2441 = _2434;\n    }\n    if (_2441)\n    {\n        return -1.0;\n    }\n    float _2449;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2449 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2449 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2397.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2397.z - ((_2449 * (1.0 + (0.5 * _2367))) / _2349);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2349;\n    float param_5 = _2349 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2367, 3.0)) * 0.5) / _2349;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2837 = int(fa_shadows[25].x + 0.5);\n    if (_2837 < 1)\n    {\n        return 1.0;\n    }\n    float _2852 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2837 - 1;\n    if (_2852 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2864 = _2837 > 1;\n    bool _2871;\n    if (_2864)\n    {\n        _2871 = _2852 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2871 = _2864;\n    }\n    if (_2871)\n    {\n        ci = 1;\n    }\n    bool _2875 = _2837 > 2;\n    bool _2882;\n    if (_2875)\n    {\n        _2882 = _2852 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2882 = _2875;\n    }\n    if (_2882)\n    {\n        ci = 2;\n    }\n    bool _2886 = _2837 > 3;\n    bool _2893;\n    if (_2886)\n    {\n        _2893 = _2852 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2893 = _2886;\n    }\n    if (_2893)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2837)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2919 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2919;\n        if (_2919 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2944;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2944 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2944 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2963 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2944, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2974 = clamp((_2852 - (fa_shadow_split_at(param_7) - _2963)) / _2963, 0.0, 1.0);\n        if (_2974 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2837)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2995 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2995;\n                if (_2995 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2974);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _2507 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2514;\n    if (!_2507)\n    {\n        _2514 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2514 = _2507;\n    }\n    if (_2514)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2527 = fa_light_texel(param);\n    float _2528 = _2527.x;\n    if (_2528 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2537 = int(_2528 + 0.5);\n    int param_1 = _2537;\n    vec4 _2541 = fa_light_texel(param_1);\n    int param_2 = _2537 + 1;\n    vec4 _2546 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2549 = _2541.y;\n    if (_2549 > 0.0)\n    {\n        float _2566 = 1.0 - smoothstep(0.75 * _2549, _2549, length(world - fa_shadows[27].xyz));\n        fade = _2566;\n        if (_2566 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2541.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        vec3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2595 = (_2537 + 2) + (face * 6);\n    int param_6 = _2595;\n    int param_7 = _2595 + 1;\n    int param_8 = _2595 + 3;\n    vec4 _2609 = fa_light_texel(param_8);\n    int param_9 = _2595 + 4;\n    vec4 _2614 = fa_light_texel(param_9);\n    int param_10 = _2595 + 5;\n    vec4 _2619 = fa_light_texel(param_10);\n    float _2631 = _2619.x * max(dot(_2609, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2636 = clamp(dot(n, l), 0.0, 1.0);\n    float _2659 = clamp(dot(n, _2609.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2683 = min(sqrt(1.0 - (_2659 * _2659)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2609, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2686 = _2546.y;\n    float _2688;\n    if (_2686 > 0.0)\n    {\n        _2688 = _2686;\n    }\n    else\n    {\n        _2688 = 1.5 * _2631;\n    }\n    vec4 _2708 = vec4(world + (n * (_2688 * sqrt(1.0 - (_2636 * _2636)))), 1.0);\n    float _2712 = dot(_2609, _2708);\n    float _2715 = _2619.y;\n    if (_2712 < _2715)\n    {\n        return 1.0;\n    }\n    vec2 _2730 = vec2(dot(fa_light_texel(param_6), _2708), dot(fa_light_texel(param_7), _2708)) / vec2(_2712);\n    float _2732 = _2730.x;\n    bool _2735 = _2732 < _2614.x;\n    bool _2744;\n    if (!_2735)\n    {\n        _2744 = _2732 > _2614.z;\n    }\n    else\n    {\n        _2744 = _2735;\n    }\n    bool _2753;\n    if (!_2744)\n    {\n        _2753 = _2730.y < _2614.y;\n    }\n    else\n    {\n        _2753 = _2744;\n    }\n    bool _2762;\n    if (!_2753)\n    {\n        _2762 = _2730.y > _2614.w;\n    }\n    else\n    {\n        _2762 = _2753;\n    }\n    if (_2762)\n    {\n        return 1.0;\n    }\n    float _2768 = _2546.x;\n    float _2770;\n    if (_2768 > 0.0)\n    {\n        _2770 = _2768;\n    }\n    else\n    {\n        _2770 = 1.5 * _2631;\n    }\n    vec2 param_13 = _2730;\n    vec4 param_14 = _2614;\n    float param_15 = _2712 - (_2770 * (1.0 + (0.5 * _2683)));\n    float param_16 = _2631;\n    float param_17 = 1.0;\n    float param_18 = _2619.z * 0.25;\n    float param_19 = (_2631 * min(_2683, 3.0)) * 0.5;\n    vec3 param_20 = vec3(1.0, _2715, _2619.z);\n    int param_21 = int(_2541.z + 0.5);\n    float param_22 = _2541.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3918 = fa_lm.z > 0.5;\n    bool _3924;\n    if (_3918)\n    {\n        int param = li;\n        _3924 = fa_light_baked(param);\n    }\n    else\n    {\n        _3924 = _3918;\n    }\n    if (_3924)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3948 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5088 = _3948.color;\n    float _5090 = _3948.shadow;\n    if ((_3948.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3948.direction;\n        float _3962 = fa_shadow_factor(param_5, param_6);\n        _5090 = _3962;\n        _5088 *= _3962;\n    }\n    else\n    {\n        bool _3973 = _3948.type != 0;\n        bool _3979;\n        if (_3973)\n        {\n            _3979 = _3948.attenuation > 0.0;\n        }\n        else\n        {\n            _3979 = _3973;\n        }\n        if (_3979)\n        {\n            int param_7 = li;\n            vec3 param_8 = world_pos;\n            vec3 param_9 = gn;\n            vec3 param_10 = _3948.direction;\n            float _3991 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _5090 = _3991;\n            _5088 *= _3991;\n        }\n    }\n    return LightSample(_3948.direction, _5088, _3948.attenuation, _5090, _3948._distance, _3948.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4008 = n < 0;\n    bool _4015;\n    if (!_4008)\n    {\n        _4015 = n >= fa_light_count();\n    }\n    else\n    {\n        _4015 = _4008;\n    }\n    if (_4015)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _4030 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4030;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3274 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3282 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3285 = int(_3274);\n    int _3288 = int(_3282);\n    float _3298 = _3282 - float(_3288);\n    int _3354 = (_3285 * 9) + _3288;\n    int _3374 = ((_3285 + 1) * 9) + _3288;\n    return mix(mix(_3349[_3354], _3349[_3354 + 1], _3298), mix(_3349[_3374], _3349[_3374 + 1], _3298), _3274 - float(_3285));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4954 = false;\n    float _4955 = 1.0;\n    float _4956 = 1.0;\n    float _4957 = 1.0;\n    float _4958 = 0.0;\n    float _4959 = 0.0;\n    float _4960 = 0.0;\n    float _4961 = 0.0;\n    float _4963 = 1.0;\n    bool _4964 = false;\n    vec3 _4965 = vec3(0.0);\n    float _4966 = 1.0;\n    float _4967 = 1.0;\n    float _4968 = 1.0;\n    float _4969 = 0.0;\n    float _4970 = 0.0;\n    vec3 _4971 = vec3(1.0, 0.0, 0.0);\n    vec3 _4972 = vec3(0.0, 0.0, 1.0);\n    float _4973 = 1.0;\n    float _4974 = 1.0;\n    float _3425 = clamp(s.specular, 0.0, 1.0);\n    float _3429 = clamp(s.ior, 1.0, 3.0);\n    bool _3434 = (_3425 != 1.0) || (_3429 != 1.5);\n    bool _3443;\n    if (!_3434)\n    {\n        _3443 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3443 = _3434;\n    }\n    if (_3443)\n    {\n        float _3451 = (_3429 - 1.0) / (_3429 + 1.0);\n        f0 = mix(min(vec3(_3451 * _3451) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3425, s.albedo, vec3(metallic));\n        _4955 = mix(_3425, 1.0, metallic);\n        _4954 = true;\n    }\n    float _3478 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3478 > 0.0)\n    {\n        float _3486 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4958 = _3478;\n        _4959 = _3486;\n        float _3493 = _3486 * _3486;\n        _4960 = _3493;\n        _4961 = _3493 * _3493;\n        float _3505 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4963 = _3505;\n        _4956 = 1.0 - (_3478 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3505, 0.0, 1.0), 5.0))));\n        _4954 = true;\n    }\n    vec3 _3525 = max(s.sheen_color, vec3(0.0));\n    float _3534 = max(_3525.x, max(_3525.y, _3525.z));\n    if (_3534 > 0.0)\n    {\n        float _3542 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4964 = true;\n        _4965 = _3525;\n        _4966 = _3542;\n        _4967 = _3542 * _3542;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3542;\n        float _3559 = fa_sheen_albedo(param, param_1);\n        _4969 = _3559;\n        _4968 = 1.0 - min(_3534 * _3559, 1.0);\n        _4954 = true;\n    }\n    _4957 = _4956 * _4968;\n    float _3578 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3578 != 0.0)\n    {\n        vec3 _3593 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3593;\n        if (dot(_3593, _3593) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3605 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3605.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3605.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3605.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3609 = t;\n        vec3 _3610 = normalize(_3609);\n        t = _3610;\n        vec3 _3635 = normalize((_3610 * cos(s.anisotropy_rotation)) + ((cross(n, _3610) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4971 = _3635;\n        _4972 = cross(n, _3635);\n        float _3645 = roughness * roughness;\n        float _3651 = mix(_3645, 1.0, _3578 * _3578);\n        bool _3653 = _3578 > 0.0;\n        _4973 = _3653 ? _3651 : _3645;\n        _4974 = _3653 ? _3645 : _3651;\n        _4970 = _3578;\n        _4954 = true;\n    }\n    return FaLayers(_4954, _4955, _4956, _4957, _4958, _4959, _4960, _4961, i.world_normal, _4963, _4964, _4965, _4966, _4967, _4968, _4969, _4970, _4971, _4972, _4973, _4974);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3206 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3209 = _3206.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3209 * _3209, exp2((-9.27999973297119140625) * ndv)) * _3209) + _3206.y)) + _3206.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3130 = rough * rough;\n    float _3160 = 0.60000002384185791015625 * _3130;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3130)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3160, 0.0500000007450580596923828125 + _3160, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3130 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3686;\n        if (L.aniso >= 0.0)\n        {\n            _3686 = L.b;\n        }\n        else\n        {\n            _3686 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3686, v), _3686), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3719 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3719.x) + (vec3(L.f90) * _3719.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3774 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3774.x) + _3774.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3248 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3248.x) + vec3(_3248.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3813 = clamp(s.metallic, 0.0, 1.0);\n    float _3817 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _3824 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_3813));\n    vec3 f0 = _3824;\n    vec3 _3828 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _3828;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _3813;\n    float param_5 = _3817;\n    vec3 param_6 = _3824;\n    FaLayers _3845 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3845.on)\n    {\n        FaLayers param_7 = _3845;\n        vec3 param_8 = _3828;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _3817;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _3828;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _3817;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4091 = fa_light_unshadowed(param, param_1);\n        float _4099 = dot(_4091.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_4099 > bestPower)\n        {\n            bestPower = _4099;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4128 = fa_light(param_2, param_3);\n        float _4136;\n        if (dot(s.normal, _4128.direction) > 0.5)\n        {\n            _4136 = 1.0;\n        }\n        else\n        {\n            _4136 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _4128.color) * _4136);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3019 = int(fa_shadows[25].x + 0.5);\n    float _3029 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3034 = _3019 > 0;\n    bool _3043;\n    if (_3034)\n    {\n        int param = _3019 - 1;\n        _3043 = _3029 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3043 = _3034;\n    }\n    if (_3043)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3049 = _3019 > 1;\n        bool _3056;\n        if (_3049)\n        {\n            _3056 = _3029 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3056 = _3049;\n        }\n        if (_3056)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3062 = _3019 > 2;\n        bool _3069;\n        if (_3062)\n        {\n            _3069 = _3029 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3069 = _3062;\n        }\n        if (_3069)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3075 = _3019 > 3;\n        bool _3082;\n        if (_3075)\n        {\n            _3082 = _3029 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3082 = _3075;\n        }\n        if (_3082)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4828 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4828 = -_4828;\n    }\n    vec3 _4514 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4828, fa_world_tangent, fa_uv, fa_vertex_color, _4514, gl_FrontFacing);\n    Surface _4522 = fa_standard_surface(param_1);\n    vec3 _4859 = _4522.albedo;\n    float _4860 = _4522.alpha;\n    vec3 _4861 = _4522.normal;\n    float _4862 = _4522.metallic;\n    float _4863 = _4522.roughness;\n    float _4864 = _4522.occlusion;\n    vec3 _4865 = _4522.emission;\n    float _4866 = _4522.clearcoat;\n    float _4867 = _4522.clearcoat_roughness;\n    vec3 _4868 = _4522.sheen_color;\n    float _4869 = _4522.sheen_roughness;\n    float _4870 = _4522.anisotropy;\n    float _4871 = _4522.anisotropy_rotation;\n    float _4872 = _4522.specular;\n    float _4873 = _4522.ior;\n    vec3 _4874 = _4522.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4828, fa_world_tangent, fa_uv, fa_vertex_color, _4514, gl_FrontFacing);\n    Surface param_3 = _4522;\n    surface(param_2, param_3);\n    _4859 = param_3.albedo;\n    _4860 = param_3.alpha;\n    _4861 = param_3.normal;\n    _4862 = param_3.metallic;\n    _4863 = param_3.roughness;\n    _4864 = param_3.occlusion;\n    _4865 = param_3.emission;\n    _4866 = param_3.clearcoat;\n    _4867 = param_3.clearcoat_roughness;\n    _4868 = param_3.sheen_color;\n    _4869 = param_3.sheen_roughness;\n    _4870 = param_3.anisotropy;\n    _4871 = param_3.anisotropy_rotation;\n    _4872 = param_3.specular;\n    _4873 = param_3.ior;\n    _4874 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4828;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4859 = param_6;\n    _4861 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4859;\n    }\n    else\n    {\n        vec3 _4560 = _4861;\n        vec3 _4561 = normalize(_4560);\n        _4861 = _4561;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _4828, fa_world_tangent, fa_uv, fa_vertex_color, _4514, gl_FrontFacing);\n        Surface param_9 = Surface(_4859, _4860, _4561, _4862, _4863, _4864, _4865, _4866, _4867, _4868, _4869, _4870, _4871, _4872, _4873, _4874);\n        vec3 _4572 = lighting(param_8, param_9);\n        result = _4572;\n    }\n    vec3 _4576 = result;\n    vec3 _4577 = _4576 + _4865;\n    result = _4577;\n    vec3 param_10 = _4577;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _4586 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4593;\n    if (!_4586)\n    {\n        _4593 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4593 = _4586;\n    }\n    if (_4593)\n    {\n        vec3 _4602 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4608 = dot(_4602, fa_mesh_fs_params[9].xyz);\n        bool _4612 = fa_mesh_fs_params[9].w > 0.5;\n        float _4613;\n        if (_4612)\n        {\n            _4613 = _4608;\n        }\n        else\n        {\n            _4613 = length(_4602);\n        }\n        float _4625 = _4613 - fa_mesh_fs_params[8].x;\n        if (_4625 > 0.0)\n        {\n            float _4634 = fa_mesh_fs_params[7].w * _4625;\n            float tau = _4634 * _4634;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4650;\n                if (_4612)\n                {\n                    _4650 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4608);\n                }\n                else\n                {\n                    _4650 = fa_mesh_fs_params[0].y;\n                }\n                float _4671 = mix(_4650, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4613, 0.0, 1.0));\n                float _4675 = fa_world_pos.y - _4671;\n                float _4680 = _4671 - fa_mesh_fs_params[8].z;\n                float _4685 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4688 = _4680 <= 0.0;\n                bool _4689 = !_4688;\n                bool _4695;\n                if (_4689)\n                {\n                    _4695 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4695 = _4688;\n                }\n                float _4696;\n                if (_4695)\n                {\n                    _4696 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4696 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4680, 80.0));\n                }\n                bool _4723;\n                if (_4689)\n                {\n                    _4723 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4723 = _4688;\n                }\n                float _4724;\n                if (_4723)\n                {\n                    _4724 = fa_mesh_fs_params[8].y * _4680;\n                }\n                else\n                {\n                    _4724 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4680, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4749 = _4685 <= 0.0;\n                bool _4756;\n                if (!_4749)\n                {\n                    _4756 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4756 = _4749;\n                }\n                float _4757;\n                if (_4756)\n                {\n                    _4757 = fa_mesh_fs_params[8].y * _4685;\n                }\n                else\n                {\n                    _4757 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4685, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4784;\n                if (abs(_4675) < 0.001000000047497451305389404296875)\n                {\n                    _4784 = _4696;\n                }\n                else\n                {\n                    _4784 = (_4757 - _4724) / _4675;\n                }\n                tau += (_4625 * max(_4784, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4860);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_365",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2073",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_4142",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
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
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
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
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _788 = base_t;\n    _788.x = _225.x;\n    _788.y = _225.y;\n    _788.z = _225.z;\n    base_t = _788;\n    vec4 _241 = (_788 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _751 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _796 = _279;\n        _796.x = _284.x;\n        _796.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _796;\n        _751 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _799 = mrt;\n    _799.x = _313.x;\n    _799.y = _313.y;\n    _799.z = _313.z;\n    mrt = _799;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _756 = fa_mesh_fs_params[20].x;\n    float _757 = fa_mesh_fs_params[20].y;\n    float _760 = fa_mesh_fs_params[20].z;\n    float _759 = fa_mesh_fs_params[21].w;\n    float _762 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _756 *= _355.y;\n            _757 *= _355.z;\n            _759 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _760 *= mrt.x;\n            _762 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _751, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _756, _757, fa_mesh_fs_params[21].xyz, _759, _760, fa_mesh_fs_params[20].w, _762, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _662 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _662 = -_662;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
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
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
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
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _423 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _788 = base_t;\n    _788.x = _225.x;\n    _788.y = _225.y;\n    _788.z = _225.z;\n    base_t = _788;\n    vec4 _241 = (_788 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _751 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _796 = _279;\n        _796.x = _284.x;\n        _796.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _796;\n        _751 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _799 = mrt;\n    _799.x = _313.x;\n    _799.y = _313.y;\n    _799.z = _313.z;\n    mrt = _799;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _756 = fa_mesh_fs_params[20].x;\n    float _757 = fa_mesh_fs_params[20].y;\n    float _760 = fa_mesh_fs_params[20].z;\n    float _759 = fa_mesh_fs_params[21].w;\n    float _762 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _756 *= _355.y;\n            _757 *= _355.z;\n            _759 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _760 *= mrt.x;\n            _762 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _751, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _756, _757, fa_mesh_fs_params[21].xyz, _759, _760, fa_mesh_fs_params[20].w, _762, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _662 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _662 = -_662;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
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
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
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
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    }
  }
}
