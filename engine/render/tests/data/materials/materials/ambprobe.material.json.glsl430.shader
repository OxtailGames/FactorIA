{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "57cbd5df71b0000e548dcd5fbfe873bc15510a64a336f6248792368f21adbf33",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[50];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1329 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1336;\n    if (!_1329)\n    {\n        _1336 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1336 = _1329;\n    }\n    bool _1344;\n    if (!_1336)\n    {\n        _1344 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1344 = _1336;\n    }\n    bool _1351;\n    if (!_1344)\n    {\n        _1351 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1351 = _1344;\n    }\n    bool _1358;\n    if (!_1351)\n    {\n        _1358 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1358 = _1351;\n    }\n    if (_1358)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1368 = vec4(world_pos, 1.0);\n    float _1374 = dot(fa_mesh_fs_params[16], _1368);\n    if (!(_1374 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1396 = vec2(dot(fa_mesh_fs_params[14], _1368), dot(fa_mesh_fs_params[15], _1368)) / vec2(_1374);\n    int _1400 = int(fa_mesh_fs_params[18].x);\n    int _1404 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1404) + clamp(int(floor(((_1396.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1404 - 1)) * _1400)) + clamp(int(floor(((_1396.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1400 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1480 = fa_cluster_texel(param);\n    return ivec2(int(_1480.x), int(_1480.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3656 = fa_cluster_lookup(param);\n    fa_cl_slot = _3656.x;\n    fa_cl_local = _3656.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3864 = fa_linear_to_srgb(param);\n        c = _3864;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3872 = fa_srgb_to_linear(param_1);\n            c = _3872;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _283;\n    if (i.front_facing)\n    {\n        _283 = i.world_normal;\n    }\n    else\n    {\n        _283 = -i.world_normal;\n    }\n    vec3 _307 = normalize(i.world_tangent.xyz - (_283 * dot(_283, i.world_tangent.xyz)));\n    vec3 _334 = normalize(((_307 * m.x) + ((cross(_283, _307) * i.world_tangent.w) * m.y)) + (_283 * m.z));\n    vec3 _337;\n    if (i.front_facing)\n    {\n        _337 = _334;\n    }\n    else\n    {\n        _337 = -_334;\n    }\n    return _337;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3903 = fa_tex_fix(param_2, param_3);\n    vec4 _4994 = base_t;\n    _4994.x = _3903.x;\n    _4994.y = _3903.y;\n    _4994.z = _3903.z;\n    base_t = _4994;\n    vec4 _3917 = (_4994 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4846 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3949 = fa_tex_fix(param_6, param_7);\n        vec3 _3952 = (_3949 * 2.0) - vec3(1.0);\n        vec2 _3957 = _3952.xy * fa_mesh_fs_params[6].x;\n        vec3 _5002 = _3952;\n        _5002.x = _3957.x;\n        _5002.y = _3957.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5002;\n        _4846 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3985 = fa_tex_fix(param_12, param_13);\n    vec4 _5005 = mrt;\n    _5005.x = _3985.x;\n    _5005.y = _3985.y;\n    _5005.z = _3985.z;\n    mrt = _5005;\n    vec4 _4013 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4013.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4024 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4054 = fa_tex_fix(param_20, param_21);\n    float _4851 = fa_mesh_fs_params[20].x;\n    float _4852 = fa_mesh_fs_params[20].y;\n    float _4855 = fa_mesh_fs_params[20].z;\n    float _4854 = fa_mesh_fs_params[21].w;\n    float _4857 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4851 *= _4024.y;\n            _4852 *= _4024.z;\n            _4854 *= _4013.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4855 *= mrt.x;\n            _4857 *= mrt.w;\n        }\n    }\n    return Surface(_3917.xyz, _3917.w, _4846, clamp(fa_mesh_fs_params[5].x * _3985.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3985.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4024.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4054), _4851, _4852, fa_mesh_fs_params[21].xyz, _4854, _4855, fa_mesh_fs_params[20].w, _4857, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1560 = rect.zw - rect.xy;\n    vec2 _1564 = _1560 * atlas;\n    vec2 _1568 = ddx * _1564;\n    vec2 _1572 = ddy * _1564;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1560), clamp(0.5 * log2(max(max(dot(_1568, _1568), dot(_1572, _1572)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1605 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1612;\n    if (!_1605)\n    {\n        _1612 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1612 = _1605;\n    }\n    if (_1612)\n    {\n        return;\n    }\n    vec3 _1618 = dFdx(world_pos);\n    vec3 _1621 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1625 = fa_cluster_texel(param);\n    int _1629 = int(_1625.w);\n    if (_1629 < 1)\n    {\n        return;\n    }\n    int _1639 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1639;\n    vec4 _1643 = fa_light_texel(param_1);\n    vec2 _1646 = _1643.yz;\n    int _1650 = int(_1643.w);\n    int param_2 = _1639 + 1;\n    vec4 _1655 = fa_light_texel(param_2);\n    float _1656 = _1655.x;\n    int _1662 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1666 = int(_1625.z);\n    vec3 _1931;\n    for (int k = 0; k < _1629; k++)\n    {\n        int _1679 = _1666 + k;\n        int param_3 = _1650 + (_1679 >> 2);\n        int _1696 = (_1639 + 2) + (int(fa_light_texel(param_3)[_1679 & 3]) * 7);\n        int param_4 = _1696 + 6;\n        vec4 _1701 = fa_light_texel(param_4);\n        if (((int(_1701.w + 0.5) >> _1662) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1696;\n        vec4 _1716 = fa_light_texel(param_5);\n        int param_6 = _1696 + 1;\n        vec4 _1721 = fa_light_texel(param_6);\n        int param_7 = _1696 + 2;\n        vec4 _1726 = fa_light_texel(param_7);\n        vec3 _1729 = _1716.xyz;\n        float _1734 = dot(_1729, world_pos) + _1716.w;\n        vec3 _1736 = _1721.xyz;\n        float _1741 = dot(_1736, world_pos) + _1721.w;\n        vec3 _1743 = _1726.xyz;\n        float _1748 = dot(_1743, world_pos) + _1726.w;\n        bool _1753 = abs(_1734) > 0.5;\n        bool _1761;\n        if (!_1753)\n        {\n            _1761 = abs(_1741) > 0.5;\n        }\n        else\n        {\n            _1761 = _1753;\n        }\n        bool _1769;\n        if (!_1761)\n        {\n            _1769 = abs(_1748) > 0.5;\n        }\n        else\n        {\n            _1769 = _1761;\n        }\n        if (_1769)\n        {\n            continue;\n        }\n        float _1784 = clamp(dot(geo_normal, normalize(_1743)) * _1701.z, 0.0, 1.0);\n        if (_1784 <= 0.0)\n        {\n            continue;\n        }\n        float _1804 = (clamp((0.5 - abs(_1748)) * 10.0, 0.0, 1.0) * _1784) * _1701.x;\n        vec2 _1812 = vec2(_1734 + 0.5, 0.5 - _1741);\n        vec2 _1822 = vec2(dot(_1729, _1618), dot(_1736, _1618));\n        vec2 _1832 = vec2(dot(_1729, _1621), dot(_1736, _1621));\n        int param_8 = _1696 + 5;\n        vec4 _1837 = fa_light_texel(param_8);\n        int param_9 = _1696 + 3;\n        vec4 _1842 = fa_light_texel(param_9);\n        int param_10 = _1696 + 4;\n        vec4 _1847 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1837.xyz;\n        bool _1857 = _1842.z > _1842.x;\n        if (_1857)\n        {\n            vec4 param_11 = _1842;\n            vec2 param_12 = _1812;\n            vec2 param_13 = _1646;\n            vec2 param_14 = _1822;\n            vec2 param_15 = _1832;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1656 > 0.5) && (_1656 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1883 = fa_dc_to_linear(param_16);\n                vec4 _4926 = tx;\n                _4926.x = _1883.x;\n                _4926.y = _1883.y;\n                _4926.z = _1883.z;\n                tx = _4926;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1804 * tex_a) * _1837.w, 0.0, 1.0)));\n        if (_1847.z > _1847.x)\n        {\n            vec4 param_17 = _1847;\n            vec2 param_18 = _1812;\n            vec2 param_19 = _1646;\n            vec2 param_20 = _1822;\n            vec2 param_21 = _1832;\n            vec4 _1927 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1656 > 1.5)\n            {\n                vec3 param_22 = _1927.xyz;\n                vec3 _1937 = fa_dc_to_srgb(param_22);\n                _1931 = _1937;\n            }\n            else\n            {\n                _1931 = _1927.xyz;\n            }\n            vec3 _1946 = (_1931 * 2.0) - vec3(1.0);\n            vec2 _1951 = _1946.xy * _1701.y;\n            vec3 _1973 = (normalize(_1729) * _1951.x) + (normalize(_1736) * _1951.y);\n            vec3 _1976 = normalize(normal);\n            normal = normalize(mix(_1976, normalize((_1976 * max(_1946.z, 0.0500000007450580596923828125)) + (_1973 - (_1976 * dot(_1976, _1973)))), vec3(clamp(_1804 * (_1857 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[39].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3171 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3171;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3227 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 amb = vec3(0.0);\n    bool _3233 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3227 > 0.0005000000237487256526947021484375)\n    {\n        if (_3233)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[39].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3227;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3227;\n        }\n    }\n    bool _3286 = fa_mesh_fs_params[40].w > 0.0;\n    if (_3286)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[40].xy;\n            float param_4 = fa_mesh_fs_params[40].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[40].w);\n        }\n    }\n    bool _3317 = fa_mesh_fs_params[45].w > 0.0;\n    if (_3317)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[45].xy;\n            float param_7 = fa_mesh_fs_params[45].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[45].w);\n        }\n    }\n    if ((_3233 || _3286) || _3317)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return ambientColor;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3626;\n    if (fa_lm.z > 0.5)\n    {\n        _3626 = 0.0;\n    }\n    else\n    {\n        _3626 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _3637 = _3626 < 1.0;\n    bool _3643;\n    if (_3637)\n    {\n        int param = li;\n        _3643 = fa_light_baked(param);\n    }\n    else\n    {\n        _3643 = _3637;\n    }\n    return _3643 ? _3626 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _579 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _592 = (c - (ru * hx)) - p;\n        vec3 _598 = ru * (2.0 * hx);\n        float _604 = max(dot(_598, _598), 9.9999999392252902907785028219223e-09);\n        float _608 = dot(_592, _598);\n        float t = clamp((-_608) / _604, 0.0, 1.0);\n        if (_579)\n        {\n            float _623 = dot(r, _598);\n            float _629 = _604 - (_623 * _623);\n            if (abs(_629) > (9.9999997473787516355514526367188e-06 * _604))\n            {\n                t = clamp(((dot(r, _592) * _623) - _608) / _629, 0.0, 1.0);\n            }\n        }\n        return (p + _592) + (_598 * t);\n    }\n    vec3 q = p;\n    float _661 = dot(r, axis);\n    bool _669;\n    if (_579)\n    {\n        _669 = abs(_661) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _669 = _579;\n    }\n    if (_669)\n    {\n        float _679 = dot(c - p, axis) / _661;\n        if (_679 > 0.0)\n        {\n            q = p + (r * _679);\n        }\n    }\n    vec3 _692 = q - c;\n    vec2 xy = vec2(dot(_692, ru), dot(_692, uu));\n    if (shape > 0.5)\n    {\n        float _707 = length(xy);\n        if (_707 > hx)\n        {\n            xy *= (hx / _707);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _349 = abs(d);\n    float _351 = _349.x;\n    float _353 = _349.y;\n    bool _354 = _351 >= _353;\n    bool _362;\n    if (_354)\n    {\n        _362 = _351 >= _349.z;\n    }\n    else\n    {\n        _362 = _354;\n    }\n    int _363;\n    if (_362)\n    {\n        _363 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _378;\n        if (_353 >= _349.z)\n        {\n            _378 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _378 = (d.z > 0.0) ? 4 : 5;\n        }\n        _363 = _378;\n    }\n    return _363;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _499 = dot(d, right);\n    float _503 = dot(d, up);\n    float _514;\n    if (((_499 * _499) + (_503 * _503)) > 1.0000000133514319600180897396058e-10)\n    {\n        _514 = atan(_503, _499) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _514 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_514 - floor(_514)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _745 = fa_light_base(param);\n    bool _749 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _745;\n    vec4 _753 = fa_light_texel(param_1);\n    int param_2 = _745 + 1;\n    vec4 _758 = fa_light_texel(param_2);\n    float _761 = _758.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _773 = _749 && (_761 > 2.5);\n    fa_light_is_area = _773;\n    bool _775 = _761 < 0.5;\n    vec3 l;\n    if (_775)\n    {\n        l = normalize(_753.xyz);\n        if (_749)\n        {\n            int param_3 = _745 + 6;\n            vec4 _789 = fa_light_texel(param_3);\n            if (_789.z > 0.5)\n            {\n                int param_4 = _745 + 4;\n                vec4 _799 = fa_light_texel(param_4);\n                int param_5 = _745 + 5;\n                vec4 _804 = fa_light_texel(param_5);\n                vec2 param_6 = _789.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _799.xyz) * _799.w, (-dot(world_pos, _804.xyz)) * _804.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _834 = _753.xyz;\n        vec3 _836 = _834 - world_pos;\n        vec3 to_light = _836;\n        float _839 = length(_836);\n        float reach = _839;\n        bool front = true;\n        if (_773)\n        {\n            int param_8 = _745 + 7;\n            reach = max(_839 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _745 + 4;\n            vec4 _863 = fa_light_texel(param_9);\n            int param_10 = _745 + 5;\n            vec4 _868 = fa_light_texel(param_10);\n            int param_11 = _745 + 6;\n            vec4 _873 = fa_light_texel(param_11);\n            float _874 = _873.w;\n            int param_12 = _745 + 2;\n            vec3 _881 = normalize(fa_light_texel(param_12).xyz);\n            bool _883 = _874 > 1.5;\n            bool _891;\n            if (!_883)\n            {\n                _891 = dot(_881, to_light) < 0.0;\n            }\n            else\n            {\n                _891 = _883;\n            }\n            front = _891;\n            vec3 r = vec3(0.0);\n            vec3 _900 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _904 = dot(n, n) > 0.5;\n            bool _912;\n            if (_904)\n            {\n                _912 = dot(_900, _900) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _912 = _904;\n            }\n            if (_912)\n            {\n                r = reflect(-normalize(_900), normalize(n));\n            }\n            vec3 param_13 = _834;\n            vec3 param_14 = _881;\n            vec3 param_15 = _863.xyz;\n            vec3 param_16 = _868.xyz;\n            float param_17 = _863.w;\n            float param_18 = _868.w;\n            float param_19 = _874;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _948 = length(to_light);\n        dist = _948;\n        l = to_light / vec3(max(_948, 9.9999997473787516355514526367188e-05));\n        float _962 = reach / max(_753.w, 0.001000000047497451305389404296875);\n        float _968 = clamp(1.0 - (_962 * _962), 0.0, 1.0);\n        float _970;\n        if (front)\n        {\n            _970 = _968 * _968;\n        }\n        else\n        {\n            _970 = 0.0;\n        }\n        atten = _970;\n        bool _981 = _761 < 2.5;\n        if ((_761 > 1.5) && _981)\n        {\n            int param_22 = _745 + 2;\n            vec4 _989 = fa_light_texel(param_22);\n            float _999 = _989.w;\n            int param_23 = _745 + 3;\n            vec4 _1004 = fa_light_texel(param_23);\n            float _1005 = _1004.x;\n            float cos_inner = _1005;\n            if (_1005 > 1.5)\n            {\n                cos_inner = mix(_999, 1.0, 0.25);\n            }\n            atten *= smoothstep(_999, cos_inner, dot(-l, normalize(_989.xyz)));\n        }\n        if (_749 && (_761 < 1.5))\n        {\n            int param_24 = _745 + 6;\n            vec4 _1029 = fa_light_texel(param_24);\n            if (_1029.z > 0.5)\n            {\n                vec3 _1037 = -to_light;\n                int param_25 = _745 + 4;\n                int param_26 = _745 + 5;\n                vec3 _1051 = fa_light_texel(param_25).xyz;\n                vec3 _1055 = fa_light_texel(param_26).xyz;\n                vec3 _1064 = vec3(dot(_1037, _1051), dot(_1037, _1055), dot(_1037, cross(_1051, _1055)));\n                vec3 param_27 = _1064;\n                int _1068 = fa_cube_face(param_27);\n                int param_28 = _1068;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1095 = vec2(dot(_1064, cross(param_29, param_30)), dot(_1064, param_30)) / vec2(max(dot(_1064, param_29), 9.9999997473787516355514526367188e-05));\n                int _1099 = _1068 / 3;\n                vec2 param_31 = _1029.xy + (vec2(float(_1068 - (_1099 * 3)), float(_1099)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1095.x), 0.5 - (0.5 * _1095.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _745 + 7;\n            vec4 _1129 = fa_light_texel(param_33);\n            if (_1129.z > 0.5)\n            {\n                int param_34 = _745 + 2;\n                int param_35 = _745 + 4;\n                int param_36 = _745 + 5;\n                vec2 param_37 = _1129.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_749 && _981)\n            {\n                int param_42 = _745 + 6;\n                vec4 _1176 = fa_light_texel(param_42);\n                int param_43 = _745 + 7;\n                vec4 _1181 = fa_light_texel(param_43);\n                bool _1184 = _1176.z > 0.5;\n                bool _1191;\n                if (!_1184)\n                {\n                    _1191 = _1181.z > 0.5;\n                }\n                else\n                {\n                    _1191 = _1184;\n                }\n                if (_1191)\n                {\n                    int param_44 = _745 + 2;\n                    vec4 _1198 = fa_light_texel(param_44);\n                    vec3 _1202 = normalize(_1198.xyz);\n                    int param_45 = _745 + 4;\n                    vec4 _1207 = fa_light_texel(param_45);\n                    int param_46 = _745 + 5;\n                    vec4 _1212 = fa_light_texel(param_46);\n                    if (_1184)\n                    {\n                        vec3 _1220 = -to_light;\n                        float _1227 = _1198.w;\n                        float _1243 = 0.5 / max(dot(_1220, _1202) * (sqrt(max(1.0 - (_1227 * _1227), 0.0)) / max(_1227, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1176.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1220, _1207.xyz) * _1243), 0.5 - (dot(_1220, _1212.xyz) * _1243));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1181.z > 0.5)\n                    {\n                        vec2 param_49 = _1181.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1202;\n                        vec3 param_52 = _1207.xyz;\n                        vec3 param_53 = _1212.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4800 = _758.xyz * atten;\n    if (_749)\n    {\n        _4800 *= fa_light_tint;\n    }\n    int _1311;\n    if (_775)\n    {\n        _1311 = 0;\n    }\n    else\n    {\n        _1311 = ((_761 > 1.5) && (_761 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4800, atten, 1.0, dist, _1311);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2048;\n    if (i == 0)\n    {\n        _2048 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2064;\n        if (i == 1)\n        {\n            _2064 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2072;\n            if (i == 2)\n            {\n                _2072 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2072 = fa_shadows[24].w;\n            }\n            _2064 = _2072;\n        }\n        _2048 = _2064;\n    }\n    return _2048;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2105 = fa_shadow_depth(param, param_1);\n    float _2109;\n    if (conv.x < 0.5)\n    {\n        _2109 = _2105;\n    }\n    else\n    {\n        _2109 = (conv.y * conv.z) / (conv.z - (_2105 * (conv.z - conv.y)));\n    }\n    return _2109;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2036 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2036), sin(_2036)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2155 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2164;\n        if (k < 0.0)\n        {\n            _2164 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2164 = k;\n        }\n        float _2184 = clamp((_2164 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2155;\n            vec2 _2203 = fa_shadow_vogel(param_3, param_4, param_5) * _2184;\n            vec2 param_6 = uv + (_2203 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2215 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2215 < (zr - (length(_2203) * plane)))\n            {\n                sum += _2215;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2241 = sum / cnt;\n        float _2251;\n        if (k < 0.0)\n        {\n            _2251 = (-k) / max(_2241, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2251 = k;\n        }\n        radius = clamp(((max(zr - _2241, 0.0) * unit) * _2251) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2273 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2273; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2273;\n        float param_11 = _2155;\n        vec2 _2292 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2292 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2292) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2273);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2334 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2339 = clamp(dot(n, l), 0.0, 1.0);\n    float _2345 = sqrt(1.0 - (_2339 * _2339));\n    float _2352 = min(_2345 / max(_2339, 0.20000000298023223876953125), 4.0);\n    float _2357;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2357 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2357 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2382 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2357 * _2345)), 1.0);\n    float _2389 = _2382.x;\n    bool _2392 = _2389 < fa_shadows[ci * 1 + 16].x;\n    bool _2401;\n    if (!_2392)\n    {\n        _2401 = _2389 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2401 = _2392;\n    }\n    bool _2410;\n    if (!_2401)\n    {\n        _2410 = _2382.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2410 = _2401;\n    }\n    bool _2419;\n    if (!_2410)\n    {\n        _2419 = _2382.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2419 = _2410;\n    }\n    bool _2426;\n    if (!_2419)\n    {\n        _2426 = _2382.z > 1.0;\n    }\n    else\n    {\n        _2426 = _2419;\n    }\n    if (_2426)\n    {\n        return -1.0;\n    }\n    float _2434;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2434 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2434 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2382.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2382.z - ((_2434 * (1.0 + (0.5 * _2352))) / _2334);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2334;\n    float param_5 = _2334 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2352, 3.0)) * 0.5) / _2334;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2812 = int(fa_shadows[25].x + 0.5);\n    if (_2812 < 1)\n    {\n        return 1.0;\n    }\n    float _2827 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2812 - 1;\n    if (_2827 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2839 = _2812 > 1;\n    bool _2846;\n    if (_2839)\n    {\n        _2846 = _2827 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2846 = _2839;\n    }\n    if (_2846)\n    {\n        ci = 1;\n    }\n    bool _2850 = _2812 > 2;\n    bool _2857;\n    if (_2850)\n    {\n        _2857 = _2827 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2857 = _2850;\n    }\n    if (_2857)\n    {\n        ci = 2;\n    }\n    bool _2861 = _2812 > 3;\n    bool _2868;\n    if (_2861)\n    {\n        _2868 = _2827 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2868 = _2861;\n    }\n    if (_2868)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2812)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2894 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2894;\n        if (_2894 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2919;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2919 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2919 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2938 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2919, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2949 = clamp((_2827 - (fa_shadow_split_at(param_7) - _2938)) / _2938, 0.0, 1.0);\n        if (_2949 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2812)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2970 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2970;\n                if (_2970 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2949);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2492 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2499;\n    if (!_2492)\n    {\n        _2499 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2499 = _2492;\n    }\n    if (_2499)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2512 = fa_light_texel(param);\n    float _2513 = _2512.x;\n    if (_2513 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2522 = int(_2513 + 0.5);\n    int param_1 = _2522;\n    vec4 _2526 = fa_light_texel(param_1);\n    int param_2 = _2522 + 1;\n    vec4 _2531 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2534 = _2526.y;\n    if (_2534 > 0.0)\n    {\n        float _2551 = 1.0 - smoothstep(0.75 * _2534, _2534, length(world - fa_shadows[27].xyz));\n        fade = _2551;\n        if (_2551 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2526.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2575 = (_2522 + 2) + (face * 6);\n    int param_4 = _2575;\n    int param_5 = _2575 + 1;\n    int param_6 = _2575 + 3;\n    vec4 _2589 = fa_light_texel(param_6);\n    int param_7 = _2575 + 4;\n    vec4 _2594 = fa_light_texel(param_7);\n    int param_8 = _2575 + 5;\n    vec4 _2599 = fa_light_texel(param_8);\n    float _2611 = _2599.x * max(dot(_2589, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2616 = clamp(dot(n, l), 0.0, 1.0);\n    float _2639 = clamp(dot(n, _2589.xyz), -1.0, 1.0);\n    float _2658 = min(sqrt(1.0 - (_2639 * _2639)) / max(abs(dot(n, world - lpos)) / max(dot(_2589, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2661 = _2531.y;\n    float _2663;\n    if (_2661 > 0.0)\n    {\n        _2663 = _2661;\n    }\n    else\n    {\n        _2663 = 1.5 * _2611;\n    }\n    vec4 _2683 = vec4(world + (n * (_2663 * sqrt(1.0 - (_2616 * _2616)))), 1.0);\n    float _2687 = dot(_2589, _2683);\n    float _2690 = _2599.y;\n    if (_2687 < _2690)\n    {\n        return 1.0;\n    }\n    vec2 _2705 = vec2(dot(fa_light_texel(param_4), _2683), dot(fa_light_texel(param_5), _2683)) / vec2(_2687);\n    float _2707 = _2705.x;\n    bool _2710 = _2707 < _2594.x;\n    bool _2719;\n    if (!_2710)\n    {\n        _2719 = _2707 > _2594.z;\n    }\n    else\n    {\n        _2719 = _2710;\n    }\n    bool _2728;\n    if (!_2719)\n    {\n        _2728 = _2705.y < _2594.y;\n    }\n    else\n    {\n        _2728 = _2719;\n    }\n    bool _2737;\n    if (!_2728)\n    {\n        _2737 = _2705.y > _2594.w;\n    }\n    else\n    {\n        _2737 = _2728;\n    }\n    if (_2737)\n    {\n        return 1.0;\n    }\n    float _2743 = _2531.x;\n    float _2745;\n    if (_2743 > 0.0)\n    {\n        _2745 = _2743;\n    }\n    else\n    {\n        _2745 = 1.5 * _2611;\n    }\n    vec2 param_9 = _2705;\n    vec4 param_10 = _2594;\n    float param_11 = _2687 - (_2745 * (1.0 + (0.5 * _2658)));\n    float param_12 = _2611;\n    float param_13 = 1.0;\n    float param_14 = _2599.z * 0.25;\n    float param_15 = (_2611 * min(_2658, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2690, _2599.z);\n    int param_17 = int(_2526.z + 0.5);\n    float param_18 = _2526.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3368 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3375;\n    if (!_3368)\n    {\n        _3375 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3375 = _3368;\n    }\n    if (_3375)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3388 = fa_light_texel(param);\n    float _3389 = _3388.y;\n    float len = _3389;\n    if (_3389 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3401 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3411 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3401);\n    if (_3411 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3417 = len;\n    float _3420 = min(_3417, 0.89999997615814208984375 * dist);\n    len = _3420;\n    float _3426 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3401);\n    float _3431 = _3426 + (0.5 * _3420);\n    vec3 _3437 = world + (gn * _3426);\n    float _3439 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3504;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3455 = (float(k) + _3439) * 0.083333335816860198974609375;\n        vec3 _3463 = _3437 + (l * (_3455 * len));\n        vec4 _3469 = vec4(_3463, 1.0);\n        float _3475 = dot(fa_mesh_fs_params[28], _3469);\n        if (_3475 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3495 = vec2(dot(fa_mesh_fs_params[26], _3469), dot(fa_mesh_fs_params[27], _3469)) / vec2(_3475);\n        float _3499 = _3495.x * 0.5;\n        float _3500 = _3499 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3504 = (_3495.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3504 = 0.5 - (_3495.y * 0.5);\n        }\n        bool _3520 = _3500 < 0.0;\n        bool _3527;\n        if (!_3520)\n        {\n            _3527 = _3500 >= 1.0;\n        }\n        else\n        {\n            _3527 = _3520;\n        }\n        bool _3534;\n        if (!_3527)\n        {\n            _3534 = _3504 < 0.0;\n        }\n        else\n        {\n            _3534 = _3527;\n        }\n        bool _3541;\n        if (!_3534)\n        {\n            _3541 = _3504 >= 1.0;\n        }\n        else\n        {\n            _3541 = _3534;\n        }\n        if (_3541)\n        {\n            break;\n        }\n        vec4 _3560 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3500, _3504) * fa_mesh_fs_params[24].zw), 0);\n        if (_3560.w < 0.5)\n        {\n            continue;\n        }\n        float _3579 = (dot(fa_mesh_fs_params[29].xyz, _3463) + fa_mesh_fs_params[29].w) - _3560.x;\n        if ((_3579 > _3426) && (_3579 < _3431))\n        {\n            occ = max(occ, (1.0 - (_3455 * _3455)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3500, 0.5 - _3499), min(_3504, 1.0 - _3504))));\n        }\n    }\n    return 1.0 - (occ * _3411);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3682 = fa_baked_keep(param);\n    if (_3682 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3708 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4826 = _3708.color;\n    float _4827 = _3708.attenuation;\n    float _4828 = _3708.shadow;\n    bool _3711 = _3708.type == 0;\n    if (_3711 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3708.direction;\n        float _3722 = fa_shadow_factor(param_5, param_6);\n        _4828 = _3722;\n        _4826 *= _3722;\n    }\n    else\n    {\n        bool _3733 = _3708.type != 0;\n        bool _3739;\n        if (_3733)\n        {\n            _3739 = _4827 > 0.0;\n        }\n        else\n        {\n            _3739 = _3733;\n        }\n        if (_3739)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3708.direction;\n            float _3758 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4828 = _3758;\n            _4826 *= _3758;\n        }\n    }\n    bool _3768 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3774;\n    if (_3768)\n    {\n        _3774 = _4827 > 0.0;\n    }\n    else\n    {\n        _3774 = _3768;\n    }\n    if (_3774)\n    {\n        float _3781;\n        if (_3711)\n        {\n            _3781 = 1000000000.0;\n        }\n        else\n        {\n            _3781 = _3708._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3708.direction;\n        float param_18 = _3781;\n        float _3799 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4828 *= _3799;\n        _4826 *= _3799;\n    }\n    float _3812 = _4827;\n    float _3813 = _3812 * _3682;\n    _4827 = _3813;\n    vec3 _3817 = _4826;\n    vec3 _3818 = _3817 * _3682;\n    _4826 = _3818;\n    return LightSample(_3708.direction, _3818, _3813, _4828, _3708._distance, _3708.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2994 = int(fa_shadows[25].x + 0.5);\n    float _3004 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3009 = _2994 > 0;\n    bool _3018;\n    if (_3009)\n    {\n        int param = _2994 - 1;\n        _3018 = _3004 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3018 = _3009;\n    }\n    if (_3018)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3024 = _2994 > 1;\n        bool _3031;\n        if (_3024)\n        {\n            _3031 = _3004 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3031 = _3024;\n        }\n        if (_3031)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3037 = _2994 > 2;\n        bool _3044;\n        if (_3037)\n        {\n            _3044 = _3004 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3044 = _3037;\n        }\n        if (_3044)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3050 = _2994 > 3;\n        bool _3057;\n        if (_3050)\n        {\n            _3057 = _3004 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3057 = _3050;\n        }\n        if (_3057)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4642 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4642 = -_4642;\n    }\n    vec3 _4233 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4642, fa_world_tangent, fa_uv, fa_vertex_color, _4233, gl_FrontFacing);\n    Surface _4241 = fa_standard_surface(param_1);\n    vec3 _4681 = _4241.albedo;\n    float _4682 = _4241.alpha;\n    vec3 _4683 = _4241.normal;\n    float _4684 = _4241.metallic;\n    float _4685 = _4241.roughness;\n    float _4686 = _4241.occlusion;\n    vec3 _4687 = _4241.emission;\n    float _4688 = _4241.clearcoat;\n    float _4689 = _4241.clearcoat_roughness;\n    vec3 _4690 = _4241.sheen_color;\n    float _4691 = _4241.sheen_roughness;\n    float _4692 = _4241.anisotropy;\n    float _4693 = _4241.anisotropy_rotation;\n    float _4694 = _4241.specular;\n    float _4695 = _4241.ior;\n    vec3 _4696 = _4241.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4642, fa_world_tangent, fa_uv, fa_vertex_color, _4233, gl_FrontFacing);\n    Surface param_3 = _4241;\n    surface(param_2, param_3);\n    _4681 = param_3.albedo;\n    _4682 = param_3.alpha;\n    _4683 = param_3.normal;\n    _4684 = param_3.metallic;\n    _4685 = param_3.roughness;\n    _4686 = param_3.occlusion;\n    _4687 = param_3.emission;\n    _4688 = param_3.clearcoat;\n    _4689 = param_3.clearcoat_roughness;\n    _4690 = param_3.sheen_color;\n    _4691 = param_3.sheen_roughness;\n    _4692 = param_3.anisotropy;\n    _4693 = param_3.anisotropy_rotation;\n    _4694 = param_3.specular;\n    _4695 = param_3.ior;\n    _4696 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4642;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4681 = param_6;\n    _4683 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4681;\n    }\n    else\n    {\n        vec3 _4279 = _4683;\n        vec3 _4280 = normalize(_4279);\n        _4683 = _4280;\n        vec3 param_8 = _4280;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _4642, fa_world_tangent, fa_uv, fa_vertex_color, _4233, gl_FrontFacing);\n        Surface param_10 = Surface(_4681, _4682, _4683, _4684, _4685, _4686, _4687, _4688, _4689, _4690, _4691, _4692, _4693, _4694, _4695, _4696);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _4299 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4299; ln++)\n        {\n            int param_12 = ln;\n            int _4312 = fa_cl_light(param_12);\n            int param_13 = _4312;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _4312;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _4642;\n            LightSample _4328 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _4642, fa_world_tangent, fa_uv, fa_vertex_color, _4233, gl_FrontFacing);\n            Surface param_18 = Surface(_4681, _4682, _4683, _4684, _4685, _4686, _4687, _4688, _4689, _4690, _4691, _4692, _4693, _4694, _4695, _4696);\n            LightSample param_19 = _4328;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _4343 = result;\n    vec3 _4344 = _4343 + _4687;\n    result = _4344;\n    vec3 param_20 = _4344;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4353 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4360;\n    if (!_4353)\n    {\n        _4360 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4360 = _4353;\n    }\n    if (_4360)\n    {\n        vec3 _4369 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4375 = dot(_4369, fa_mesh_fs_params[9].xyz);\n        bool _4379 = fa_mesh_fs_params[9].w > 0.5;\n        float _4380;\n        if (_4379)\n        {\n            _4380 = _4375;\n        }\n        else\n        {\n            _4380 = length(_4369);\n        }\n        float _4392 = _4380 - fa_mesh_fs_params[8].x;\n        if (_4392 > 0.0)\n        {\n            float _4401 = fa_mesh_fs_params[7].w * _4392;\n            float tau = _4401 * _4401;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4417;\n                if (_4379)\n                {\n                    _4417 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4375);\n                }\n                else\n                {\n                    _4417 = fa_mesh_fs_params[0].y;\n                }\n                float _4438 = mix(_4417, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4380, 0.0, 1.0));\n                float _4442 = fa_world_pos.y - _4438;\n                float _4447 = _4438 - fa_mesh_fs_params[8].z;\n                float _4452 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4455 = _4447 <= 0.0;\n                bool _4456 = !_4455;\n                bool _4462;\n                if (_4456)\n                {\n                    _4462 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4462 = _4455;\n                }\n                float _4463;\n                if (_4462)\n                {\n                    _4463 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4463 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4447, 80.0));\n                }\n                bool _4490;\n                if (_4456)\n                {\n                    _4490 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4490 = _4455;\n                }\n                float _4491;\n                if (_4490)\n                {\n                    _4491 = fa_mesh_fs_params[8].y * _4447;\n                }\n                else\n                {\n                    _4491 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4447, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4516 = _4452 <= 0.0;\n                bool _4523;\n                if (!_4516)\n                {\n                    _4523 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4523 = _4516;\n                }\n                float _4524;\n                if (_4523)\n                {\n                    _4524 = fa_mesh_fs_params[8].y * _4452;\n                }\n                else\n                {\n                    _4524 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4452, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4551;\n                if (abs(_4442) < 0.001000000047497451305389404296875)\n                {\n                    _4551 = _4463;\n                }\n                else\n                {\n                    _4551 = (_4524 - _4491) / _4442;\n                }\n                tau += (_4392 * max(_4551, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4682);\n}\n\n",
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
            "inst_name": "_401",
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
            "inst_name": "_2058",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[50];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1329 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1336;\n    if (!_1329)\n    {\n        _1336 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1336 = _1329;\n    }\n    bool _1344;\n    if (!_1336)\n    {\n        _1344 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1344 = _1336;\n    }\n    bool _1351;\n    if (!_1344)\n    {\n        _1351 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1351 = _1344;\n    }\n    bool _1358;\n    if (!_1351)\n    {\n        _1358 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1358 = _1351;\n    }\n    if (_1358)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1368 = vec4(world_pos, 1.0);\n    float _1374 = dot(fa_mesh_fs_params[16], _1368);\n    if (!(_1374 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1396 = vec2(dot(fa_mesh_fs_params[14], _1368), dot(fa_mesh_fs_params[15], _1368)) / vec2(_1374);\n    int _1400 = int(fa_mesh_fs_params[18].x);\n    int _1404 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1404) + clamp(int(floor(((_1396.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1404 - 1)) * _1400)) + clamp(int(floor(((_1396.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1400 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1480 = fa_cluster_texel(param);\n    return ivec2(int(_1480.x), int(_1480.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3656 = fa_cluster_lookup(param);\n    fa_cl_slot = _3656.x;\n    fa_cl_local = _3656.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3864 = fa_linear_to_srgb(param);\n        c = _3864;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3872 = fa_srgb_to_linear(param_1);\n            c = _3872;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _283;\n    if (i.front_facing)\n    {\n        _283 = i.world_normal;\n    }\n    else\n    {\n        _283 = -i.world_normal;\n    }\n    vec3 _307 = normalize(i.world_tangent.xyz - (_283 * dot(_283, i.world_tangent.xyz)));\n    vec3 _334 = normalize(((_307 * m.x) + ((cross(_283, _307) * i.world_tangent.w) * m.y)) + (_283 * m.z));\n    vec3 _337;\n    if (i.front_facing)\n    {\n        _337 = _334;\n    }\n    else\n    {\n        _337 = -_334;\n    }\n    return _337;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3903 = fa_tex_fix(param_2, param_3);\n    vec4 _4994 = base_t;\n    _4994.x = _3903.x;\n    _4994.y = _3903.y;\n    _4994.z = _3903.z;\n    base_t = _4994;\n    vec4 _3917 = (_4994 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4846 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3949 = fa_tex_fix(param_6, param_7);\n        vec3 _3952 = (_3949 * 2.0) - vec3(1.0);\n        vec2 _3957 = _3952.xy * fa_mesh_fs_params[6].x;\n        vec3 _5002 = _3952;\n        _5002.x = _3957.x;\n        _5002.y = _3957.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5002;\n        _4846 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3985 = fa_tex_fix(param_12, param_13);\n    vec4 _5005 = mrt;\n    _5005.x = _3985.x;\n    _5005.y = _3985.y;\n    _5005.z = _3985.z;\n    mrt = _5005;\n    vec4 _4013 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4013.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4024 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4054 = fa_tex_fix(param_20, param_21);\n    float _4851 = fa_mesh_fs_params[20].x;\n    float _4852 = fa_mesh_fs_params[20].y;\n    float _4855 = fa_mesh_fs_params[20].z;\n    float _4854 = fa_mesh_fs_params[21].w;\n    float _4857 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4851 *= _4024.y;\n            _4852 *= _4024.z;\n            _4854 *= _4013.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4855 *= mrt.x;\n            _4857 *= mrt.w;\n        }\n    }\n    return Surface(_3917.xyz, _3917.w, _4846, clamp(fa_mesh_fs_params[5].x * _3985.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3985.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4024.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4054), _4851, _4852, fa_mesh_fs_params[21].xyz, _4854, _4855, fa_mesh_fs_params[20].w, _4857, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1560 = rect.zw - rect.xy;\n    vec2 _1564 = _1560 * atlas;\n    vec2 _1568 = ddx * _1564;\n    vec2 _1572 = ddy * _1564;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1560), clamp(0.5 * log2(max(max(dot(_1568, _1568), dot(_1572, _1572)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1605 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1612;\n    if (!_1605)\n    {\n        _1612 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1612 = _1605;\n    }\n    if (_1612)\n    {\n        return;\n    }\n    vec3 _1618 = dFdx(world_pos);\n    vec3 _1621 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1625 = fa_cluster_texel(param);\n    int _1629 = int(_1625.w);\n    if (_1629 < 1)\n    {\n        return;\n    }\n    int _1639 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1639;\n    vec4 _1643 = fa_light_texel(param_1);\n    vec2 _1646 = _1643.yz;\n    int _1650 = int(_1643.w);\n    int param_2 = _1639 + 1;\n    vec4 _1655 = fa_light_texel(param_2);\n    float _1656 = _1655.x;\n    int _1662 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1666 = int(_1625.z);\n    vec3 _1931;\n    for (int k = 0; k < _1629; k++)\n    {\n        int _1679 = _1666 + k;\n        int param_3 = _1650 + (_1679 >> 2);\n        int _1696 = (_1639 + 2) + (int(fa_light_texel(param_3)[_1679 & 3]) * 7);\n        int param_4 = _1696 + 6;\n        vec4 _1701 = fa_light_texel(param_4);\n        if (((int(_1701.w + 0.5) >> _1662) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1696;\n        vec4 _1716 = fa_light_texel(param_5);\n        int param_6 = _1696 + 1;\n        vec4 _1721 = fa_light_texel(param_6);\n        int param_7 = _1696 + 2;\n        vec4 _1726 = fa_light_texel(param_7);\n        vec3 _1729 = _1716.xyz;\n        float _1734 = dot(_1729, world_pos) + _1716.w;\n        vec3 _1736 = _1721.xyz;\n        float _1741 = dot(_1736, world_pos) + _1721.w;\n        vec3 _1743 = _1726.xyz;\n        float _1748 = dot(_1743, world_pos) + _1726.w;\n        bool _1753 = abs(_1734) > 0.5;\n        bool _1761;\n        if (!_1753)\n        {\n            _1761 = abs(_1741) > 0.5;\n        }\n        else\n        {\n            _1761 = _1753;\n        }\n        bool _1769;\n        if (!_1761)\n        {\n            _1769 = abs(_1748) > 0.5;\n        }\n        else\n        {\n            _1769 = _1761;\n        }\n        if (_1769)\n        {\n            continue;\n        }\n        float _1784 = clamp(dot(geo_normal, normalize(_1743)) * _1701.z, 0.0, 1.0);\n        if (_1784 <= 0.0)\n        {\n            continue;\n        }\n        float _1804 = (clamp((0.5 - abs(_1748)) * 10.0, 0.0, 1.0) * _1784) * _1701.x;\n        vec2 _1812 = vec2(_1734 + 0.5, 0.5 - _1741);\n        vec2 _1822 = vec2(dot(_1729, _1618), dot(_1736, _1618));\n        vec2 _1832 = vec2(dot(_1729, _1621), dot(_1736, _1621));\n        int param_8 = _1696 + 5;\n        vec4 _1837 = fa_light_texel(param_8);\n        int param_9 = _1696 + 3;\n        vec4 _1842 = fa_light_texel(param_9);\n        int param_10 = _1696 + 4;\n        vec4 _1847 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1837.xyz;\n        bool _1857 = _1842.z > _1842.x;\n        if (_1857)\n        {\n            vec4 param_11 = _1842;\n            vec2 param_12 = _1812;\n            vec2 param_13 = _1646;\n            vec2 param_14 = _1822;\n            vec2 param_15 = _1832;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1656 > 0.5) && (_1656 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1883 = fa_dc_to_linear(param_16);\n                vec4 _4926 = tx;\n                _4926.x = _1883.x;\n                _4926.y = _1883.y;\n                _4926.z = _1883.z;\n                tx = _4926;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1804 * tex_a) * _1837.w, 0.0, 1.0)));\n        if (_1847.z > _1847.x)\n        {\n            vec4 param_17 = _1847;\n            vec2 param_18 = _1812;\n            vec2 param_19 = _1646;\n            vec2 param_20 = _1822;\n            vec2 param_21 = _1832;\n            vec4 _1927 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1656 > 1.5)\n            {\n                vec3 param_22 = _1927.xyz;\n                vec3 _1937 = fa_dc_to_srgb(param_22);\n                _1931 = _1937;\n            }\n            else\n            {\n                _1931 = _1927.xyz;\n            }\n            vec3 _1946 = (_1931 * 2.0) - vec3(1.0);\n            vec2 _1951 = _1946.xy * _1701.y;\n            vec3 _1973 = (normalize(_1729) * _1951.x) + (normalize(_1736) * _1951.y);\n            vec3 _1976 = normalize(normal);\n            normal = normalize(mix(_1976, normalize((_1976 * max(_1946.z, 0.0500000007450580596923828125)) + (_1973 - (_1976 * dot(_1976, _1973)))), vec3(clamp(_1804 * (_1857 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[39].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3171 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3171;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3227 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 amb = vec3(0.0);\n    bool _3233 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3227 > 0.0005000000237487256526947021484375)\n    {\n        if (_3233)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[39].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3227;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3227;\n        }\n    }\n    bool _3286 = fa_mesh_fs_params[40].w > 0.0;\n    if (_3286)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[40].xy;\n            float param_4 = fa_mesh_fs_params[40].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[40].w);\n        }\n    }\n    bool _3317 = fa_mesh_fs_params[45].w > 0.0;\n    if (_3317)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[45].xy;\n            float param_7 = fa_mesh_fs_params[45].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[45].w);\n        }\n    }\n    if ((_3233 || _3286) || _3317)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return ambientColor;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3626;\n    if (fa_lm.z > 0.5)\n    {\n        _3626 = 0.0;\n    }\n    else\n    {\n        _3626 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _3637 = _3626 < 1.0;\n    bool _3643;\n    if (_3637)\n    {\n        int param = li;\n        _3643 = fa_light_baked(param);\n    }\n    else\n    {\n        _3643 = _3637;\n    }\n    return _3643 ? _3626 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _579 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _592 = (c - (ru * hx)) - p;\n        vec3 _598 = ru * (2.0 * hx);\n        float _604 = max(dot(_598, _598), 9.9999999392252902907785028219223e-09);\n        float _608 = dot(_592, _598);\n        float t = clamp((-_608) / _604, 0.0, 1.0);\n        if (_579)\n        {\n            float _623 = dot(r, _598);\n            float _629 = _604 - (_623 * _623);\n            if (abs(_629) > (9.9999997473787516355514526367188e-06 * _604))\n            {\n                t = clamp(((dot(r, _592) * _623) - _608) / _629, 0.0, 1.0);\n            }\n        }\n        return (p + _592) + (_598 * t);\n    }\n    vec3 q = p;\n    float _661 = dot(r, axis);\n    bool _669;\n    if (_579)\n    {\n        _669 = abs(_661) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _669 = _579;\n    }\n    if (_669)\n    {\n        float _679 = dot(c - p, axis) / _661;\n        if (_679 > 0.0)\n        {\n            q = p + (r * _679);\n        }\n    }\n    vec3 _692 = q - c;\n    vec2 xy = vec2(dot(_692, ru), dot(_692, uu));\n    if (shape > 0.5)\n    {\n        float _707 = length(xy);\n        if (_707 > hx)\n        {\n            xy *= (hx / _707);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _349 = abs(d);\n    float _351 = _349.x;\n    float _353 = _349.y;\n    bool _354 = _351 >= _353;\n    bool _362;\n    if (_354)\n    {\n        _362 = _351 >= _349.z;\n    }\n    else\n    {\n        _362 = _354;\n    }\n    int _363;\n    if (_362)\n    {\n        _363 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _378;\n        if (_353 >= _349.z)\n        {\n            _378 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _378 = (d.z > 0.0) ? 4 : 5;\n        }\n        _363 = _378;\n    }\n    return _363;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _499 = dot(d, right);\n    float _503 = dot(d, up);\n    float _514;\n    if (((_499 * _499) + (_503 * _503)) > 1.0000000133514319600180897396058e-10)\n    {\n        _514 = atan(_503, _499) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _514 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_514 - floor(_514)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _745 = fa_light_base(param);\n    bool _749 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _745;\n    vec4 _753 = fa_light_texel(param_1);\n    int param_2 = _745 + 1;\n    vec4 _758 = fa_light_texel(param_2);\n    float _761 = _758.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _773 = _749 && (_761 > 2.5);\n    fa_light_is_area = _773;\n    bool _775 = _761 < 0.5;\n    vec3 l;\n    if (_775)\n    {\n        l = normalize(_753.xyz);\n        if (_749)\n        {\n            int param_3 = _745 + 6;\n            vec4 _789 = fa_light_texel(param_3);\n            if (_789.z > 0.5)\n            {\n                int param_4 = _745 + 4;\n                vec4 _799 = fa_light_texel(param_4);\n                int param_5 = _745 + 5;\n                vec4 _804 = fa_light_texel(param_5);\n                vec2 param_6 = _789.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _799.xyz) * _799.w, (-dot(world_pos, _804.xyz)) * _804.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _834 = _753.xyz;\n        vec3 _836 = _834 - world_pos;\n        vec3 to_light = _836;\n        float _839 = length(_836);\n        float reach = _839;\n        bool front = true;\n        if (_773)\n        {\n            int param_8 = _745 + 7;\n            reach = max(_839 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _745 + 4;\n            vec4 _863 = fa_light_texel(param_9);\n            int param_10 = _745 + 5;\n            vec4 _868 = fa_light_texel(param_10);\n            int param_11 = _745 + 6;\n            vec4 _873 = fa_light_texel(param_11);\n            float _874 = _873.w;\n            int param_12 = _745 + 2;\n            vec3 _881 = normalize(fa_light_texel(param_12).xyz);\n            bool _883 = _874 > 1.5;\n            bool _891;\n            if (!_883)\n            {\n                _891 = dot(_881, to_light) < 0.0;\n            }\n            else\n            {\n                _891 = _883;\n            }\n            front = _891;\n            vec3 r = vec3(0.0);\n            vec3 _900 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _904 = dot(n, n) > 0.5;\n            bool _912;\n            if (_904)\n            {\n                _912 = dot(_900, _900) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _912 = _904;\n            }\n            if (_912)\n            {\n                r = reflect(-normalize(_900), normalize(n));\n            }\n            vec3 param_13 = _834;\n            vec3 param_14 = _881;\n            vec3 param_15 = _863.xyz;\n            vec3 param_16 = _868.xyz;\n            float param_17 = _863.w;\n            float param_18 = _868.w;\n            float param_19 = _874;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _948 = length(to_light);\n        dist = _948;\n        l = to_light / vec3(max(_948, 9.9999997473787516355514526367188e-05));\n        float _962 = reach / max(_753.w, 0.001000000047497451305389404296875);\n        float _968 = clamp(1.0 - (_962 * _962), 0.0, 1.0);\n        float _970;\n        if (front)\n        {\n            _970 = _968 * _968;\n        }\n        else\n        {\n            _970 = 0.0;\n        }\n        atten = _970;\n        bool _981 = _761 < 2.5;\n        if ((_761 > 1.5) && _981)\n        {\n            int param_22 = _745 + 2;\n            vec4 _989 = fa_light_texel(param_22);\n            float _999 = _989.w;\n            int param_23 = _745 + 3;\n            vec4 _1004 = fa_light_texel(param_23);\n            float _1005 = _1004.x;\n            float cos_inner = _1005;\n            if (_1005 > 1.5)\n            {\n                cos_inner = mix(_999, 1.0, 0.25);\n            }\n            atten *= smoothstep(_999, cos_inner, dot(-l, normalize(_989.xyz)));\n        }\n        if (_749 && (_761 < 1.5))\n        {\n            int param_24 = _745 + 6;\n            vec4 _1029 = fa_light_texel(param_24);\n            if (_1029.z > 0.5)\n            {\n                vec3 _1037 = -to_light;\n                int param_25 = _745 + 4;\n                int param_26 = _745 + 5;\n                vec3 _1051 = fa_light_texel(param_25).xyz;\n                vec3 _1055 = fa_light_texel(param_26).xyz;\n                vec3 _1064 = vec3(dot(_1037, _1051), dot(_1037, _1055), dot(_1037, cross(_1051, _1055)));\n                vec3 param_27 = _1064;\n                int _1068 = fa_cube_face(param_27);\n                int param_28 = _1068;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1095 = vec2(dot(_1064, cross(param_29, param_30)), dot(_1064, param_30)) / vec2(max(dot(_1064, param_29), 9.9999997473787516355514526367188e-05));\n                int _1099 = _1068 / 3;\n                vec2 param_31 = _1029.xy + (vec2(float(_1068 - (_1099 * 3)), float(_1099)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1095.x), 0.5 - (0.5 * _1095.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _745 + 7;\n            vec4 _1129 = fa_light_texel(param_33);\n            if (_1129.z > 0.5)\n            {\n                int param_34 = _745 + 2;\n                int param_35 = _745 + 4;\n                int param_36 = _745 + 5;\n                vec2 param_37 = _1129.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_749 && _981)\n            {\n                int param_42 = _745 + 6;\n                vec4 _1176 = fa_light_texel(param_42);\n                int param_43 = _745 + 7;\n                vec4 _1181 = fa_light_texel(param_43);\n                bool _1184 = _1176.z > 0.5;\n                bool _1191;\n                if (!_1184)\n                {\n                    _1191 = _1181.z > 0.5;\n                }\n                else\n                {\n                    _1191 = _1184;\n                }\n                if (_1191)\n                {\n                    int param_44 = _745 + 2;\n                    vec4 _1198 = fa_light_texel(param_44);\n                    vec3 _1202 = normalize(_1198.xyz);\n                    int param_45 = _745 + 4;\n                    vec4 _1207 = fa_light_texel(param_45);\n                    int param_46 = _745 + 5;\n                    vec4 _1212 = fa_light_texel(param_46);\n                    if (_1184)\n                    {\n                        vec3 _1220 = -to_light;\n                        float _1227 = _1198.w;\n                        float _1243 = 0.5 / max(dot(_1220, _1202) * (sqrt(max(1.0 - (_1227 * _1227), 0.0)) / max(_1227, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1176.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1220, _1207.xyz) * _1243), 0.5 - (dot(_1220, _1212.xyz) * _1243));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1181.z > 0.5)\n                    {\n                        vec2 param_49 = _1181.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1202;\n                        vec3 param_52 = _1207.xyz;\n                        vec3 param_53 = _1212.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4800 = _758.xyz * atten;\n    if (_749)\n    {\n        _4800 *= fa_light_tint;\n    }\n    int _1311;\n    if (_775)\n    {\n        _1311 = 0;\n    }\n    else\n    {\n        _1311 = ((_761 > 1.5) && (_761 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4800, atten, 1.0, dist, _1311);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2048;\n    if (i == 0)\n    {\n        _2048 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2064;\n        if (i == 1)\n        {\n            _2064 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2072;\n            if (i == 2)\n            {\n                _2072 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2072 = fa_shadows[24].w;\n            }\n            _2064 = _2072;\n        }\n        _2048 = _2064;\n    }\n    return _2048;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2105 = fa_shadow_depth(param, param_1);\n    float _2109;\n    if (conv.x < 0.5)\n    {\n        _2109 = _2105;\n    }\n    else\n    {\n        _2109 = (conv.y * conv.z) / (conv.z - (_2105 * (conv.z - conv.y)));\n    }\n    return _2109;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2036 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2036), sin(_2036)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2155 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2164;\n        if (k < 0.0)\n        {\n            _2164 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2164 = k;\n        }\n        float _2184 = clamp((_2164 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2155;\n            vec2 _2203 = fa_shadow_vogel(param_3, param_4, param_5) * _2184;\n            vec2 param_6 = uv + (_2203 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2215 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2215 < (zr - (length(_2203) * plane)))\n            {\n                sum += _2215;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2241 = sum / cnt;\n        float _2251;\n        if (k < 0.0)\n        {\n            _2251 = (-k) / max(_2241, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2251 = k;\n        }\n        radius = clamp(((max(zr - _2241, 0.0) * unit) * _2251) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2273 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2273; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2273;\n        float param_11 = _2155;\n        vec2 _2292 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2292 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2292) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2273);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2334 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2339 = clamp(dot(n, l), 0.0, 1.0);\n    float _2345 = sqrt(1.0 - (_2339 * _2339));\n    float _2352 = min(_2345 / max(_2339, 0.20000000298023223876953125), 4.0);\n    float _2357;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2357 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2357 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2382 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2357 * _2345)), 1.0);\n    float _2389 = _2382.x;\n    bool _2392 = _2389 < fa_shadows[ci * 1 + 16].x;\n    bool _2401;\n    if (!_2392)\n    {\n        _2401 = _2389 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2401 = _2392;\n    }\n    bool _2410;\n    if (!_2401)\n    {\n        _2410 = _2382.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2410 = _2401;\n    }\n    bool _2419;\n    if (!_2410)\n    {\n        _2419 = _2382.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2419 = _2410;\n    }\n    bool _2426;\n    if (!_2419)\n    {\n        _2426 = _2382.z > 1.0;\n    }\n    else\n    {\n        _2426 = _2419;\n    }\n    if (_2426)\n    {\n        return -1.0;\n    }\n    float _2434;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2434 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2434 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2382.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2382.z - ((_2434 * (1.0 + (0.5 * _2352))) / _2334);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2334;\n    float param_5 = _2334 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2352, 3.0)) * 0.5) / _2334;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2812 = int(fa_shadows[25].x + 0.5);\n    if (_2812 < 1)\n    {\n        return 1.0;\n    }\n    float _2827 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2812 - 1;\n    if (_2827 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2839 = _2812 > 1;\n    bool _2846;\n    if (_2839)\n    {\n        _2846 = _2827 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2846 = _2839;\n    }\n    if (_2846)\n    {\n        ci = 1;\n    }\n    bool _2850 = _2812 > 2;\n    bool _2857;\n    if (_2850)\n    {\n        _2857 = _2827 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2857 = _2850;\n    }\n    if (_2857)\n    {\n        ci = 2;\n    }\n    bool _2861 = _2812 > 3;\n    bool _2868;\n    if (_2861)\n    {\n        _2868 = _2827 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2868 = _2861;\n    }\n    if (_2868)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2812)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2894 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2894;\n        if (_2894 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2919;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2919 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2919 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2938 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2919, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2949 = clamp((_2827 - (fa_shadow_split_at(param_7) - _2938)) / _2938, 0.0, 1.0);\n        if (_2949 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2812)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2970 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2970;\n                if (_2970 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2949);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2492 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2499;\n    if (!_2492)\n    {\n        _2499 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2499 = _2492;\n    }\n    if (_2499)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2512 = fa_light_texel(param);\n    float _2513 = _2512.x;\n    if (_2513 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2522 = int(_2513 + 0.5);\n    int param_1 = _2522;\n    vec4 _2526 = fa_light_texel(param_1);\n    int param_2 = _2522 + 1;\n    vec4 _2531 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2534 = _2526.y;\n    if (_2534 > 0.0)\n    {\n        float _2551 = 1.0 - smoothstep(0.75 * _2534, _2534, length(world - fa_shadows[27].xyz));\n        fade = _2551;\n        if (_2551 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2526.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2575 = (_2522 + 2) + (face * 6);\n    int param_4 = _2575;\n    int param_5 = _2575 + 1;\n    int param_6 = _2575 + 3;\n    vec4 _2589 = fa_light_texel(param_6);\n    int param_7 = _2575 + 4;\n    vec4 _2594 = fa_light_texel(param_7);\n    int param_8 = _2575 + 5;\n    vec4 _2599 = fa_light_texel(param_8);\n    float _2611 = _2599.x * max(dot(_2589, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2616 = clamp(dot(n, l), 0.0, 1.0);\n    float _2639 = clamp(dot(n, _2589.xyz), -1.0, 1.0);\n    float _2658 = min(sqrt(1.0 - (_2639 * _2639)) / max(abs(dot(n, world - lpos)) / max(dot(_2589, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2661 = _2531.y;\n    float _2663;\n    if (_2661 > 0.0)\n    {\n        _2663 = _2661;\n    }\n    else\n    {\n        _2663 = 1.5 * _2611;\n    }\n    vec4 _2683 = vec4(world + (n * (_2663 * sqrt(1.0 - (_2616 * _2616)))), 1.0);\n    float _2687 = dot(_2589, _2683);\n    float _2690 = _2599.y;\n    if (_2687 < _2690)\n    {\n        return 1.0;\n    }\n    vec2 _2705 = vec2(dot(fa_light_texel(param_4), _2683), dot(fa_light_texel(param_5), _2683)) / vec2(_2687);\n    float _2707 = _2705.x;\n    bool _2710 = _2707 < _2594.x;\n    bool _2719;\n    if (!_2710)\n    {\n        _2719 = _2707 > _2594.z;\n    }\n    else\n    {\n        _2719 = _2710;\n    }\n    bool _2728;\n    if (!_2719)\n    {\n        _2728 = _2705.y < _2594.y;\n    }\n    else\n    {\n        _2728 = _2719;\n    }\n    bool _2737;\n    if (!_2728)\n    {\n        _2737 = _2705.y > _2594.w;\n    }\n    else\n    {\n        _2737 = _2728;\n    }\n    if (_2737)\n    {\n        return 1.0;\n    }\n    float _2743 = _2531.x;\n    float _2745;\n    if (_2743 > 0.0)\n    {\n        _2745 = _2743;\n    }\n    else\n    {\n        _2745 = 1.5 * _2611;\n    }\n    vec2 param_9 = _2705;\n    vec4 param_10 = _2594;\n    float param_11 = _2687 - (_2745 * (1.0 + (0.5 * _2658)));\n    float param_12 = _2611;\n    float param_13 = 1.0;\n    float param_14 = _2599.z * 0.25;\n    float param_15 = (_2611 * min(_2658, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2690, _2599.z);\n    int param_17 = int(_2526.z + 0.5);\n    float param_18 = _2526.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3368 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3375;\n    if (!_3368)\n    {\n        _3375 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3375 = _3368;\n    }\n    if (_3375)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3388 = fa_light_texel(param);\n    float _3389 = _3388.y;\n    float len = _3389;\n    if (_3389 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3401 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3411 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3401);\n    if (_3411 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3417 = len;\n    float _3420 = min(_3417, 0.89999997615814208984375 * dist);\n    len = _3420;\n    float _3426 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3401);\n    float _3431 = _3426 + (0.5 * _3420);\n    vec3 _3437 = world + (gn * _3426);\n    float _3439 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3504;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3455 = (float(k) + _3439) * 0.083333335816860198974609375;\n        vec3 _3463 = _3437 + (l * (_3455 * len));\n        vec4 _3469 = vec4(_3463, 1.0);\n        float _3475 = dot(fa_mesh_fs_params[28], _3469);\n        if (_3475 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3495 = vec2(dot(fa_mesh_fs_params[26], _3469), dot(fa_mesh_fs_params[27], _3469)) / vec2(_3475);\n        float _3499 = _3495.x * 0.5;\n        float _3500 = _3499 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3504 = (_3495.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3504 = 0.5 - (_3495.y * 0.5);\n        }\n        bool _3520 = _3500 < 0.0;\n        bool _3527;\n        if (!_3520)\n        {\n            _3527 = _3500 >= 1.0;\n        }\n        else\n        {\n            _3527 = _3520;\n        }\n        bool _3534;\n        if (!_3527)\n        {\n            _3534 = _3504 < 0.0;\n        }\n        else\n        {\n            _3534 = _3527;\n        }\n        bool _3541;\n        if (!_3534)\n        {\n            _3541 = _3504 >= 1.0;\n        }\n        else\n        {\n            _3541 = _3534;\n        }\n        if (_3541)\n        {\n            break;\n        }\n        vec4 _3560 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3500, _3504) * fa_mesh_fs_params[24].zw), 0);\n        if (_3560.w < 0.5)\n        {\n            continue;\n        }\n        float _3579 = (dot(fa_mesh_fs_params[29].xyz, _3463) + fa_mesh_fs_params[29].w) - _3560.x;\n        if ((_3579 > _3426) && (_3579 < _3431))\n        {\n            occ = max(occ, (1.0 - (_3455 * _3455)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3500, 0.5 - _3499), min(_3504, 1.0 - _3504))));\n        }\n    }\n    return 1.0 - (occ * _3411);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3682 = fa_baked_keep(param);\n    if (_3682 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3708 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4826 = _3708.color;\n    float _4827 = _3708.attenuation;\n    float _4828 = _3708.shadow;\n    bool _3711 = _3708.type == 0;\n    if (_3711 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3708.direction;\n        float _3722 = fa_shadow_factor(param_5, param_6);\n        _4828 = _3722;\n        _4826 *= _3722;\n    }\n    else\n    {\n        bool _3733 = _3708.type != 0;\n        bool _3739;\n        if (_3733)\n        {\n            _3739 = _4827 > 0.0;\n        }\n        else\n        {\n            _3739 = _3733;\n        }\n        if (_3739)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3708.direction;\n            float _3758 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4828 = _3758;\n            _4826 *= _3758;\n        }\n    }\n    bool _3768 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3774;\n    if (_3768)\n    {\n        _3774 = _4827 > 0.0;\n    }\n    else\n    {\n        _3774 = _3768;\n    }\n    if (_3774)\n    {\n        float _3781;\n        if (_3711)\n        {\n            _3781 = 1000000000.0;\n        }\n        else\n        {\n            _3781 = _3708._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3708.direction;\n        float param_18 = _3781;\n        float _3799 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4828 *= _3799;\n        _4826 *= _3799;\n    }\n    float _3812 = _4827;\n    float _3813 = _3812 * _3682;\n    _4827 = _3813;\n    vec3 _3817 = _4826;\n    vec3 _3818 = _3817 * _3682;\n    _4826 = _3818;\n    return LightSample(_3708.direction, _3818, _3813, _4828, _3708._distance, _3708.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2994 = int(fa_shadows[25].x + 0.5);\n    float _3004 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3009 = _2994 > 0;\n    bool _3018;\n    if (_3009)\n    {\n        int param = _2994 - 1;\n        _3018 = _3004 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3018 = _3009;\n    }\n    if (_3018)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3024 = _2994 > 1;\n        bool _3031;\n        if (_3024)\n        {\n            _3031 = _3004 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3031 = _3024;\n        }\n        if (_3031)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3037 = _2994 > 2;\n        bool _3044;\n        if (_3037)\n        {\n            _3044 = _3004 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3044 = _3037;\n        }\n        if (_3044)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3050 = _2994 > 3;\n        bool _3057;\n        if (_3050)\n        {\n            _3057 = _3004 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3057 = _3050;\n        }\n        if (_3057)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4642 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4642 = -_4642;\n    }\n    vec3 _4233 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4642, fa_world_tangent, fa_uv, fa_vertex_color, _4233, gl_FrontFacing);\n    Surface _4241 = fa_standard_surface(param_1);\n    vec3 _4681 = _4241.albedo;\n    float _4682 = _4241.alpha;\n    vec3 _4683 = _4241.normal;\n    float _4684 = _4241.metallic;\n    float _4685 = _4241.roughness;\n    float _4686 = _4241.occlusion;\n    vec3 _4687 = _4241.emission;\n    float _4688 = _4241.clearcoat;\n    float _4689 = _4241.clearcoat_roughness;\n    vec3 _4690 = _4241.sheen_color;\n    float _4691 = _4241.sheen_roughness;\n    float _4692 = _4241.anisotropy;\n    float _4693 = _4241.anisotropy_rotation;\n    float _4694 = _4241.specular;\n    float _4695 = _4241.ior;\n    vec3 _4696 = _4241.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4642, fa_world_tangent, fa_uv, fa_vertex_color, _4233, gl_FrontFacing);\n    Surface param_3 = _4241;\n    surface(param_2, param_3);\n    _4681 = param_3.albedo;\n    _4682 = param_3.alpha;\n    _4683 = param_3.normal;\n    _4684 = param_3.metallic;\n    _4685 = param_3.roughness;\n    _4686 = param_3.occlusion;\n    _4687 = param_3.emission;\n    _4688 = param_3.clearcoat;\n    _4689 = param_3.clearcoat_roughness;\n    _4690 = param_3.sheen_color;\n    _4691 = param_3.sheen_roughness;\n    _4692 = param_3.anisotropy;\n    _4693 = param_3.anisotropy_rotation;\n    _4694 = param_3.specular;\n    _4695 = param_3.ior;\n    _4696 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4642;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4681 = param_6;\n    _4683 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4681;\n    }\n    else\n    {\n        vec3 _4279 = _4683;\n        vec3 _4280 = normalize(_4279);\n        _4683 = _4280;\n        vec3 param_8 = _4280;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _4642, fa_world_tangent, fa_uv, fa_vertex_color, _4233, gl_FrontFacing);\n        Surface param_10 = Surface(_4681, _4682, _4683, _4684, _4685, _4686, _4687, _4688, _4689, _4690, _4691, _4692, _4693, _4694, _4695, _4696);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _4299 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4299; ln++)\n        {\n            int param_12 = ln;\n            int _4312 = fa_cl_light(param_12);\n            int param_13 = _4312;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _4312;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _4642;\n            LightSample _4328 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _4642, fa_world_tangent, fa_uv, fa_vertex_color, _4233, gl_FrontFacing);\n            Surface param_18 = Surface(_4681, _4682, _4683, _4684, _4685, _4686, _4687, _4688, _4689, _4690, _4691, _4692, _4693, _4694, _4695, _4696);\n            LightSample param_19 = _4328;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _4343 = result;\n    vec3 _4344 = _4343 + _4687;\n    result = _4344;\n    vec3 param_20 = _4344;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4353 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4360;\n    if (!_4353)\n    {\n        _4360 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4360 = _4353;\n    }\n    if (_4360)\n    {\n        vec3 _4369 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4375 = dot(_4369, fa_mesh_fs_params[9].xyz);\n        bool _4379 = fa_mesh_fs_params[9].w > 0.5;\n        float _4380;\n        if (_4379)\n        {\n            _4380 = _4375;\n        }\n        else\n        {\n            _4380 = length(_4369);\n        }\n        float _4392 = _4380 - fa_mesh_fs_params[8].x;\n        if (_4392 > 0.0)\n        {\n            float _4401 = fa_mesh_fs_params[7].w * _4392;\n            float tau = _4401 * _4401;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4417;\n                if (_4379)\n                {\n                    _4417 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4375);\n                }\n                else\n                {\n                    _4417 = fa_mesh_fs_params[0].y;\n                }\n                float _4438 = mix(_4417, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4380, 0.0, 1.0));\n                float _4442 = fa_world_pos.y - _4438;\n                float _4447 = _4438 - fa_mesh_fs_params[8].z;\n                float _4452 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4455 = _4447 <= 0.0;\n                bool _4456 = !_4455;\n                bool _4462;\n                if (_4456)\n                {\n                    _4462 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4462 = _4455;\n                }\n                float _4463;\n                if (_4462)\n                {\n                    _4463 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4463 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4447, 80.0));\n                }\n                bool _4490;\n                if (_4456)\n                {\n                    _4490 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4490 = _4455;\n                }\n                float _4491;\n                if (_4490)\n                {\n                    _4491 = fa_mesh_fs_params[8].y * _4447;\n                }\n                else\n                {\n                    _4491 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4447, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4516 = _4452 <= 0.0;\n                bool _4523;\n                if (!_4516)\n                {\n                    _4523 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4523 = _4516;\n                }\n                float _4524;\n                if (_4523)\n                {\n                    _4524 = fa_mesh_fs_params[8].y * _4452;\n                }\n                else\n                {\n                    _4524 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4452, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4551;\n                if (abs(_4442) < 0.001000000047497451305389404296875)\n                {\n                    _4551 = _4463;\n                }\n                else\n                {\n                    _4551 = (_4524 - _4491) / _4442;\n                }\n                tau += (_4392 * max(_4551, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4682);\n}\n\n",
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
            "inst_name": "_401",
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
            "inst_name": "_2058",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[50];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _785 = base_t;\n    _785.x = _227.x;\n    _785.y = _227.y;\n    _785.z = _227.z;\n    base_t = _785;\n    vec4 _243 = (_785 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _748 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _793 = _281;\n        _793.x = _286.x;\n        _793.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _796 = mrt;\n    _796.x = _315.x;\n    _796.y = _315.y;\n    _796.z = _315.z;\n    mrt = _796;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _753 = fa_mesh_fs_params[20].x;\n    float _754 = fa_mesh_fs_params[20].y;\n    float _757 = fa_mesh_fs_params[20].z;\n    float _756 = fa_mesh_fs_params[21].w;\n    float _759 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _753 *= _357.y;\n            _754 *= _357.z;\n            _756 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _748, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _753, _754, fa_mesh_fs_params[21].xyz, _756, _757, fa_mesh_fs_params[20].w, _759, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    vec3 _521 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _536 = normalize(param_2.normal);\n    vec3 _551 = normalize(vec3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    vec2 e = _551.xy / vec2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[50];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _785 = base_t;\n    _785.x = _227.x;\n    _785.y = _227.y;\n    _785.z = _227.z;\n    base_t = _785;\n    vec4 _243 = (_785 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _748 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _793 = _281;\n        _793.x = _286.x;\n        _793.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _796 = mrt;\n    _796.x = _315.x;\n    _796.y = _315.y;\n    _796.z = _315.z;\n    mrt = _796;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _753 = fa_mesh_fs_params[20].x;\n    float _754 = fa_mesh_fs_params[20].y;\n    float _757 = fa_mesh_fs_params[20].z;\n    float _756 = fa_mesh_fs_params[21].w;\n    float _759 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _753 *= _357.y;\n            _754 *= _357.z;\n            _756 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _748, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _753, _754, fa_mesh_fs_params[21].xyz, _756, _757, fa_mesh_fs_params[20].w, _759, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    vec3 _521 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _536 = normalize(param_2.normal);\n    vec3 _551 = normalize(vec3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    vec2 e = _551.xy / vec2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
