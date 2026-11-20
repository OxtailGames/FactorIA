{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "57cbd5df71b0000e548dcd5fbfe873bc15510a64a336f6248792368f21adbf33",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3872[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[50];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1398 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1405;\n    if (!_1398)\n    {\n        _1405 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1405 = _1398;\n    }\n    bool _1413;\n    if (!_1405)\n    {\n        _1413 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1413 = _1405;\n    }\n    bool _1420;\n    if (!_1413)\n    {\n        _1420 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1420 = _1413;\n    }\n    bool _1427;\n    if (!_1420)\n    {\n        _1427 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1427 = _1420;\n    }\n    if (_1427)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1437 = vec4(world_pos, 1.0);\n    float _1443 = dot(fa_mesh_fs_params[16], _1437);\n    if (!(_1443 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1465 = vec2(dot(fa_mesh_fs_params[14], _1437), dot(fa_mesh_fs_params[15], _1437)) / vec2(_1443);\n    int _1469 = int(fa_mesh_fs_params[18].x);\n    int _1473 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1473) + clamp(int(floor(((_1465.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1473 - 1)) * _1469)) + clamp(int(floor(((_1465.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1469 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1549 = fa_cluster_texel(param);\n    return ivec2(int(_1549.x), int(_1549.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4692 = fa_cluster_lookup(param);\n    fa_cl_slot = _4692.x;\n    fa_cl_local = _4692.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5069 = fa_linear_to_srgb(param);\n        c = _5069;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5077 = fa_srgb_to_linear(param_1);\n            c = _5077;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _349;\n    if (i.front_facing)\n    {\n        _349 = i.world_normal;\n    }\n    else\n    {\n        _349 = -i.world_normal;\n    }\n    vec3 _373 = normalize(i.world_tangent.xyz - (_349 * dot(_349, i.world_tangent.xyz)));\n    vec3 _401 = normalize(((_373 * m.x) + ((cross(_349, _373) * i.world_tangent.w) * m.y)) + (_349 * m.z));\n    vec3 _404;\n    if (i.front_facing)\n    {\n        _404 = _401;\n    }\n    else\n    {\n        _404 = -_401;\n    }\n    return _404;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5108 = fa_tex_fix(param_2, param_3);\n    vec4 _6187 = base_t;\n    _6187.x = _5108.x;\n    _6187.y = _5108.y;\n    _6187.z = _5108.z;\n    base_t = _6187;\n    vec4 _5122 = (_6187 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6001 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5154 = fa_tex_fix(param_6, param_7);\n        vec3 _5157 = (_5154 * 2.0) - vec3(1.0);\n        vec2 _5162 = _5157.xy * fa_mesh_fs_params[6].x;\n        vec3 _6195 = _5157;\n        _6195.x = _5162.x;\n        _6195.y = _5162.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6195;\n        _6001 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5190 = fa_tex_fix(param_12, param_13);\n    vec4 _6198 = mrt;\n    _6198.x = _5190.x;\n    _6198.y = _5190.y;\n    _6198.z = _5190.z;\n    mrt = _6198;\n    vec4 _5218 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5218.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5229 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5259 = fa_tex_fix(param_20, param_21);\n    float _6006 = fa_mesh_fs_params[20].x;\n    float _6007 = fa_mesh_fs_params[20].y;\n    float _6010 = fa_mesh_fs_params[20].z;\n    float _6009 = fa_mesh_fs_params[21].w;\n    float _6012 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6006 *= _5229.y;\n            _6007 *= _5229.z;\n            _6009 *= _5218.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6010 *= mrt.x;\n            _6012 *= mrt.w;\n        }\n    }\n    return Surface(_5122.xyz, _5122.w, _6001, clamp(fa_mesh_fs_params[5].x * _5190.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5190.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5229.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5259), _6006, _6007, fa_mesh_fs_params[21].xyz, _6009, _6010, fa_mesh_fs_params[20].w, _6012, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1629 = rect.zw - rect.xy;\n    vec2 _1633 = _1629 * atlas;\n    vec2 _1637 = ddx * _1633;\n    vec2 _1641 = ddy * _1633;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1629), clamp(0.5 * log2(max(max(dot(_1637, _1637), dot(_1641, _1641)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1674 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1681;\n    if (!_1674)\n    {\n        _1681 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1681 = _1674;\n    }\n    if (_1681)\n    {\n        return;\n    }\n    vec3 _1687 = dFdx(world_pos);\n    vec3 _1690 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1694 = fa_cluster_texel(param);\n    int _1698 = int(_1694.w);\n    if (_1698 < 1)\n    {\n        return;\n    }\n    int _1708 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1708;\n    vec4 _1712 = fa_light_texel(param_1);\n    vec2 _1715 = _1712.yz;\n    int _1719 = int(_1712.w);\n    int param_2 = _1708 + 1;\n    vec4 _1724 = fa_light_texel(param_2);\n    float _1725 = _1724.x;\n    int _1731 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1735 = int(_1694.z);\n    vec3 _2000;\n    for (int k = 0; k < _1698; k++)\n    {\n        int _1748 = _1735 + k;\n        int param_3 = _1719 + (_1748 >> 2);\n        int _1765 = (_1708 + 2) + (int(fa_light_texel(param_3)[_1748 & 3]) * 7);\n        int param_4 = _1765 + 6;\n        vec4 _1770 = fa_light_texel(param_4);\n        if (((int(_1770.w + 0.5) >> _1731) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1765;\n        vec4 _1785 = fa_light_texel(param_5);\n        int param_6 = _1765 + 1;\n        vec4 _1790 = fa_light_texel(param_6);\n        int param_7 = _1765 + 2;\n        vec4 _1795 = fa_light_texel(param_7);\n        vec3 _1798 = _1785.xyz;\n        float _1803 = dot(_1798, world_pos) + _1785.w;\n        vec3 _1805 = _1790.xyz;\n        float _1810 = dot(_1805, world_pos) + _1790.w;\n        vec3 _1812 = _1795.xyz;\n        float _1817 = dot(_1812, world_pos) + _1795.w;\n        bool _1822 = abs(_1803) > 0.5;\n        bool _1830;\n        if (!_1822)\n        {\n            _1830 = abs(_1810) > 0.5;\n        }\n        else\n        {\n            _1830 = _1822;\n        }\n        bool _1838;\n        if (!_1830)\n        {\n            _1838 = abs(_1817) > 0.5;\n        }\n        else\n        {\n            _1838 = _1830;\n        }\n        if (_1838)\n        {\n            continue;\n        }\n        float _1853 = clamp(dot(geo_normal, normalize(_1812)) * _1770.z, 0.0, 1.0);\n        if (_1853 <= 0.0)\n        {\n            continue;\n        }\n        float _1873 = (clamp((0.5 - abs(_1817)) * 10.0, 0.0, 1.0) * _1853) * _1770.x;\n        vec2 _1881 = vec2(_1803 + 0.5, 0.5 - _1810);\n        vec2 _1891 = vec2(dot(_1798, _1687), dot(_1805, _1687));\n        vec2 _1901 = vec2(dot(_1798, _1690), dot(_1805, _1690));\n        int param_8 = _1765 + 5;\n        vec4 _1906 = fa_light_texel(param_8);\n        int param_9 = _1765 + 3;\n        vec4 _1911 = fa_light_texel(param_9);\n        int param_10 = _1765 + 4;\n        vec4 _1916 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1906.xyz;\n        bool _1926 = _1911.z > _1911.x;\n        if (_1926)\n        {\n            vec4 param_11 = _1911;\n            vec2 param_12 = _1881;\n            vec2 param_13 = _1715;\n            vec2 param_14 = _1891;\n            vec2 param_15 = _1901;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1725 > 0.5) && (_1725 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1952 = fa_dc_to_linear(param_16);\n                vec4 _6081 = tx;\n                _6081.x = _1952.x;\n                _6081.y = _1952.y;\n                _6081.z = _1952.z;\n                tx = _6081;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1873 * tex_a) * _1906.w, 0.0, 1.0)));\n        if (_1916.z > _1916.x)\n        {\n            vec4 param_17 = _1916;\n            vec2 param_18 = _1881;\n            vec2 param_19 = _1715;\n            vec2 param_20 = _1891;\n            vec2 param_21 = _1901;\n            vec4 _1996 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1725 > 1.5)\n            {\n                vec3 param_22 = _1996.xyz;\n                vec3 _2006 = fa_dc_to_srgb(param_22);\n                _2000 = _2006;\n            }\n            else\n            {\n                _2000 = _1996.xyz;\n            }\n            vec3 _2015 = (_2000 * 2.0) - vec3(1.0);\n            vec2 _2020 = _2015.xy * _1770.y;\n            vec3 _2042 = (normalize(_1798) * _2020.x) + (normalize(_1805) * _2020.y);\n            vec3 _2045 = normalize(normal);\n            normal = normalize(mix(_2045, normalize((_2045 * max(_2015.z, 0.0500000007450580596923828125)) + (_2042 - (_2045 * dot(_2045, _2042)))), vec3(clamp(_1873 * (_1926 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4662;\n    if (fa_lm.z > 0.5)\n    {\n        _4662 = 0.0;\n    }\n    else\n    {\n        _4662 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _4673 = _4662 < 1.0;\n    bool _4679;\n    if (_4673)\n    {\n        int param = li;\n        _4679 = fa_light_baked(param);\n    }\n    else\n    {\n        _4679 = _4673;\n    }\n    return _4679 ? _4662 : 1.0;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _647 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _660 = (c - (ru * hx)) - p;\n        vec3 _666 = ru * (2.0 * hx);\n        float _672 = max(dot(_666, _666), 9.9999999392252902907785028219223e-09);\n        float _676 = dot(_660, _666);\n        float t = clamp((-_676) / _672, 0.0, 1.0);\n        if (_647)\n        {\n            float _691 = dot(r, _666);\n            float _697 = _672 - (_691 * _691);\n            if (abs(_697) > (9.9999997473787516355514526367188e-06 * _672))\n            {\n                t = clamp(((dot(r, _660) * _691) - _676) / _697, 0.0, 1.0);\n            }\n        }\n        return (p + _660) + (_666 * t);\n    }\n    vec3 q = p;\n    float _729 = dot(r, axis);\n    bool _737;\n    if (_647)\n    {\n        _737 = abs(_729) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _737 = _647;\n    }\n    if (_737)\n    {\n        float _747 = dot(c - p, axis) / _729;\n        if (_747 > 0.0)\n        {\n            q = p + (r * _747);\n        }\n    }\n    vec3 _760 = q - c;\n    vec2 xy = vec2(dot(_760, ru), dot(_760, uu));\n    if (shape > 0.5)\n    {\n        float _775 = length(xy);\n        if (_775 > hx)\n        {\n            xy *= (hx / _775);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _416 = abs(d);\n    float _418 = _416.x;\n    float _420 = _416.y;\n    bool _421 = _418 >= _420;\n    bool _429;\n    if (_421)\n    {\n        _429 = _418 >= _416.z;\n    }\n    else\n    {\n        _429 = _421;\n    }\n    int _430;\n    if (_429)\n    {\n        _430 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _445;\n        if (_420 >= _416.z)\n        {\n            _445 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _445 = (d.z > 0.0) ? 4 : 5;\n        }\n        _430 = _445;\n    }\n    return _430;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _567 = dot(d, right);\n    float _571 = dot(d, up);\n    float _582;\n    if (((_567 * _567) + (_571 * _571)) > 1.0000000133514319600180897396058e-10)\n    {\n        _582 = atan(_571, _567) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _582 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_582 - floor(_582)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _813 = fa_light_base(param);\n    bool _817 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _813;\n    vec4 _821 = fa_light_texel(param_1);\n    int param_2 = _813 + 1;\n    vec4 _826 = fa_light_texel(param_2);\n    float _829 = _826.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _841 = _817 && (_829 > 2.5);\n    fa_light_is_area = _841;\n    bool _843 = _829 < 0.5;\n    vec3 l;\n    if (_843)\n    {\n        l = normalize(_821.xyz);\n        if (_817)\n        {\n            int param_3 = _813 + 6;\n            vec4 _857 = fa_light_texel(param_3);\n            if (_857.z > 0.5)\n            {\n                int param_4 = _813 + 4;\n                vec4 _867 = fa_light_texel(param_4);\n                int param_5 = _813 + 5;\n                vec4 _872 = fa_light_texel(param_5);\n                vec2 param_6 = _857.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _867.xyz) * _867.w, (-dot(world_pos, _872.xyz)) * _872.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _902 = _821.xyz;\n        vec3 _904 = _902 - world_pos;\n        vec3 to_light = _904;\n        float _907 = length(_904);\n        float reach = _907;\n        bool front = true;\n        if (_841)\n        {\n            int param_8 = _813 + 7;\n            reach = max(_907 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _813 + 4;\n            vec4 _931 = fa_light_texel(param_9);\n            int param_10 = _813 + 5;\n            vec4 _936 = fa_light_texel(param_10);\n            int param_11 = _813 + 6;\n            vec4 _941 = fa_light_texel(param_11);\n            float _942 = _941.w;\n            int param_12 = _813 + 2;\n            vec3 _949 = normalize(fa_light_texel(param_12).xyz);\n            bool _951 = _942 > 1.5;\n            bool _959;\n            if (!_951)\n            {\n                _959 = dot(_949, to_light) < 0.0;\n            }\n            else\n            {\n                _959 = _951;\n            }\n            front = _959;\n            vec3 r = vec3(0.0);\n            vec3 _968 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _972 = dot(n, n) > 0.5;\n            bool _980;\n            if (_972)\n            {\n                _980 = dot(_968, _968) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _980 = _972;\n            }\n            if (_980)\n            {\n                r = reflect(-normalize(_968), normalize(n));\n            }\n            vec3 param_13 = _902;\n            vec3 param_14 = _949;\n            vec3 param_15 = _931.xyz;\n            vec3 param_16 = _936.xyz;\n            float param_17 = _931.w;\n            float param_18 = _936.w;\n            float param_19 = _942;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1016 = length(to_light);\n        dist = _1016;\n        l = to_light / vec3(max(_1016, 9.9999997473787516355514526367188e-05));\n        float _1030 = reach / max(_821.w, 0.001000000047497451305389404296875);\n        float _1036 = clamp(1.0 - (_1030 * _1030), 0.0, 1.0);\n        float _1038;\n        if (front)\n        {\n            _1038 = _1036 * _1036;\n        }\n        else\n        {\n            _1038 = 0.0;\n        }\n        atten = _1038;\n        bool _1049 = _829 < 2.5;\n        if ((_829 > 1.5) && _1049)\n        {\n            int param_22 = _813 + 2;\n            vec4 _1057 = fa_light_texel(param_22);\n            float _1067 = _1057.w;\n            int param_23 = _813 + 3;\n            vec4 _1072 = fa_light_texel(param_23);\n            float _1073 = _1072.x;\n            float cos_inner = _1073;\n            if (_1073 > 1.5)\n            {\n                cos_inner = mix(_1067, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1067, cos_inner, dot(-l, normalize(_1057.xyz)));\n        }\n        if (_817 && (_829 < 1.5))\n        {\n            int param_24 = _813 + 6;\n            vec4 _1097 = fa_light_texel(param_24);\n            if (_1097.z > 0.5)\n            {\n                vec3 _1105 = -to_light;\n                int param_25 = _813 + 4;\n                int param_26 = _813 + 5;\n                vec3 _1119 = fa_light_texel(param_25).xyz;\n                vec3 _1123 = fa_light_texel(param_26).xyz;\n                vec3 _1132 = vec3(dot(_1105, _1119), dot(_1105, _1123), dot(_1105, cross(_1119, _1123)));\n                vec3 param_27 = _1132;\n                int _1136 = fa_cube_face(param_27);\n                int param_28 = _1136;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1163 = vec2(dot(_1132, cross(param_29, param_30)), dot(_1132, param_30)) / vec2(max(dot(_1132, param_29), 9.9999997473787516355514526367188e-05));\n                int _1167 = _1136 / 3;\n                vec2 param_31 = _1097.xy + (vec2(float(_1136 - (_1167 * 3)), float(_1167)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1163.x), 0.5 - (0.5 * _1163.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _813 + 7;\n            vec4 _1197 = fa_light_texel(param_33);\n            if (_1197.z > 0.5)\n            {\n                int param_34 = _813 + 2;\n                int param_35 = _813 + 4;\n                int param_36 = _813 + 5;\n                vec2 param_37 = _1197.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_817 && _1049)\n            {\n                int param_42 = _813 + 6;\n                vec4 _1244 = fa_light_texel(param_42);\n                int param_43 = _813 + 7;\n                vec4 _1249 = fa_light_texel(param_43);\n                bool _1252 = _1244.z > 0.5;\n                bool _1259;\n                if (!_1252)\n                {\n                    _1259 = _1249.z > 0.5;\n                }\n                else\n                {\n                    _1259 = _1252;\n                }\n                if (_1259)\n                {\n                    int param_44 = _813 + 2;\n                    vec4 _1266 = fa_light_texel(param_44);\n                    vec3 _1270 = normalize(_1266.xyz);\n                    int param_45 = _813 + 4;\n                    vec4 _1275 = fa_light_texel(param_45);\n                    int param_46 = _813 + 5;\n                    vec4 _1280 = fa_light_texel(param_46);\n                    if (_1252)\n                    {\n                        vec3 _1288 = -to_light;\n                        float _1295 = _1266.w;\n                        float _1311 = 0.5 / max(dot(_1288, _1270) * (sqrt(max(1.0 - (_1295 * _1295), 0.0)) / max(_1295, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1244.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1288, _1275.xyz) * _1311), 0.5 - (dot(_1288, _1280.xyz) * _1311));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1249.z > 0.5)\n                    {\n                        vec2 param_49 = _1249.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1270;\n                        vec3 param_52 = _1275.xyz;\n                        vec3 param_53 = _1280.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5807 = _826.xyz * atten;\n    if (_817)\n    {\n        _5807 *= fa_light_tint;\n    }\n    int _1380;\n    if (_843)\n    {\n        _1380 = 0;\n    }\n    else\n    {\n        _1380 = ((_829 > 1.5) && (_829 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5807, atten, 1.0, dist, _1380);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4891 = n < 0;\n    bool _4898;\n    if (!_4891)\n    {\n        _4898 = n >= fa_light_count();\n    }\n    else\n    {\n        _4898 = _4891;\n    }\n    if (_4898)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4906 = fa_cl_light(param);\n    int param_1 = _4906;\n    float _4910 = fa_baked_keep(param_1);\n    if (_4910 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4906;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _4926 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_4926.direction, _4926.color * _4910, _4926.attenuation * _4910, _4926.shadow, _4926._distance, _4926.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2117;\n    if (i == 0)\n    {\n        _2117 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2133;\n        if (i == 1)\n        {\n            _2133 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2141;\n            if (i == 2)\n            {\n                _2141 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2141 = fa_shadows[24].w;\n            }\n            _2133 = _2141;\n        }\n        _2117 = _2133;\n    }\n    return _2117;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2174 = fa_shadow_depth(param, param_1);\n    float _2178;\n    if (conv.x < 0.5)\n    {\n        _2178 = _2174;\n    }\n    else\n    {\n        _2178 = (conv.y * conv.z) / (conv.z - (_2174 * (conv.z - conv.y)));\n    }\n    return _2178;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2105 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2105), sin(_2105)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2224 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2253 = clamp((_2233 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2224;\n            vec2 _2272 = fa_shadow_vogel(param_3, param_4, param_5) * _2253;\n            vec2 param_6 = uv + (_2272 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2284 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2284 < (zr - (length(_2272) * plane)))\n            {\n                sum += _2284;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2310 = sum / cnt;\n        float _2320;\n        if (k < 0.0)\n        {\n            _2320 = (-k) / max(_2310, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2320 = k;\n        }\n        radius = clamp(((max(zr - _2310, 0.0) * unit) * _2320) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2342 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2342; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2342;\n        float param_11 = _2224;\n        vec2 _2361 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2361 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2361) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2342);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2403 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2408 = clamp(dot(n, l), 0.0, 1.0);\n    float _2414 = sqrt(1.0 - (_2408 * _2408));\n    float _2421 = min(_2414 / max(_2408, 0.20000000298023223876953125), 4.0);\n    float _2426;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2426 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2426 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2451 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2426 * _2414)), 1.0);\n    float _2458 = _2451.x;\n    bool _2461 = _2458 < fa_shadows[ci * 1 + 16].x;\n    bool _2470;\n    if (!_2461)\n    {\n        _2470 = _2458 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2470 = _2461;\n    }\n    bool _2479;\n    if (!_2470)\n    {\n        _2479 = _2451.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2479 = _2470;\n    }\n    bool _2488;\n    if (!_2479)\n    {\n        _2488 = _2451.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2488 = _2479;\n    }\n    bool _2495;\n    if (!_2488)\n    {\n        _2495 = _2451.z > 1.0;\n    }\n    else\n    {\n        _2495 = _2488;\n    }\n    if (_2495)\n    {\n        return -1.0;\n    }\n    float _2503;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2503 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2503 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2451.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2451.z - ((_2503 * (1.0 + (0.5 * _2421))) / _2403);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2403;\n    float param_5 = _2403 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2421, 3.0)) * 0.5) / _2403;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2881 = int(fa_shadows[25].x + 0.5);\n    if (_2881 < 1)\n    {\n        return 1.0;\n    }\n    float _2896 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2881 - 1;\n    if (_2896 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2908 = _2881 > 1;\n    bool _2915;\n    if (_2908)\n    {\n        _2915 = _2896 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2915 = _2908;\n    }\n    if (_2915)\n    {\n        ci = 1;\n    }\n    bool _2919 = _2881 > 2;\n    bool _2926;\n    if (_2919)\n    {\n        _2926 = _2896 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2926 = _2919;\n    }\n    if (_2926)\n    {\n        ci = 2;\n    }\n    bool _2930 = _2881 > 3;\n    bool _2937;\n    if (_2930)\n    {\n        _2937 = _2896 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2937 = _2930;\n    }\n    if (_2937)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2881)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2963 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2963;\n        if (_2963 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2988;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2988 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2988 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3007 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2988, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3018 = clamp((_2896 - (fa_shadow_split_at(param_7) - _3007)) / _3007, 0.0, 1.0);\n        if (_3018 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2881)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3039 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3039;\n                if (_3039 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3018);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2561 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2568;\n    if (!_2561)\n    {\n        _2568 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2568 = _2561;\n    }\n    if (_2568)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2581 = fa_light_texel(param);\n    float _2582 = _2581.x;\n    if (_2582 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2591 = int(_2582 + 0.5);\n    int param_1 = _2591;\n    vec4 _2595 = fa_light_texel(param_1);\n    int param_2 = _2591 + 1;\n    vec4 _2600 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2603 = _2595.y;\n    if (_2603 > 0.0)\n    {\n        float _2620 = 1.0 - smoothstep(0.75 * _2603, _2603, length(world - fa_shadows[27].xyz));\n        fade = _2620;\n        if (_2620 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2595.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2644 = (_2591 + 2) + (face * 6);\n    int param_4 = _2644;\n    int param_5 = _2644 + 1;\n    int param_6 = _2644 + 3;\n    vec4 _2658 = fa_light_texel(param_6);\n    int param_7 = _2644 + 4;\n    vec4 _2663 = fa_light_texel(param_7);\n    int param_8 = _2644 + 5;\n    vec4 _2668 = fa_light_texel(param_8);\n    float _2680 = _2668.x * max(dot(_2658, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2685 = clamp(dot(n, l), 0.0, 1.0);\n    float _2708 = clamp(dot(n, _2658.xyz), -1.0, 1.0);\n    float _2727 = min(sqrt(1.0 - (_2708 * _2708)) / max(abs(dot(n, world - lpos)) / max(dot(_2658, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2730 = _2600.y;\n    float _2732;\n    if (_2730 > 0.0)\n    {\n        _2732 = _2730;\n    }\n    else\n    {\n        _2732 = 1.5 * _2680;\n    }\n    vec4 _2752 = vec4(world + (n * (_2732 * sqrt(1.0 - (_2685 * _2685)))), 1.0);\n    float _2756 = dot(_2658, _2752);\n    float _2759 = _2668.y;\n    if (_2756 < _2759)\n    {\n        return 1.0;\n    }\n    vec2 _2774 = vec2(dot(fa_light_texel(param_4), _2752), dot(fa_light_texel(param_5), _2752)) / vec2(_2756);\n    float _2776 = _2774.x;\n    bool _2779 = _2776 < _2663.x;\n    bool _2788;\n    if (!_2779)\n    {\n        _2788 = _2776 > _2663.z;\n    }\n    else\n    {\n        _2788 = _2779;\n    }\n    bool _2797;\n    if (!_2788)\n    {\n        _2797 = _2774.y < _2663.y;\n    }\n    else\n    {\n        _2797 = _2788;\n    }\n    bool _2806;\n    if (!_2797)\n    {\n        _2806 = _2774.y > _2663.w;\n    }\n    else\n    {\n        _2806 = _2797;\n    }\n    if (_2806)\n    {\n        return 1.0;\n    }\n    float _2812 = _2600.x;\n    float _2814;\n    if (_2812 > 0.0)\n    {\n        _2814 = _2812;\n    }\n    else\n    {\n        _2814 = 1.5 * _2680;\n    }\n    vec2 param_9 = _2774;\n    vec4 param_10 = _2663;\n    float param_11 = _2756 - (_2814 * (1.0 + (0.5 * _2727)));\n    float param_12 = _2680;\n    float param_13 = 1.0;\n    float param_14 = _2668.z * 0.25;\n    float param_15 = (_2680 * min(_2727, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2759, _2668.z);\n    int param_17 = int(_2595.z + 0.5);\n    float param_18 = _2595.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4406 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4413;\n    if (!_4406)\n    {\n        _4413 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4413 = _4406;\n    }\n    if (_4413)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4426 = fa_light_texel(param);\n    float _4427 = _4426.y;\n    float len = _4427;\n    if (_4427 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4439 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4449 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4439);\n    if (_4449 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4455 = len;\n    float _4458 = min(_4455, 0.89999997615814208984375 * dist);\n    len = _4458;\n    float _4463 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4439);\n    float _4468 = _4463 + (0.5 * _4458);\n    vec3 _4474 = world + (gn * _4463);\n    float _4476 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4540;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4491 = (float(k) + _4476) * 0.083333335816860198974609375;\n        vec3 _4499 = _4474 + (l * (_4491 * len));\n        vec4 _4505 = vec4(_4499, 1.0);\n        float _4511 = dot(fa_mesh_fs_params[28], _4505);\n        if (_4511 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4531 = vec2(dot(fa_mesh_fs_params[26], _4505), dot(fa_mesh_fs_params[27], _4505)) / vec2(_4511);\n        float _4535 = _4531.x * 0.5;\n        float _4536 = _4535 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4540 = (_4531.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4540 = 0.5 - (_4531.y * 0.5);\n        }\n        bool _4556 = _4536 < 0.0;\n        bool _4563;\n        if (!_4556)\n        {\n            _4563 = _4536 >= 1.0;\n        }\n        else\n        {\n            _4563 = _4556;\n        }\n        bool _4570;\n        if (!_4563)\n        {\n            _4570 = _4540 < 0.0;\n        }\n        else\n        {\n            _4570 = _4563;\n        }\n        bool _4577;\n        if (!_4570)\n        {\n            _4577 = _4540 >= 1.0;\n        }\n        else\n        {\n            _4577 = _4570;\n        }\n        if (_4577)\n        {\n            break;\n        }\n        vec4 _4596 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4536, _4540) * fa_mesh_fs_params[24].zw), 0);\n        if (_4596.w < 0.5)\n        {\n            continue;\n        }\n        float _4615 = (dot(fa_mesh_fs_params[29].xyz, _4499) + fa_mesh_fs_params[29].w) - _4596.x;\n        if ((_4615 > _4463) && (_4615 < _4468))\n        {\n            occ = max(occ, (1.0 - (_4491 * _4491)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4536, 0.5 - _4535), min(_4540, 1.0 - _4540))));\n        }\n    }\n    return 1.0 - (occ * _4449);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4718 = fa_baked_keep(param);\n    if (_4718 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4744 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5953 = _4744.color;\n    float _5954 = _4744.attenuation;\n    float _5955 = _4744.shadow;\n    bool _4747 = _4744.type == 0;\n    if (_4747 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4744.direction;\n        float _4758 = fa_shadow_factor(param_5, param_6);\n        _5955 = _4758;\n        _5953 *= _4758;\n    }\n    else\n    {\n        bool _4769 = _4744.type != 0;\n        bool _4775;\n        if (_4769)\n        {\n            _4775 = _5954 > 0.0;\n        }\n        else\n        {\n            _4775 = _4769;\n        }\n        if (_4775)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4744.direction;\n            float _4794 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5955 = _4794;\n            _5953 *= _4794;\n        }\n    }\n    bool _4804 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4810;\n    if (_4804)\n    {\n        _4810 = _5954 > 0.0;\n    }\n    else\n    {\n        _4810 = _4804;\n    }\n    if (_4810)\n    {\n        float _4817;\n        if (_4747)\n        {\n            _4817 = 1000000000.0;\n        }\n        else\n        {\n            _4817 = _4744._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4744.direction;\n        float param_18 = _4817;\n        float _4835 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5955 *= _4835;\n        _5953 *= _4835;\n    }\n    float _4848 = _5954;\n    float _4849 = _4848 * _4718;\n    _5954 = _4849;\n    vec3 _4853 = _5953;\n    vec3 _4854 = _4853 * _4718;\n    _5953 = _4854;\n    return LightSample(_4744.direction, _4854, _4849, _5955, _4744._distance, _4744.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4865 = n < 0;\n    bool _4872;\n    if (!_4865)\n    {\n        _4872 = n >= fa_light_count();\n    }\n    else\n    {\n        _4872 = _4865;\n    }\n    if (_4872)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _4887 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4887;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3797 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3805 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3808 = int(_3797);\n    int _3811 = int(_3805);\n    float _3821 = _3805 - float(_3811);\n    int _3877 = (_3808 * 9) + _3811;\n    int _3897 = ((_3808 + 1) * 9) + _3811;\n    return mix(mix(_3872[_3877], _3872[_3877 + 1], _3821), mix(_3872[_3897], _3872[_3897 + 1], _3821), _3797 - float(_3808));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5819 = false;\n    float _5820 = 1.0;\n    float _5821 = 1.0;\n    float _5822 = 1.0;\n    float _5823 = 0.0;\n    float _5824 = 0.0;\n    float _5825 = 0.0;\n    float _5826 = 0.0;\n    float _5828 = 1.0;\n    bool _5829 = false;\n    vec3 _5830 = vec3(0.0);\n    float _5831 = 1.0;\n    float _5832 = 1.0;\n    float _5833 = 1.0;\n    float _5834 = 0.0;\n    float _5835 = 0.0;\n    vec3 _5836 = vec3(1.0, 0.0, 0.0);\n    vec3 _5837 = vec3(0.0, 0.0, 1.0);\n    float _5838 = 1.0;\n    float _5839 = 1.0;\n    float _3948 = clamp(s.specular, 0.0, 1.0);\n    float _3952 = clamp(s.ior, 1.0, 3.0);\n    bool _3957 = (_3948 != 1.0) || (_3952 != 1.5);\n    bool _3966;\n    if (!_3957)\n    {\n        _3966 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3966 = _3957;\n    }\n    if (_3966)\n    {\n        float _3974 = (_3952 - 1.0) / (_3952 + 1.0);\n        f0 = mix(min(vec3(_3974 * _3974) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3948, s.albedo, vec3(metallic));\n        _5820 = mix(_3948, 1.0, metallic);\n        _5819 = true;\n    }\n    float _4001 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4001 > 0.0)\n    {\n        float _4009 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5823 = _4001;\n        _5824 = _4009;\n        float _4016 = _4009 * _4009;\n        _5825 = _4016;\n        _5826 = _4016 * _4016;\n        float _4028 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5828 = _4028;\n        _5821 = 1.0 - (_4001 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4028, 0.0, 1.0), 5.0))));\n        _5819 = true;\n    }\n    vec3 _4047 = max(s.sheen_color, vec3(0.0));\n    float _4056 = max(_4047.x, max(_4047.y, _4047.z));\n    if (_4056 > 0.0)\n    {\n        float _4064 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5829 = true;\n        _5830 = _4047;\n        _5831 = _4064;\n        _5832 = _4064 * _4064;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4064;\n        float _4081 = fa_sheen_albedo(param, param_1);\n        _5834 = _4081;\n        _5833 = 1.0 - min(_4056 * _4081, 1.0);\n        _5819 = true;\n    }\n    _5822 = _5821 * _5833;\n    float _4100 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4100 != 0.0)\n    {\n        vec3 _4115 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4115;\n        if (dot(_4115, _4115) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4127 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4127.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4127.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4127.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4131 = t;\n        vec3 _4132 = normalize(_4131);\n        t = _4132;\n        vec3 _4157 = normalize((_4132 * cos(s.anisotropy_rotation)) + ((cross(n, _4132) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5836 = _4157;\n        _5837 = cross(n, _4157);\n        float _4167 = roughness * roughness;\n        float _4173 = mix(_4167, 1.0, _4100 * _4100);\n        bool _4175 = _4100 > 0.0;\n        _5838 = _4175 ? _4173 : _4167;\n        _5839 = _4175 ? _4167 : _4173;\n        _5835 = _4100;\n        _5819 = true;\n    }\n    return FaLayers(_5819, _5820, _5821, _5822, _5823, _5824, _5825, _5826, i.world_normal, _5828, _5829, _5830, _5831, _5832, _5833, _5834, _5835, _5836, _5837, _5838, _5839);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3729 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3732 = _3729.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3732 * _3732, exp2((-9.27999973297119140625) * ndv)) * _3732) + _3729.y)) + _3729.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3165 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3168 = _3165.x;\n    float _3170 = _3165.z;\n    vec2 e = vec2(_3168, _3170);\n    if (_3165.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3170)) * ((_3168 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3168)) * ((_3170 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3217;\n    if (lv == 0)\n    {\n        _3217 = 0.0;\n    }\n    else\n    {\n        _3217 = res + 2.0;\n    }\n    float _3227;\n    if (lv == 0)\n    {\n        _3227 = 0.0;\n    }\n    else\n    {\n        _3227 = (res - (res / float(1 << (lv - 1)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3217, _3227)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3272;\n    if (res > 64.5)\n    {\n        _3272 = 5.0;\n    }\n    else\n    {\n        _3272 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3287 = clamp(rough, 0.0, 1.0) * (_3272 - 1.0);\n    int _3294 = int(min(floor(_3287), _3272 - 2.0));\n    float _3299 = _3287 - float(_3294);\n    vec3 param = d;\n    vec2 _3303 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3294;\n    vec2 param_4 = _3303;\n    vec3 _3313 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3299 < 0.00200000009499490261077880859375)\n    {\n        return _3313;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3294 + 1;\n    vec2 param_8 = _3303;\n    return mix(_3313, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3299));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3351 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3358 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3365 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3371 = dot(bx.xyz, d);\n    float _3375 = dot(by.xyz, d);\n    float _3379 = dot(bz.xyz, d);\n    float _3385;\n    if (_3371 > 9.9999999747524270787835121154785e-07)\n    {\n        _3385 = (1.0 - _3351) / _3371;\n    }\n    else\n    {\n        float _3399;\n        if (_3371 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3399 = ((-1.0) - _3351) / _3371;\n        }\n        else\n        {\n            _3399 = 1000000015047466219876688855040.0;\n        }\n        _3385 = _3399;\n    }\n    float tx = _3385;\n    float _3416;\n    if (_3375 > 9.9999999747524270787835121154785e-07)\n    {\n        _3416 = (1.0 - _3358) / _3375;\n    }\n    else\n    {\n        float _3429;\n        if (_3375 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3429 = ((-1.0) - _3358) / _3375;\n        }\n        else\n        {\n            _3429 = 1000000015047466219876688855040.0;\n        }\n        _3416 = _3429;\n    }\n    float ty = _3416;\n    float _3445;\n    if (_3379 > 9.9999999747524270787835121154785e-07)\n    {\n        _3445 = (1.0 - _3365) / _3379;\n    }\n    else\n    {\n        float _3458;\n        if (_3379 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3458 = ((-1.0) - _3365) / _3379;\n        }\n        else\n        {\n            _3458 = 1000000015047466219876688855040.0;\n        }\n        _3445 = _3458;\n    }\n    float _3470 = tx;\n    float _3473 = (_3470 > 0.0) ? _3470 : 1000000015047466219876688855040.0;\n    tx = _3473;\n    float _3474 = ty;\n    float _3477 = (_3474 > 0.0) ? _3474 : 1000000015047466219876688855040.0;\n    ty = _3477;\n    float _3487 = min(_3473, min(_3477, (_3445 > 0.0) ? _3445 : 1000000015047466219876688855040.0));\n    if (_3487 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3503 = (fa_world_pos + (d * _3487)) - posw.xyz;\n    vec3 _3508;\n    if (dot(_3503, _3503) > 1.0000000133514319600180897396058e-10)\n    {\n        _3508 = normalize(_3503);\n    }\n    else\n    {\n        _3508 = d;\n    }\n    return _3508;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3554 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 outc = vec3(0.0);\n    if (_3554 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[39].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3584 = rough * rough;\n            float _3615 = 0.60000002384185791015625 * _3584;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3584)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3615, 0.0500000007450580596923828125 + _3615, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3584 * 0.60000002384185791015625));\n        }\n        outc = base * _3554;\n    }\n    if (fa_mesh_fs_params[40].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[40];\n        vec4 param_5 = fa_mesh_fs_params[41];\n        vec4 param_6 = fa_mesh_fs_params[42];\n        vec4 param_7 = fa_mesh_fs_params[43];\n        vec4 param_8 = fa_mesh_fs_params[44];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3674 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3674 * fa_mesh_fs_params[40].w);\n    }\n    if (fa_mesh_fs_params[45].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[45];\n        vec4 param_12 = fa_mesh_fs_params[46];\n        vec4 param_13 = fa_mesh_fs_params[47];\n        vec4 param_14 = fa_mesh_fs_params[48];\n        vec4 param_15 = fa_mesh_fs_params[49];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3706 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3706 * fa_mesh_fs_params[45].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4208;\n        if (L.aniso >= 0.0)\n        {\n            _4208 = L.b;\n        }\n        else\n        {\n            _4208 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4208, v), _4208), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4241 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4241.x) + (vec3(L.f90) * _4241.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4296 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4296.x) + _4296.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3771 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3771.x) + vec3(_3771.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4335 = clamp(s.metallic, 0.0, 1.0);\n    float _4339 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4346 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4335));\n    vec3 f0 = _4346;\n    vec3 _4350 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4350;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4335;\n    float param_5 = _4339;\n    vec3 param_6 = _4346;\n    FaLayers _4367 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4367.on)\n    {\n        FaLayers param_7 = _4367;\n        vec3 param_8 = _4350;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4339;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _4350;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _4339;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4957 = fa_light_unshadowed(param, param_1);\n        float _4965 = dot(_4957.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_4965 > bestPower)\n        {\n            bestPower = _4965;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4994 = fa_light(param_2, param_3);\n        float _5002;\n        if (dot(s.normal, _4994.direction) > 0.5)\n        {\n            _5002 = 1.0;\n        }\n        else\n        {\n            _5002 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _4994.color) * _5002);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3063 = int(fa_shadows[25].x + 0.5);\n    float _3073 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3078 = _3063 > 0;\n    bool _3087;\n    if (_3078)\n    {\n        int param = _3063 - 1;\n        _3087 = _3073 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3087 = _3078;\n    }\n    if (_3087)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3093 = _3063 > 1;\n        bool _3100;\n        if (_3093)\n        {\n            _3100 = _3073 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3100 = _3093;\n        }\n        if (_3100)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3106 = _3063 > 2;\n        bool _3113;\n        if (_3106)\n        {\n            _3113 = _3073 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3113 = _3106;\n        }\n        if (_3113)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3119 = _3063 > 3;\n        bool _3126;\n        if (_3119)\n        {\n            _3126 = _3073 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3126 = _3119;\n        }\n        if (_3126)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5693 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5693 = -_5693;\n    }\n    vec3 _5380 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5693, fa_world_tangent, fa_uv, fa_vertex_color, _5380, gl_FrontFacing);\n    Surface _5388 = fa_standard_surface(param_1);\n    vec3 _5724 = _5388.albedo;\n    float _5725 = _5388.alpha;\n    vec3 _5726 = _5388.normal;\n    float _5727 = _5388.metallic;\n    float _5728 = _5388.roughness;\n    float _5729 = _5388.occlusion;\n    vec3 _5730 = _5388.emission;\n    float _5731 = _5388.clearcoat;\n    float _5732 = _5388.clearcoat_roughness;\n    vec3 _5733 = _5388.sheen_color;\n    float _5734 = _5388.sheen_roughness;\n    float _5735 = _5388.anisotropy;\n    float _5736 = _5388.anisotropy_rotation;\n    float _5737 = _5388.specular;\n    float _5738 = _5388.ior;\n    vec3 _5739 = _5388.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5693, fa_world_tangent, fa_uv, fa_vertex_color, _5380, gl_FrontFacing);\n    Surface param_3 = _5388;\n    surface(param_2, param_3);\n    _5724 = param_3.albedo;\n    _5725 = param_3.alpha;\n    _5726 = param_3.normal;\n    _5727 = param_3.metallic;\n    _5728 = param_3.roughness;\n    _5729 = param_3.occlusion;\n    _5730 = param_3.emission;\n    _5731 = param_3.clearcoat;\n    _5732 = param_3.clearcoat_roughness;\n    _5733 = param_3.sheen_color;\n    _5734 = param_3.sheen_roughness;\n    _5735 = param_3.anisotropy;\n    _5736 = param_3.anisotropy_rotation;\n    _5737 = param_3.specular;\n    _5738 = param_3.ior;\n    _5739 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5693;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5724 = param_6;\n    _5726 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5724;\n    }\n    else\n    {\n        vec3 _5426 = _5726;\n        vec3 _5427 = normalize(_5426);\n        _5726 = _5427;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _5693, fa_world_tangent, fa_uv, fa_vertex_color, _5380, gl_FrontFacing);\n        Surface param_9 = Surface(_5724, _5725, _5427, _5727, _5728, _5729, _5730, _5731, _5732, _5733, _5734, _5735, _5736, _5737, _5738, _5739);\n        vec3 _5438 = lighting(param_8, param_9);\n        result = _5438;\n    }\n    vec3 _5442 = result;\n    vec3 _5443 = _5442 + _5730;\n    result = _5443;\n    vec3 param_10 = _5443;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5452 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5459;\n    if (!_5452)\n    {\n        _5459 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5459 = _5452;\n    }\n    if (_5459)\n    {\n        vec3 _5468 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5474 = dot(_5468, fa_mesh_fs_params[9].xyz);\n        bool _5478 = fa_mesh_fs_params[9].w > 0.5;\n        float _5479;\n        if (_5478)\n        {\n            _5479 = _5474;\n        }\n        else\n        {\n            _5479 = length(_5468);\n        }\n        float _5491 = _5479 - fa_mesh_fs_params[8].x;\n        if (_5491 > 0.0)\n        {\n            float _5500 = fa_mesh_fs_params[7].w * _5491;\n            float tau = _5500 * _5500;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5516;\n                if (_5478)\n                {\n                    _5516 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5474);\n                }\n                else\n                {\n                    _5516 = fa_mesh_fs_params[0].y;\n                }\n                float _5537 = mix(_5516, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5479, 0.0, 1.0));\n                float _5541 = fa_world_pos.y - _5537;\n                float _5546 = _5537 - fa_mesh_fs_params[8].z;\n                float _5551 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5554 = _5546 <= 0.0;\n                bool _5555 = !_5554;\n                bool _5561;\n                if (_5555)\n                {\n                    _5561 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5561 = _5554;\n                }\n                float _5562;\n                if (_5561)\n                {\n                    _5562 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5562 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5546, 80.0));\n                }\n                bool _5589;\n                if (_5555)\n                {\n                    _5589 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5589 = _5554;\n                }\n                float _5590;\n                if (_5589)\n                {\n                    _5590 = fa_mesh_fs_params[8].y * _5546;\n                }\n                else\n                {\n                    _5590 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5546, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5615 = _5551 <= 0.0;\n                bool _5622;\n                if (!_5615)\n                {\n                    _5622 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5622 = _5615;\n                }\n                float _5623;\n                if (_5622)\n                {\n                    _5623 = fa_mesh_fs_params[8].y * _5551;\n                }\n                else\n                {\n                    _5623 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5551, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5650;\n                if (abs(_5541) < 0.001000000047497451305389404296875)\n                {\n                    _5650 = _5562;\n                }\n                else\n                {\n                    _5650 = (_5623 - _5590) / _5541;\n                }\n                tau += (_5491 * max(_5650, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5725);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_469",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
            "inst_name": "_2127",
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
            "inst_name": "_5008",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3872[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[50];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1398 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1405;\n    if (!_1398)\n    {\n        _1405 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1405 = _1398;\n    }\n    bool _1413;\n    if (!_1405)\n    {\n        _1413 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1413 = _1405;\n    }\n    bool _1420;\n    if (!_1413)\n    {\n        _1420 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1420 = _1413;\n    }\n    bool _1427;\n    if (!_1420)\n    {\n        _1427 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1427 = _1420;\n    }\n    if (_1427)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1437 = vec4(world_pos, 1.0);\n    float _1443 = dot(fa_mesh_fs_params[16], _1437);\n    if (!(_1443 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1465 = vec2(dot(fa_mesh_fs_params[14], _1437), dot(fa_mesh_fs_params[15], _1437)) / vec2(_1443);\n    int _1469 = int(fa_mesh_fs_params[18].x);\n    int _1473 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1473) + clamp(int(floor(((_1465.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1473 - 1)) * _1469)) + clamp(int(floor(((_1465.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1469 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1549 = fa_cluster_texel(param);\n    return ivec2(int(_1549.x), int(_1549.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4692 = fa_cluster_lookup(param);\n    fa_cl_slot = _4692.x;\n    fa_cl_local = _4692.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5069 = fa_linear_to_srgb(param);\n        c = _5069;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5077 = fa_srgb_to_linear(param_1);\n            c = _5077;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _349;\n    if (i.front_facing)\n    {\n        _349 = i.world_normal;\n    }\n    else\n    {\n        _349 = -i.world_normal;\n    }\n    vec3 _373 = normalize(i.world_tangent.xyz - (_349 * dot(_349, i.world_tangent.xyz)));\n    vec3 _401 = normalize(((_373 * m.x) + ((cross(_349, _373) * i.world_tangent.w) * m.y)) + (_349 * m.z));\n    vec3 _404;\n    if (i.front_facing)\n    {\n        _404 = _401;\n    }\n    else\n    {\n        _404 = -_401;\n    }\n    return _404;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5108 = fa_tex_fix(param_2, param_3);\n    vec4 _6187 = base_t;\n    _6187.x = _5108.x;\n    _6187.y = _5108.y;\n    _6187.z = _5108.z;\n    base_t = _6187;\n    vec4 _5122 = (_6187 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6001 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5154 = fa_tex_fix(param_6, param_7);\n        vec3 _5157 = (_5154 * 2.0) - vec3(1.0);\n        vec2 _5162 = _5157.xy * fa_mesh_fs_params[6].x;\n        vec3 _6195 = _5157;\n        _6195.x = _5162.x;\n        _6195.y = _5162.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6195;\n        _6001 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5190 = fa_tex_fix(param_12, param_13);\n    vec4 _6198 = mrt;\n    _6198.x = _5190.x;\n    _6198.y = _5190.y;\n    _6198.z = _5190.z;\n    mrt = _6198;\n    vec4 _5218 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5218.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5229 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5259 = fa_tex_fix(param_20, param_21);\n    float _6006 = fa_mesh_fs_params[20].x;\n    float _6007 = fa_mesh_fs_params[20].y;\n    float _6010 = fa_mesh_fs_params[20].z;\n    float _6009 = fa_mesh_fs_params[21].w;\n    float _6012 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6006 *= _5229.y;\n            _6007 *= _5229.z;\n            _6009 *= _5218.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6010 *= mrt.x;\n            _6012 *= mrt.w;\n        }\n    }\n    return Surface(_5122.xyz, _5122.w, _6001, clamp(fa_mesh_fs_params[5].x * _5190.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5190.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5229.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5259), _6006, _6007, fa_mesh_fs_params[21].xyz, _6009, _6010, fa_mesh_fs_params[20].w, _6012, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1629 = rect.zw - rect.xy;\n    vec2 _1633 = _1629 * atlas;\n    vec2 _1637 = ddx * _1633;\n    vec2 _1641 = ddy * _1633;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1629), clamp(0.5 * log2(max(max(dot(_1637, _1637), dot(_1641, _1641)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1674 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1681;\n    if (!_1674)\n    {\n        _1681 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1681 = _1674;\n    }\n    if (_1681)\n    {\n        return;\n    }\n    vec3 _1687 = dFdx(world_pos);\n    vec3 _1690 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1694 = fa_cluster_texel(param);\n    int _1698 = int(_1694.w);\n    if (_1698 < 1)\n    {\n        return;\n    }\n    int _1708 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1708;\n    vec4 _1712 = fa_light_texel(param_1);\n    vec2 _1715 = _1712.yz;\n    int _1719 = int(_1712.w);\n    int param_2 = _1708 + 1;\n    vec4 _1724 = fa_light_texel(param_2);\n    float _1725 = _1724.x;\n    int _1731 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1735 = int(_1694.z);\n    vec3 _2000;\n    for (int k = 0; k < _1698; k++)\n    {\n        int _1748 = _1735 + k;\n        int param_3 = _1719 + (_1748 >> 2);\n        int _1765 = (_1708 + 2) + (int(fa_light_texel(param_3)[_1748 & 3]) * 7);\n        int param_4 = _1765 + 6;\n        vec4 _1770 = fa_light_texel(param_4);\n        if (((int(_1770.w + 0.5) >> _1731) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1765;\n        vec4 _1785 = fa_light_texel(param_5);\n        int param_6 = _1765 + 1;\n        vec4 _1790 = fa_light_texel(param_6);\n        int param_7 = _1765 + 2;\n        vec4 _1795 = fa_light_texel(param_7);\n        vec3 _1798 = _1785.xyz;\n        float _1803 = dot(_1798, world_pos) + _1785.w;\n        vec3 _1805 = _1790.xyz;\n        float _1810 = dot(_1805, world_pos) + _1790.w;\n        vec3 _1812 = _1795.xyz;\n        float _1817 = dot(_1812, world_pos) + _1795.w;\n        bool _1822 = abs(_1803) > 0.5;\n        bool _1830;\n        if (!_1822)\n        {\n            _1830 = abs(_1810) > 0.5;\n        }\n        else\n        {\n            _1830 = _1822;\n        }\n        bool _1838;\n        if (!_1830)\n        {\n            _1838 = abs(_1817) > 0.5;\n        }\n        else\n        {\n            _1838 = _1830;\n        }\n        if (_1838)\n        {\n            continue;\n        }\n        float _1853 = clamp(dot(geo_normal, normalize(_1812)) * _1770.z, 0.0, 1.0);\n        if (_1853 <= 0.0)\n        {\n            continue;\n        }\n        float _1873 = (clamp((0.5 - abs(_1817)) * 10.0, 0.0, 1.0) * _1853) * _1770.x;\n        vec2 _1881 = vec2(_1803 + 0.5, 0.5 - _1810);\n        vec2 _1891 = vec2(dot(_1798, _1687), dot(_1805, _1687));\n        vec2 _1901 = vec2(dot(_1798, _1690), dot(_1805, _1690));\n        int param_8 = _1765 + 5;\n        vec4 _1906 = fa_light_texel(param_8);\n        int param_9 = _1765 + 3;\n        vec4 _1911 = fa_light_texel(param_9);\n        int param_10 = _1765 + 4;\n        vec4 _1916 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1906.xyz;\n        bool _1926 = _1911.z > _1911.x;\n        if (_1926)\n        {\n            vec4 param_11 = _1911;\n            vec2 param_12 = _1881;\n            vec2 param_13 = _1715;\n            vec2 param_14 = _1891;\n            vec2 param_15 = _1901;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1725 > 0.5) && (_1725 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1952 = fa_dc_to_linear(param_16);\n                vec4 _6081 = tx;\n                _6081.x = _1952.x;\n                _6081.y = _1952.y;\n                _6081.z = _1952.z;\n                tx = _6081;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1873 * tex_a) * _1906.w, 0.0, 1.0)));\n        if (_1916.z > _1916.x)\n        {\n            vec4 param_17 = _1916;\n            vec2 param_18 = _1881;\n            vec2 param_19 = _1715;\n            vec2 param_20 = _1891;\n            vec2 param_21 = _1901;\n            vec4 _1996 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1725 > 1.5)\n            {\n                vec3 param_22 = _1996.xyz;\n                vec3 _2006 = fa_dc_to_srgb(param_22);\n                _2000 = _2006;\n            }\n            else\n            {\n                _2000 = _1996.xyz;\n            }\n            vec3 _2015 = (_2000 * 2.0) - vec3(1.0);\n            vec2 _2020 = _2015.xy * _1770.y;\n            vec3 _2042 = (normalize(_1798) * _2020.x) + (normalize(_1805) * _2020.y);\n            vec3 _2045 = normalize(normal);\n            normal = normalize(mix(_2045, normalize((_2045 * max(_2015.z, 0.0500000007450580596923828125)) + (_2042 - (_2045 * dot(_2045, _2042)))), vec3(clamp(_1873 * (_1926 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4662;\n    if (fa_lm.z > 0.5)\n    {\n        _4662 = 0.0;\n    }\n    else\n    {\n        _4662 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _4673 = _4662 < 1.0;\n    bool _4679;\n    if (_4673)\n    {\n        int param = li;\n        _4679 = fa_light_baked(param);\n    }\n    else\n    {\n        _4679 = _4673;\n    }\n    return _4679 ? _4662 : 1.0;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _647 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _660 = (c - (ru * hx)) - p;\n        vec3 _666 = ru * (2.0 * hx);\n        float _672 = max(dot(_666, _666), 9.9999999392252902907785028219223e-09);\n        float _676 = dot(_660, _666);\n        float t = clamp((-_676) / _672, 0.0, 1.0);\n        if (_647)\n        {\n            float _691 = dot(r, _666);\n            float _697 = _672 - (_691 * _691);\n            if (abs(_697) > (9.9999997473787516355514526367188e-06 * _672))\n            {\n                t = clamp(((dot(r, _660) * _691) - _676) / _697, 0.0, 1.0);\n            }\n        }\n        return (p + _660) + (_666 * t);\n    }\n    vec3 q = p;\n    float _729 = dot(r, axis);\n    bool _737;\n    if (_647)\n    {\n        _737 = abs(_729) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _737 = _647;\n    }\n    if (_737)\n    {\n        float _747 = dot(c - p, axis) / _729;\n        if (_747 > 0.0)\n        {\n            q = p + (r * _747);\n        }\n    }\n    vec3 _760 = q - c;\n    vec2 xy = vec2(dot(_760, ru), dot(_760, uu));\n    if (shape > 0.5)\n    {\n        float _775 = length(xy);\n        if (_775 > hx)\n        {\n            xy *= (hx / _775);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _416 = abs(d);\n    float _418 = _416.x;\n    float _420 = _416.y;\n    bool _421 = _418 >= _420;\n    bool _429;\n    if (_421)\n    {\n        _429 = _418 >= _416.z;\n    }\n    else\n    {\n        _429 = _421;\n    }\n    int _430;\n    if (_429)\n    {\n        _430 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _445;\n        if (_420 >= _416.z)\n        {\n            _445 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _445 = (d.z > 0.0) ? 4 : 5;\n        }\n        _430 = _445;\n    }\n    return _430;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _567 = dot(d, right);\n    float _571 = dot(d, up);\n    float _582;\n    if (((_567 * _567) + (_571 * _571)) > 1.0000000133514319600180897396058e-10)\n    {\n        _582 = atan(_571, _567) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _582 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_582 - floor(_582)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _813 = fa_light_base(param);\n    bool _817 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _813;\n    vec4 _821 = fa_light_texel(param_1);\n    int param_2 = _813 + 1;\n    vec4 _826 = fa_light_texel(param_2);\n    float _829 = _826.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _841 = _817 && (_829 > 2.5);\n    fa_light_is_area = _841;\n    bool _843 = _829 < 0.5;\n    vec3 l;\n    if (_843)\n    {\n        l = normalize(_821.xyz);\n        if (_817)\n        {\n            int param_3 = _813 + 6;\n            vec4 _857 = fa_light_texel(param_3);\n            if (_857.z > 0.5)\n            {\n                int param_4 = _813 + 4;\n                vec4 _867 = fa_light_texel(param_4);\n                int param_5 = _813 + 5;\n                vec4 _872 = fa_light_texel(param_5);\n                vec2 param_6 = _857.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _867.xyz) * _867.w, (-dot(world_pos, _872.xyz)) * _872.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _902 = _821.xyz;\n        vec3 _904 = _902 - world_pos;\n        vec3 to_light = _904;\n        float _907 = length(_904);\n        float reach = _907;\n        bool front = true;\n        if (_841)\n        {\n            int param_8 = _813 + 7;\n            reach = max(_907 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _813 + 4;\n            vec4 _931 = fa_light_texel(param_9);\n            int param_10 = _813 + 5;\n            vec4 _936 = fa_light_texel(param_10);\n            int param_11 = _813 + 6;\n            vec4 _941 = fa_light_texel(param_11);\n            float _942 = _941.w;\n            int param_12 = _813 + 2;\n            vec3 _949 = normalize(fa_light_texel(param_12).xyz);\n            bool _951 = _942 > 1.5;\n            bool _959;\n            if (!_951)\n            {\n                _959 = dot(_949, to_light) < 0.0;\n            }\n            else\n            {\n                _959 = _951;\n            }\n            front = _959;\n            vec3 r = vec3(0.0);\n            vec3 _968 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _972 = dot(n, n) > 0.5;\n            bool _980;\n            if (_972)\n            {\n                _980 = dot(_968, _968) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _980 = _972;\n            }\n            if (_980)\n            {\n                r = reflect(-normalize(_968), normalize(n));\n            }\n            vec3 param_13 = _902;\n            vec3 param_14 = _949;\n            vec3 param_15 = _931.xyz;\n            vec3 param_16 = _936.xyz;\n            float param_17 = _931.w;\n            float param_18 = _936.w;\n            float param_19 = _942;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1016 = length(to_light);\n        dist = _1016;\n        l = to_light / vec3(max(_1016, 9.9999997473787516355514526367188e-05));\n        float _1030 = reach / max(_821.w, 0.001000000047497451305389404296875);\n        float _1036 = clamp(1.0 - (_1030 * _1030), 0.0, 1.0);\n        float _1038;\n        if (front)\n        {\n            _1038 = _1036 * _1036;\n        }\n        else\n        {\n            _1038 = 0.0;\n        }\n        atten = _1038;\n        bool _1049 = _829 < 2.5;\n        if ((_829 > 1.5) && _1049)\n        {\n            int param_22 = _813 + 2;\n            vec4 _1057 = fa_light_texel(param_22);\n            float _1067 = _1057.w;\n            int param_23 = _813 + 3;\n            vec4 _1072 = fa_light_texel(param_23);\n            float _1073 = _1072.x;\n            float cos_inner = _1073;\n            if (_1073 > 1.5)\n            {\n                cos_inner = mix(_1067, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1067, cos_inner, dot(-l, normalize(_1057.xyz)));\n        }\n        if (_817 && (_829 < 1.5))\n        {\n            int param_24 = _813 + 6;\n            vec4 _1097 = fa_light_texel(param_24);\n            if (_1097.z > 0.5)\n            {\n                vec3 _1105 = -to_light;\n                int param_25 = _813 + 4;\n                int param_26 = _813 + 5;\n                vec3 _1119 = fa_light_texel(param_25).xyz;\n                vec3 _1123 = fa_light_texel(param_26).xyz;\n                vec3 _1132 = vec3(dot(_1105, _1119), dot(_1105, _1123), dot(_1105, cross(_1119, _1123)));\n                vec3 param_27 = _1132;\n                int _1136 = fa_cube_face(param_27);\n                int param_28 = _1136;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1163 = vec2(dot(_1132, cross(param_29, param_30)), dot(_1132, param_30)) / vec2(max(dot(_1132, param_29), 9.9999997473787516355514526367188e-05));\n                int _1167 = _1136 / 3;\n                vec2 param_31 = _1097.xy + (vec2(float(_1136 - (_1167 * 3)), float(_1167)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1163.x), 0.5 - (0.5 * _1163.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _813 + 7;\n            vec4 _1197 = fa_light_texel(param_33);\n            if (_1197.z > 0.5)\n            {\n                int param_34 = _813 + 2;\n                int param_35 = _813 + 4;\n                int param_36 = _813 + 5;\n                vec2 param_37 = _1197.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_817 && _1049)\n            {\n                int param_42 = _813 + 6;\n                vec4 _1244 = fa_light_texel(param_42);\n                int param_43 = _813 + 7;\n                vec4 _1249 = fa_light_texel(param_43);\n                bool _1252 = _1244.z > 0.5;\n                bool _1259;\n                if (!_1252)\n                {\n                    _1259 = _1249.z > 0.5;\n                }\n                else\n                {\n                    _1259 = _1252;\n                }\n                if (_1259)\n                {\n                    int param_44 = _813 + 2;\n                    vec4 _1266 = fa_light_texel(param_44);\n                    vec3 _1270 = normalize(_1266.xyz);\n                    int param_45 = _813 + 4;\n                    vec4 _1275 = fa_light_texel(param_45);\n                    int param_46 = _813 + 5;\n                    vec4 _1280 = fa_light_texel(param_46);\n                    if (_1252)\n                    {\n                        vec3 _1288 = -to_light;\n                        float _1295 = _1266.w;\n                        float _1311 = 0.5 / max(dot(_1288, _1270) * (sqrt(max(1.0 - (_1295 * _1295), 0.0)) / max(_1295, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1244.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1288, _1275.xyz) * _1311), 0.5 - (dot(_1288, _1280.xyz) * _1311));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1249.z > 0.5)\n                    {\n                        vec2 param_49 = _1249.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1270;\n                        vec3 param_52 = _1275.xyz;\n                        vec3 param_53 = _1280.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5807 = _826.xyz * atten;\n    if (_817)\n    {\n        _5807 *= fa_light_tint;\n    }\n    int _1380;\n    if (_843)\n    {\n        _1380 = 0;\n    }\n    else\n    {\n        _1380 = ((_829 > 1.5) && (_829 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5807, atten, 1.0, dist, _1380);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4891 = n < 0;\n    bool _4898;\n    if (!_4891)\n    {\n        _4898 = n >= fa_light_count();\n    }\n    else\n    {\n        _4898 = _4891;\n    }\n    if (_4898)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4906 = fa_cl_light(param);\n    int param_1 = _4906;\n    float _4910 = fa_baked_keep(param_1);\n    if (_4910 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4906;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _4926 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_4926.direction, _4926.color * _4910, _4926.attenuation * _4910, _4926.shadow, _4926._distance, _4926.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2117;\n    if (i == 0)\n    {\n        _2117 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2133;\n        if (i == 1)\n        {\n            _2133 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2141;\n            if (i == 2)\n            {\n                _2141 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2141 = fa_shadows[24].w;\n            }\n            _2133 = _2141;\n        }\n        _2117 = _2133;\n    }\n    return _2117;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2174 = fa_shadow_depth(param, param_1);\n    float _2178;\n    if (conv.x < 0.5)\n    {\n        _2178 = _2174;\n    }\n    else\n    {\n        _2178 = (conv.y * conv.z) / (conv.z - (_2174 * (conv.z - conv.y)));\n    }\n    return _2178;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2105 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2105), sin(_2105)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2224 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2253 = clamp((_2233 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2224;\n            vec2 _2272 = fa_shadow_vogel(param_3, param_4, param_5) * _2253;\n            vec2 param_6 = uv + (_2272 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2284 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2284 < (zr - (length(_2272) * plane)))\n            {\n                sum += _2284;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2310 = sum / cnt;\n        float _2320;\n        if (k < 0.0)\n        {\n            _2320 = (-k) / max(_2310, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2320 = k;\n        }\n        radius = clamp(((max(zr - _2310, 0.0) * unit) * _2320) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2342 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2342; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2342;\n        float param_11 = _2224;\n        vec2 _2361 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2361 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2361) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2342);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2403 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2408 = clamp(dot(n, l), 0.0, 1.0);\n    float _2414 = sqrt(1.0 - (_2408 * _2408));\n    float _2421 = min(_2414 / max(_2408, 0.20000000298023223876953125), 4.0);\n    float _2426;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2426 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2426 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2451 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2426 * _2414)), 1.0);\n    float _2458 = _2451.x;\n    bool _2461 = _2458 < fa_shadows[ci * 1 + 16].x;\n    bool _2470;\n    if (!_2461)\n    {\n        _2470 = _2458 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2470 = _2461;\n    }\n    bool _2479;\n    if (!_2470)\n    {\n        _2479 = _2451.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2479 = _2470;\n    }\n    bool _2488;\n    if (!_2479)\n    {\n        _2488 = _2451.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2488 = _2479;\n    }\n    bool _2495;\n    if (!_2488)\n    {\n        _2495 = _2451.z > 1.0;\n    }\n    else\n    {\n        _2495 = _2488;\n    }\n    if (_2495)\n    {\n        return -1.0;\n    }\n    float _2503;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2503 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2503 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2451.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2451.z - ((_2503 * (1.0 + (0.5 * _2421))) / _2403);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2403;\n    float param_5 = _2403 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2421, 3.0)) * 0.5) / _2403;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2881 = int(fa_shadows[25].x + 0.5);\n    if (_2881 < 1)\n    {\n        return 1.0;\n    }\n    float _2896 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2881 - 1;\n    if (_2896 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2908 = _2881 > 1;\n    bool _2915;\n    if (_2908)\n    {\n        _2915 = _2896 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2915 = _2908;\n    }\n    if (_2915)\n    {\n        ci = 1;\n    }\n    bool _2919 = _2881 > 2;\n    bool _2926;\n    if (_2919)\n    {\n        _2926 = _2896 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2926 = _2919;\n    }\n    if (_2926)\n    {\n        ci = 2;\n    }\n    bool _2930 = _2881 > 3;\n    bool _2937;\n    if (_2930)\n    {\n        _2937 = _2896 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2937 = _2930;\n    }\n    if (_2937)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2881)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2963 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2963;\n        if (_2963 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2988;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2988 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2988 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3007 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2988, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3018 = clamp((_2896 - (fa_shadow_split_at(param_7) - _3007)) / _3007, 0.0, 1.0);\n        if (_3018 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2881)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3039 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3039;\n                if (_3039 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3018);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2561 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2568;\n    if (!_2561)\n    {\n        _2568 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2568 = _2561;\n    }\n    if (_2568)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2581 = fa_light_texel(param);\n    float _2582 = _2581.x;\n    if (_2582 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2591 = int(_2582 + 0.5);\n    int param_1 = _2591;\n    vec4 _2595 = fa_light_texel(param_1);\n    int param_2 = _2591 + 1;\n    vec4 _2600 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2603 = _2595.y;\n    if (_2603 > 0.0)\n    {\n        float _2620 = 1.0 - smoothstep(0.75 * _2603, _2603, length(world - fa_shadows[27].xyz));\n        fade = _2620;\n        if (_2620 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2595.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2644 = (_2591 + 2) + (face * 6);\n    int param_4 = _2644;\n    int param_5 = _2644 + 1;\n    int param_6 = _2644 + 3;\n    vec4 _2658 = fa_light_texel(param_6);\n    int param_7 = _2644 + 4;\n    vec4 _2663 = fa_light_texel(param_7);\n    int param_8 = _2644 + 5;\n    vec4 _2668 = fa_light_texel(param_8);\n    float _2680 = _2668.x * max(dot(_2658, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2685 = clamp(dot(n, l), 0.0, 1.0);\n    float _2708 = clamp(dot(n, _2658.xyz), -1.0, 1.0);\n    float _2727 = min(sqrt(1.0 - (_2708 * _2708)) / max(abs(dot(n, world - lpos)) / max(dot(_2658, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2730 = _2600.y;\n    float _2732;\n    if (_2730 > 0.0)\n    {\n        _2732 = _2730;\n    }\n    else\n    {\n        _2732 = 1.5 * _2680;\n    }\n    vec4 _2752 = vec4(world + (n * (_2732 * sqrt(1.0 - (_2685 * _2685)))), 1.0);\n    float _2756 = dot(_2658, _2752);\n    float _2759 = _2668.y;\n    if (_2756 < _2759)\n    {\n        return 1.0;\n    }\n    vec2 _2774 = vec2(dot(fa_light_texel(param_4), _2752), dot(fa_light_texel(param_5), _2752)) / vec2(_2756);\n    float _2776 = _2774.x;\n    bool _2779 = _2776 < _2663.x;\n    bool _2788;\n    if (!_2779)\n    {\n        _2788 = _2776 > _2663.z;\n    }\n    else\n    {\n        _2788 = _2779;\n    }\n    bool _2797;\n    if (!_2788)\n    {\n        _2797 = _2774.y < _2663.y;\n    }\n    else\n    {\n        _2797 = _2788;\n    }\n    bool _2806;\n    if (!_2797)\n    {\n        _2806 = _2774.y > _2663.w;\n    }\n    else\n    {\n        _2806 = _2797;\n    }\n    if (_2806)\n    {\n        return 1.0;\n    }\n    float _2812 = _2600.x;\n    float _2814;\n    if (_2812 > 0.0)\n    {\n        _2814 = _2812;\n    }\n    else\n    {\n        _2814 = 1.5 * _2680;\n    }\n    vec2 param_9 = _2774;\n    vec4 param_10 = _2663;\n    float param_11 = _2756 - (_2814 * (1.0 + (0.5 * _2727)));\n    float param_12 = _2680;\n    float param_13 = 1.0;\n    float param_14 = _2668.z * 0.25;\n    float param_15 = (_2680 * min(_2727, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2759, _2668.z);\n    int param_17 = int(_2595.z + 0.5);\n    float param_18 = _2595.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4406 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4413;\n    if (!_4406)\n    {\n        _4413 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4413 = _4406;\n    }\n    if (_4413)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4426 = fa_light_texel(param);\n    float _4427 = _4426.y;\n    float len = _4427;\n    if (_4427 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4439 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4449 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4439);\n    if (_4449 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4455 = len;\n    float _4458 = min(_4455, 0.89999997615814208984375 * dist);\n    len = _4458;\n    float _4463 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4439);\n    float _4468 = _4463 + (0.5 * _4458);\n    vec3 _4474 = world + (gn * _4463);\n    float _4476 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4540;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4491 = (float(k) + _4476) * 0.083333335816860198974609375;\n        vec3 _4499 = _4474 + (l * (_4491 * len));\n        vec4 _4505 = vec4(_4499, 1.0);\n        float _4511 = dot(fa_mesh_fs_params[28], _4505);\n        if (_4511 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4531 = vec2(dot(fa_mesh_fs_params[26], _4505), dot(fa_mesh_fs_params[27], _4505)) / vec2(_4511);\n        float _4535 = _4531.x * 0.5;\n        float _4536 = _4535 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4540 = (_4531.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4540 = 0.5 - (_4531.y * 0.5);\n        }\n        bool _4556 = _4536 < 0.0;\n        bool _4563;\n        if (!_4556)\n        {\n            _4563 = _4536 >= 1.0;\n        }\n        else\n        {\n            _4563 = _4556;\n        }\n        bool _4570;\n        if (!_4563)\n        {\n            _4570 = _4540 < 0.0;\n        }\n        else\n        {\n            _4570 = _4563;\n        }\n        bool _4577;\n        if (!_4570)\n        {\n            _4577 = _4540 >= 1.0;\n        }\n        else\n        {\n            _4577 = _4570;\n        }\n        if (_4577)\n        {\n            break;\n        }\n        vec4 _4596 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4536, _4540) * fa_mesh_fs_params[24].zw), 0);\n        if (_4596.w < 0.5)\n        {\n            continue;\n        }\n        float _4615 = (dot(fa_mesh_fs_params[29].xyz, _4499) + fa_mesh_fs_params[29].w) - _4596.x;\n        if ((_4615 > _4463) && (_4615 < _4468))\n        {\n            occ = max(occ, (1.0 - (_4491 * _4491)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4536, 0.5 - _4535), min(_4540, 1.0 - _4540))));\n        }\n    }\n    return 1.0 - (occ * _4449);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4718 = fa_baked_keep(param);\n    if (_4718 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4744 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5953 = _4744.color;\n    float _5954 = _4744.attenuation;\n    float _5955 = _4744.shadow;\n    bool _4747 = _4744.type == 0;\n    if (_4747 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4744.direction;\n        float _4758 = fa_shadow_factor(param_5, param_6);\n        _5955 = _4758;\n        _5953 *= _4758;\n    }\n    else\n    {\n        bool _4769 = _4744.type != 0;\n        bool _4775;\n        if (_4769)\n        {\n            _4775 = _5954 > 0.0;\n        }\n        else\n        {\n            _4775 = _4769;\n        }\n        if (_4775)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4744.direction;\n            float _4794 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5955 = _4794;\n            _5953 *= _4794;\n        }\n    }\n    bool _4804 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4810;\n    if (_4804)\n    {\n        _4810 = _5954 > 0.0;\n    }\n    else\n    {\n        _4810 = _4804;\n    }\n    if (_4810)\n    {\n        float _4817;\n        if (_4747)\n        {\n            _4817 = 1000000000.0;\n        }\n        else\n        {\n            _4817 = _4744._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4744.direction;\n        float param_18 = _4817;\n        float _4835 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5955 *= _4835;\n        _5953 *= _4835;\n    }\n    float _4848 = _5954;\n    float _4849 = _4848 * _4718;\n    _5954 = _4849;\n    vec3 _4853 = _5953;\n    vec3 _4854 = _4853 * _4718;\n    _5953 = _4854;\n    return LightSample(_4744.direction, _4854, _4849, _5955, _4744._distance, _4744.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4865 = n < 0;\n    bool _4872;\n    if (!_4865)\n    {\n        _4872 = n >= fa_light_count();\n    }\n    else\n    {\n        _4872 = _4865;\n    }\n    if (_4872)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _4887 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4887;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3797 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3805 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3808 = int(_3797);\n    int _3811 = int(_3805);\n    float _3821 = _3805 - float(_3811);\n    int _3877 = (_3808 * 9) + _3811;\n    int _3897 = ((_3808 + 1) * 9) + _3811;\n    return mix(mix(_3872[_3877], _3872[_3877 + 1], _3821), mix(_3872[_3897], _3872[_3897 + 1], _3821), _3797 - float(_3808));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5819 = false;\n    float _5820 = 1.0;\n    float _5821 = 1.0;\n    float _5822 = 1.0;\n    float _5823 = 0.0;\n    float _5824 = 0.0;\n    float _5825 = 0.0;\n    float _5826 = 0.0;\n    float _5828 = 1.0;\n    bool _5829 = false;\n    vec3 _5830 = vec3(0.0);\n    float _5831 = 1.0;\n    float _5832 = 1.0;\n    float _5833 = 1.0;\n    float _5834 = 0.0;\n    float _5835 = 0.0;\n    vec3 _5836 = vec3(1.0, 0.0, 0.0);\n    vec3 _5837 = vec3(0.0, 0.0, 1.0);\n    float _5838 = 1.0;\n    float _5839 = 1.0;\n    float _3948 = clamp(s.specular, 0.0, 1.0);\n    float _3952 = clamp(s.ior, 1.0, 3.0);\n    bool _3957 = (_3948 != 1.0) || (_3952 != 1.5);\n    bool _3966;\n    if (!_3957)\n    {\n        _3966 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3966 = _3957;\n    }\n    if (_3966)\n    {\n        float _3974 = (_3952 - 1.0) / (_3952 + 1.0);\n        f0 = mix(min(vec3(_3974 * _3974) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3948, s.albedo, vec3(metallic));\n        _5820 = mix(_3948, 1.0, metallic);\n        _5819 = true;\n    }\n    float _4001 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4001 > 0.0)\n    {\n        float _4009 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5823 = _4001;\n        _5824 = _4009;\n        float _4016 = _4009 * _4009;\n        _5825 = _4016;\n        _5826 = _4016 * _4016;\n        float _4028 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5828 = _4028;\n        _5821 = 1.0 - (_4001 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4028, 0.0, 1.0), 5.0))));\n        _5819 = true;\n    }\n    vec3 _4047 = max(s.sheen_color, vec3(0.0));\n    float _4056 = max(_4047.x, max(_4047.y, _4047.z));\n    if (_4056 > 0.0)\n    {\n        float _4064 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5829 = true;\n        _5830 = _4047;\n        _5831 = _4064;\n        _5832 = _4064 * _4064;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4064;\n        float _4081 = fa_sheen_albedo(param, param_1);\n        _5834 = _4081;\n        _5833 = 1.0 - min(_4056 * _4081, 1.0);\n        _5819 = true;\n    }\n    _5822 = _5821 * _5833;\n    float _4100 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4100 != 0.0)\n    {\n        vec3 _4115 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4115;\n        if (dot(_4115, _4115) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4127 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4127.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4127.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4127.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4131 = t;\n        vec3 _4132 = normalize(_4131);\n        t = _4132;\n        vec3 _4157 = normalize((_4132 * cos(s.anisotropy_rotation)) + ((cross(n, _4132) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5836 = _4157;\n        _5837 = cross(n, _4157);\n        float _4167 = roughness * roughness;\n        float _4173 = mix(_4167, 1.0, _4100 * _4100);\n        bool _4175 = _4100 > 0.0;\n        _5838 = _4175 ? _4173 : _4167;\n        _5839 = _4175 ? _4167 : _4173;\n        _5835 = _4100;\n        _5819 = true;\n    }\n    return FaLayers(_5819, _5820, _5821, _5822, _5823, _5824, _5825, _5826, i.world_normal, _5828, _5829, _5830, _5831, _5832, _5833, _5834, _5835, _5836, _5837, _5838, _5839);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3729 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3732 = _3729.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3732 * _3732, exp2((-9.27999973297119140625) * ndv)) * _3732) + _3729.y)) + _3729.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3165 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3168 = _3165.x;\n    float _3170 = _3165.z;\n    vec2 e = vec2(_3168, _3170);\n    if (_3165.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3170)) * ((_3168 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3168)) * ((_3170 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3217;\n    if (lv == 0)\n    {\n        _3217 = 0.0;\n    }\n    else\n    {\n        _3217 = res + 2.0;\n    }\n    float _3227;\n    if (lv == 0)\n    {\n        _3227 = 0.0;\n    }\n    else\n    {\n        _3227 = (res - (res / float(1 << (lv - 1)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3217, _3227)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3272;\n    if (res > 64.5)\n    {\n        _3272 = 5.0;\n    }\n    else\n    {\n        _3272 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3287 = clamp(rough, 0.0, 1.0) * (_3272 - 1.0);\n    int _3294 = int(min(floor(_3287), _3272 - 2.0));\n    float _3299 = _3287 - float(_3294);\n    vec3 param = d;\n    vec2 _3303 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3294;\n    vec2 param_4 = _3303;\n    vec3 _3313 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3299 < 0.00200000009499490261077880859375)\n    {\n        return _3313;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3294 + 1;\n    vec2 param_8 = _3303;\n    return mix(_3313, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3299));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3351 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3358 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3365 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3371 = dot(bx.xyz, d);\n    float _3375 = dot(by.xyz, d);\n    float _3379 = dot(bz.xyz, d);\n    float _3385;\n    if (_3371 > 9.9999999747524270787835121154785e-07)\n    {\n        _3385 = (1.0 - _3351) / _3371;\n    }\n    else\n    {\n        float _3399;\n        if (_3371 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3399 = ((-1.0) - _3351) / _3371;\n        }\n        else\n        {\n            _3399 = 1000000015047466219876688855040.0;\n        }\n        _3385 = _3399;\n    }\n    float tx = _3385;\n    float _3416;\n    if (_3375 > 9.9999999747524270787835121154785e-07)\n    {\n        _3416 = (1.0 - _3358) / _3375;\n    }\n    else\n    {\n        float _3429;\n        if (_3375 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3429 = ((-1.0) - _3358) / _3375;\n        }\n        else\n        {\n            _3429 = 1000000015047466219876688855040.0;\n        }\n        _3416 = _3429;\n    }\n    float ty = _3416;\n    float _3445;\n    if (_3379 > 9.9999999747524270787835121154785e-07)\n    {\n        _3445 = (1.0 - _3365) / _3379;\n    }\n    else\n    {\n        float _3458;\n        if (_3379 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3458 = ((-1.0) - _3365) / _3379;\n        }\n        else\n        {\n            _3458 = 1000000015047466219876688855040.0;\n        }\n        _3445 = _3458;\n    }\n    float _3470 = tx;\n    float _3473 = (_3470 > 0.0) ? _3470 : 1000000015047466219876688855040.0;\n    tx = _3473;\n    float _3474 = ty;\n    float _3477 = (_3474 > 0.0) ? _3474 : 1000000015047466219876688855040.0;\n    ty = _3477;\n    float _3487 = min(_3473, min(_3477, (_3445 > 0.0) ? _3445 : 1000000015047466219876688855040.0));\n    if (_3487 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3503 = (fa_world_pos + (d * _3487)) - posw.xyz;\n    vec3 _3508;\n    if (dot(_3503, _3503) > 1.0000000133514319600180897396058e-10)\n    {\n        _3508 = normalize(_3503);\n    }\n    else\n    {\n        _3508 = d;\n    }\n    return _3508;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3554 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 outc = vec3(0.0);\n    if (_3554 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[39].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3584 = rough * rough;\n            float _3615 = 0.60000002384185791015625 * _3584;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3584)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3615, 0.0500000007450580596923828125 + _3615, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3584 * 0.60000002384185791015625));\n        }\n        outc = base * _3554;\n    }\n    if (fa_mesh_fs_params[40].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[40];\n        vec4 param_5 = fa_mesh_fs_params[41];\n        vec4 param_6 = fa_mesh_fs_params[42];\n        vec4 param_7 = fa_mesh_fs_params[43];\n        vec4 param_8 = fa_mesh_fs_params[44];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3674 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3674 * fa_mesh_fs_params[40].w);\n    }\n    if (fa_mesh_fs_params[45].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[45];\n        vec4 param_12 = fa_mesh_fs_params[46];\n        vec4 param_13 = fa_mesh_fs_params[47];\n        vec4 param_14 = fa_mesh_fs_params[48];\n        vec4 param_15 = fa_mesh_fs_params[49];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3706 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3706 * fa_mesh_fs_params[45].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4208;\n        if (L.aniso >= 0.0)\n        {\n            _4208 = L.b;\n        }\n        else\n        {\n            _4208 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4208, v), _4208), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4241 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4241.x) + (vec3(L.f90) * _4241.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4296 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4296.x) + _4296.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3771 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3771.x) + vec3(_3771.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4335 = clamp(s.metallic, 0.0, 1.0);\n    float _4339 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4346 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4335));\n    vec3 f0 = _4346;\n    vec3 _4350 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4350;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4335;\n    float param_5 = _4339;\n    vec3 param_6 = _4346;\n    FaLayers _4367 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4367.on)\n    {\n        FaLayers param_7 = _4367;\n        vec3 param_8 = _4350;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4339;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _4350;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _4339;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4957 = fa_light_unshadowed(param, param_1);\n        float _4965 = dot(_4957.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_4965 > bestPower)\n        {\n            bestPower = _4965;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4994 = fa_light(param_2, param_3);\n        float _5002;\n        if (dot(s.normal, _4994.direction) > 0.5)\n        {\n            _5002 = 1.0;\n        }\n        else\n        {\n            _5002 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _4994.color) * _5002);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3063 = int(fa_shadows[25].x + 0.5);\n    float _3073 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3078 = _3063 > 0;\n    bool _3087;\n    if (_3078)\n    {\n        int param = _3063 - 1;\n        _3087 = _3073 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3087 = _3078;\n    }\n    if (_3087)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3093 = _3063 > 1;\n        bool _3100;\n        if (_3093)\n        {\n            _3100 = _3073 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3100 = _3093;\n        }\n        if (_3100)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3106 = _3063 > 2;\n        bool _3113;\n        if (_3106)\n        {\n            _3113 = _3073 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3113 = _3106;\n        }\n        if (_3113)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3119 = _3063 > 3;\n        bool _3126;\n        if (_3119)\n        {\n            _3126 = _3073 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3126 = _3119;\n        }\n        if (_3126)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5693 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5693 = -_5693;\n    }\n    vec3 _5380 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5693, fa_world_tangent, fa_uv, fa_vertex_color, _5380, gl_FrontFacing);\n    Surface _5388 = fa_standard_surface(param_1);\n    vec3 _5724 = _5388.albedo;\n    float _5725 = _5388.alpha;\n    vec3 _5726 = _5388.normal;\n    float _5727 = _5388.metallic;\n    float _5728 = _5388.roughness;\n    float _5729 = _5388.occlusion;\n    vec3 _5730 = _5388.emission;\n    float _5731 = _5388.clearcoat;\n    float _5732 = _5388.clearcoat_roughness;\n    vec3 _5733 = _5388.sheen_color;\n    float _5734 = _5388.sheen_roughness;\n    float _5735 = _5388.anisotropy;\n    float _5736 = _5388.anisotropy_rotation;\n    float _5737 = _5388.specular;\n    float _5738 = _5388.ior;\n    vec3 _5739 = _5388.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5693, fa_world_tangent, fa_uv, fa_vertex_color, _5380, gl_FrontFacing);\n    Surface param_3 = _5388;\n    surface(param_2, param_3);\n    _5724 = param_3.albedo;\n    _5725 = param_3.alpha;\n    _5726 = param_3.normal;\n    _5727 = param_3.metallic;\n    _5728 = param_3.roughness;\n    _5729 = param_3.occlusion;\n    _5730 = param_3.emission;\n    _5731 = param_3.clearcoat;\n    _5732 = param_3.clearcoat_roughness;\n    _5733 = param_3.sheen_color;\n    _5734 = param_3.sheen_roughness;\n    _5735 = param_3.anisotropy;\n    _5736 = param_3.anisotropy_rotation;\n    _5737 = param_3.specular;\n    _5738 = param_3.ior;\n    _5739 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5693;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5724 = param_6;\n    _5726 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5724;\n    }\n    else\n    {\n        vec3 _5426 = _5726;\n        vec3 _5427 = normalize(_5426);\n        _5726 = _5427;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _5693, fa_world_tangent, fa_uv, fa_vertex_color, _5380, gl_FrontFacing);\n        Surface param_9 = Surface(_5724, _5725, _5427, _5727, _5728, _5729, _5730, _5731, _5732, _5733, _5734, _5735, _5736, _5737, _5738, _5739);\n        vec3 _5438 = lighting(param_8, param_9);\n        result = _5438;\n    }\n    vec3 _5442 = result;\n    vec3 _5443 = _5442 + _5730;\n    result = _5443;\n    vec3 param_10 = _5443;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5452 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5459;\n    if (!_5452)\n    {\n        _5459 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5459 = _5452;\n    }\n    if (_5459)\n    {\n        vec3 _5468 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5474 = dot(_5468, fa_mesh_fs_params[9].xyz);\n        bool _5478 = fa_mesh_fs_params[9].w > 0.5;\n        float _5479;\n        if (_5478)\n        {\n            _5479 = _5474;\n        }\n        else\n        {\n            _5479 = length(_5468);\n        }\n        float _5491 = _5479 - fa_mesh_fs_params[8].x;\n        if (_5491 > 0.0)\n        {\n            float _5500 = fa_mesh_fs_params[7].w * _5491;\n            float tau = _5500 * _5500;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5516;\n                if (_5478)\n                {\n                    _5516 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5474);\n                }\n                else\n                {\n                    _5516 = fa_mesh_fs_params[0].y;\n                }\n                float _5537 = mix(_5516, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5479, 0.0, 1.0));\n                float _5541 = fa_world_pos.y - _5537;\n                float _5546 = _5537 - fa_mesh_fs_params[8].z;\n                float _5551 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5554 = _5546 <= 0.0;\n                bool _5555 = !_5554;\n                bool _5561;\n                if (_5555)\n                {\n                    _5561 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5561 = _5554;\n                }\n                float _5562;\n                if (_5561)\n                {\n                    _5562 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5562 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5546, 80.0));\n                }\n                bool _5589;\n                if (_5555)\n                {\n                    _5589 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5589 = _5554;\n                }\n                float _5590;\n                if (_5589)\n                {\n                    _5590 = fa_mesh_fs_params[8].y * _5546;\n                }\n                else\n                {\n                    _5590 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5546, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5615 = _5551 <= 0.0;\n                bool _5622;\n                if (!_5615)\n                {\n                    _5622 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5622 = _5615;\n                }\n                float _5623;\n                if (_5622)\n                {\n                    _5623 = fa_mesh_fs_params[8].y * _5551;\n                }\n                else\n                {\n                    _5623 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5551, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5650;\n                if (abs(_5541) < 0.001000000047497451305389404296875)\n                {\n                    _5650 = _5562;\n                }\n                else\n                {\n                    _5650 = (_5623 - _5590) / _5541;\n                }\n                tau += (_5491 * max(_5650, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5725);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_469",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
            "inst_name": "_2127",
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
            "inst_name": "_5008",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[50];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _788 = base_t;\n    _788.x = _227.x;\n    _788.y = _227.y;\n    _788.z = _227.z;\n    base_t = _788;\n    vec4 _243 = (_788 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _751 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _796 = _281;\n        _796.x = _286.x;\n        _796.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _796;\n        _751 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _799 = mrt;\n    _799.x = _315.x;\n    _799.y = _315.y;\n    _799.z = _315.z;\n    mrt = _799;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _756 = fa_mesh_fs_params[20].x;\n    float _757 = fa_mesh_fs_params[20].y;\n    float _760 = fa_mesh_fs_params[20].z;\n    float _759 = fa_mesh_fs_params[21].w;\n    float _762 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _756 *= _357.y;\n            _757 *= _357.z;\n            _759 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _760 *= mrt.x;\n            _762 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _751, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _756, _757, fa_mesh_fs_params[21].xyz, _759, _760, fa_mesh_fs_params[20].w, _762, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _662 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _662 = -_662;\n    }\n    vec3 _521 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _536 = normalize(param_2.normal);\n    vec3 _551 = normalize(vec3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    vec2 e = _551.xy / vec2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[50];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _788 = base_t;\n    _788.x = _227.x;\n    _788.y = _227.y;\n    _788.z = _227.z;\n    base_t = _788;\n    vec4 _243 = (_788 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _751 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _796 = _281;\n        _796.x = _286.x;\n        _796.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _796;\n        _751 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _799 = mrt;\n    _799.x = _315.x;\n    _799.y = _315.y;\n    _799.z = _315.z;\n    mrt = _799;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _756 = fa_mesh_fs_params[20].x;\n    float _757 = fa_mesh_fs_params[20].y;\n    float _760 = fa_mesh_fs_params[20].z;\n    float _759 = fa_mesh_fs_params[21].w;\n    float _762 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _756 *= _357.y;\n            _757 *= _357.z;\n            _759 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _760 *= mrt.x;\n            _762 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _751, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _756, _757, fa_mesh_fs_params[21].xyz, _759, _760, fa_mesh_fs_params[20].w, _762, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _662 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _662 = -_662;\n    }\n    vec3 _521 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _536 = normalize(param_2.normal);\n    vec3 _551 = normalize(vec3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    vec2 e = _551.xy / vec2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
