{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "d1200774cea097b39827c1b4e04c78590627c6e19a8743dd5b2416938bbf252b",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1348 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1355;\n    if (!_1348)\n    {\n        _1355 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1355 = _1348;\n    }\n    bool _1363;\n    if (!_1355)\n    {\n        _1363 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1363 = _1355;\n    }\n    bool _1370;\n    if (!_1363)\n    {\n        _1370 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1370 = _1363;\n    }\n    bool _1377;\n    if (!_1370)\n    {\n        _1377 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1377 = _1370;\n    }\n    if (_1377)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1387 = vec4(world_pos, 1.0);\n    float _1393 = dot(fa_mesh_fs_params[16], _1387);\n    if (!(_1393 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1415 = vec2(dot(fa_mesh_fs_params[14], _1387), dot(fa_mesh_fs_params[15], _1387)) / vec2(_1393);\n    int _1419 = int(fa_mesh_fs_params[18].x);\n    int _1423 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1423) + clamp(int(floor(((_1415.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1423 - 1)) * _1419)) + clamp(int(floor(((_1415.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1419 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1499 = fa_cluster_texel(param);\n    return ivec2(int(_1499.x), int(_1499.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3917 = fa_cluster_lookup(param);\n    fa_cl_slot = _3917.x;\n    fa_cl_local = _3917.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4127 = fa_linear_to_srgb(param);\n        c = _4127;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4135 = fa_srgb_to_linear(param_1);\n            c = _4135;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _302;\n    if (i.front_facing)\n    {\n        _302 = i.world_normal;\n    }\n    else\n    {\n        _302 = -i.world_normal;\n    }\n    vec3 _326 = normalize(i.world_tangent.xyz - (_302 * dot(_302, i.world_tangent.xyz)));\n    vec3 _353 = normalize(((_326 * m.x) + ((cross(_302, _326) * i.world_tangent.w) * m.y)) + (_302 * m.z));\n    vec3 _356;\n    if (i.front_facing)\n    {\n        _356 = _353;\n    }\n    else\n    {\n        _356 = -_353;\n    }\n    return _356;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4167 = fa_tex_fix(param_2, param_3);\n    vec4 _5987 = base_t;\n    _5987.x = _4167.x;\n    _5987.y = _4167.y;\n    _5987.z = _4167.z;\n    base_t = _5987;\n    vec4 _4181 = (_5987 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5813 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4215 = fa_tex_fix(param_6, param_7);\n        vec3 _4218 = (_4215 * 2.0) - vec3(1.0);\n        vec2 _4223 = _4218.xy * fa_mesh_fs_params[6].x;\n        vec3 _5995 = _4218;\n        _5995.x = _4223.x;\n        _5995.y = _4223.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5995;\n        _5813 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4253 = fa_tex_fix(param_12, param_13);\n    vec4 _5998 = mrt;\n    _5998.x = _4253.x;\n    _5998.y = _4253.y;\n    _5998.z = _4253.z;\n    mrt = _5998;\n    vec4 _4283 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4283.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4294 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4326 = fa_tex_fix(param_20, param_21);\n    float _5818 = fa_mesh_fs_params[20].x;\n    float _5819 = fa_mesh_fs_params[20].y;\n    float _5822 = fa_mesh_fs_params[20].z;\n    float _5821 = fa_mesh_fs_params[21].w;\n    float _5824 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5818 *= _4294.y;\n            _5819 *= _4294.z;\n            _5821 *= _4283.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5822 *= mrt.x;\n            _5824 *= mrt.w;\n        }\n    }\n    return Surface(_4181.xyz, _4181.w, _5813, clamp(fa_mesh_fs_params[5].x * _4253.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4253.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4294.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4326), _5818, _5819, fa_mesh_fs_params[21].xyz, _5821, _5822, fa_mesh_fs_params[20].w, _5824, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1579 = rect.zw - rect.xy;\n    vec2 _1583 = _1579 * atlas;\n    vec2 _1587 = ddx * _1583;\n    vec2 _1591 = ddy * _1583;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1579), clamp(0.5 * log2(max(max(dot(_1587, _1587), dot(_1591, _1591)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1624 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1631;\n    if (!_1624)\n    {\n        _1631 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1631 = _1624;\n    }\n    if (_1631)\n    {\n        return;\n    }\n    vec3 _1637 = dFdx(world_pos);\n    vec3 _1640 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1644 = fa_cluster_texel(param);\n    int _1648 = int(_1644.w);\n    if (_1648 < 1)\n    {\n        return;\n    }\n    int _1658 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1658;\n    vec4 _1662 = fa_light_texel(param_1);\n    vec2 _1665 = _1662.yz;\n    int _1669 = int(_1662.w);\n    int param_2 = _1658 + 1;\n    vec4 _1674 = fa_light_texel(param_2);\n    float _1675 = _1674.x;\n    int _1681 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1685 = int(_1644.z);\n    vec3 _1950;\n    for (int k = 0; k < _1648; k++)\n    {\n        int _1698 = _1685 + k;\n        int param_3 = _1669 + (_1698 >> 2);\n        int _1715 = (_1658 + 2) + (int(fa_light_texel(param_3)[_1698 & 3]) * 7);\n        int param_4 = _1715 + 6;\n        vec4 _1720 = fa_light_texel(param_4);\n        if (((int(_1720.w + 0.5) >> _1681) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1715;\n        vec4 _1735 = fa_light_texel(param_5);\n        int param_6 = _1715 + 1;\n        vec4 _1740 = fa_light_texel(param_6);\n        int param_7 = _1715 + 2;\n        vec4 _1745 = fa_light_texel(param_7);\n        vec3 _1748 = _1735.xyz;\n        float _1753 = dot(_1748, world_pos) + _1735.w;\n        vec3 _1755 = _1740.xyz;\n        float _1760 = dot(_1755, world_pos) + _1740.w;\n        vec3 _1762 = _1745.xyz;\n        float _1767 = dot(_1762, world_pos) + _1745.w;\n        bool _1772 = abs(_1753) > 0.5;\n        bool _1780;\n        if (!_1772)\n        {\n            _1780 = abs(_1760) > 0.5;\n        }\n        else\n        {\n            _1780 = _1772;\n        }\n        bool _1788;\n        if (!_1780)\n        {\n            _1788 = abs(_1767) > 0.5;\n        }\n        else\n        {\n            _1788 = _1780;\n        }\n        if (_1788)\n        {\n            continue;\n        }\n        float _1803 = clamp(dot(geo_normal, normalize(_1762)) * _1720.z, 0.0, 1.0);\n        if (_1803 <= 0.0)\n        {\n            continue;\n        }\n        float _1823 = (clamp((0.5 - abs(_1767)) * 10.0, 0.0, 1.0) * _1803) * _1720.x;\n        vec2 _1831 = vec2(_1753 + 0.5, 0.5 - _1760);\n        vec2 _1841 = vec2(dot(_1748, _1637), dot(_1755, _1637));\n        vec2 _1851 = vec2(dot(_1748, _1640), dot(_1755, _1640));\n        int param_8 = _1715 + 5;\n        vec4 _1856 = fa_light_texel(param_8);\n        int param_9 = _1715 + 3;\n        vec4 _1861 = fa_light_texel(param_9);\n        int param_10 = _1715 + 4;\n        vec4 _1866 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1856.xyz;\n        bool _1876 = _1861.z > _1861.x;\n        if (_1876)\n        {\n            vec4 param_11 = _1861;\n            vec2 param_12 = _1831;\n            vec2 param_13 = _1665;\n            vec2 param_14 = _1841;\n            vec2 param_15 = _1851;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1675 > 0.5) && (_1675 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1902 = fa_dc_to_linear(param_16);\n                vec4 _5901 = tx;\n                _5901.x = _1902.x;\n                _5901.y = _1902.y;\n                _5901.z = _1902.z;\n                tx = _5901;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1823 * tex_a) * _1856.w, 0.0, 1.0)));\n        if (_1866.z > _1866.x)\n        {\n            vec4 param_17 = _1866;\n            vec2 param_18 = _1831;\n            vec2 param_19 = _1665;\n            vec2 param_20 = _1841;\n            vec2 param_21 = _1851;\n            vec4 _1946 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1675 > 1.5)\n            {\n                vec3 param_22 = _1946.xyz;\n                vec3 _1956 = fa_dc_to_srgb(param_22);\n                _1950 = _1956;\n            }\n            else\n            {\n                _1950 = _1946.xyz;\n            }\n            vec3 _1965 = (_1950 * 2.0) - vec3(1.0);\n            vec2 _1970 = _1965.xy * _1720.y;\n            vec3 _1992 = (normalize(_1748) * _1970.x) + (normalize(_1755) * _1970.y);\n            vec3 _1995 = normalize(normal);\n            normal = normalize(mix(_1995, normalize((_1995 * max(_1965.z, 0.0500000007450580596923828125)) + (_1992 - (_1995 * dot(_1995, _1992)))), vec3(clamp(_1823 * (_1876 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3379 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3379;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3489 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3495 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3489 > 0.0005000000237487256526947021484375)\n    {\n        if (_3495)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3489;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3489;\n        }\n    }\n    bool _3547 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3547)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3578 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3578)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3495 || _3547) || _3578)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3399 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3402 = _3399.x;\n    float _3404 = _3399.z;\n    vec2 e = vec2(_3402, _3404);\n    if (_3399.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3404)) * ((_3402 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3402)) * ((_3404 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4440 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4445 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4450 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4455 = fa_light_texel(param_3);\n    bool _4458 = _4455.z < 0.5;\n    bool _4466;\n    if (!_4458)\n    {\n        _4466 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4466 = _4458;\n    }\n    if (_4466)\n    {\n        return vec3(0.0);\n    }\n    float _4473 = max(_4440.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4476 = _4445.xyz;\n    vec3 _4480 = _4440.xyz;\n    vec3 _4484 = (fa_world_pos - _4480) / vec3(_4473);\n    vec3 _4493 = min(_4484 + vec3(0.5), (_4476 - vec3(0.5)) - _4484);\n    float _4502 = min(_4493.x, min(_4493.y, _4493.z));\n    if (!(_4502 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4517 = _4476 - vec3(1.0);\n    vec3 _4518 = clamp(_4484, vec3(0.0), _4517);\n    vec3 _4526 = min(floor(_4518), max(_4476 - vec3(2.0), vec3(0.0)));\n    vec3 _4530 = _4518 - _4526;\n    vec3 _4542 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4473));\n    int _4547 = int(_4450.y + 0.5);\n    float _4552 = 0.3257350027561187744140625 * n.y;\n    float _4556 = 0.3257350027561187744140625 * n.z;\n    float _4560 = 0.3257350027561187744140625 * n.x;\n    float _4567 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _4574 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _4583 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _4590 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _4603 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _4610 = 8 + int(_4455.w);\n    float _4637;\n    float _4650;\n    float _4664;\n    for (int k = 0; k < _4610; k++)\n    {\n        float _4623 = float(k & 1);\n        float _4627 = float((k >> 1) & 1);\n        float _4631 = float((k >> 2) & 1);\n        if (_4623 > 0.5)\n        {\n            _4637 = _4530.x;\n        }\n        else\n        {\n            _4637 = 1.0 - _4530.x;\n        }\n        if (_4627 > 0.5)\n        {\n            _4650 = _4530.y;\n        }\n        else\n        {\n            _4650 = 1.0 - _4530.y;\n        }\n        if (_4631 > 0.5)\n        {\n            _4664 = _4530.z;\n        }\n        else\n        {\n            _4664 = 1.0 - _4530.z;\n        }\n        float _4674 = (_4637 * _4650) * _4664;\n        if (!(_4674 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4687 = min(_4526 + vec3(_4623, _4627, _4631), _4517);\n        int _4707 = int(((_4450.x + _4687.x) + (_4445.x * (_4687.y + (_4445.y * _4687.z)))) + 0.5);\n        vec2 _4722 = vec2(float(_4707 % _4547) * 10.0, 1024.0 + (float(_4707 / _4547) * 11.0));\n        vec2 param_4 = _4722 + vec2(9.5, 10.5);\n        vec4 _4730 = fa_gi_fetch(param_4);\n        bool _4733 = _4730.y < 0.5;\n        bool _4742;\n        if (!_4733)\n        {\n            _4742 = _4730.x > _4455.y;\n        }\n        else\n        {\n            _4742 = _4733;\n        }\n        if (_4742)\n        {\n            continue;\n        }\n        vec3 _4754 = _4542 - (_4480 + (_4687 * _4473));\n        float _4757 = length(_4754);\n        vec3 _4763 = _4754 / vec3(max(_4757, 9.9999997473787516355514526367188e-05));\n        float _4773 = max(9.9999997473787516355514526367188e-05, (dot(-_4763, n) + 1.0) * 0.5);\n        float w = _4674 * (_4773 * _4773);\n        vec3 param_5 = _4763;\n        vec2 param_6 = (_4722 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _4793 = fa_gi_fetch(param_6);\n        float _4800 = _4757 / max(_4450.z, 9.9999997473787516355514526367188e-05);\n        float _4803 = _4793.x;\n        if (_4800 > _4803)\n        {\n            float _4816 = max(_4793.y - (_4803 * _4803), 0.0);\n            float _4821 = _4800 - _4803;\n            float _4830 = _4816 / max(_4816 + (_4821 * _4821), 9.9999999600419720025001879548654e-13);\n            w *= ((_4830 * _4830) * _4830);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _4722 + vec2(0.5, 10.5);\n        vec2 param_8 = _4722 + vec2(1.5, 10.5);\n        vec2 param_9 = _4722 + vec2(2.5, 10.5);\n        vec2 param_10 = _4722 + vec2(3.5, 10.5);\n        vec2 param_11 = _4722 + vec2(4.5, 10.5);\n        vec2 param_12 = _4722 + vec2(5.5, 10.5);\n        vec2 param_13 = _4722 + vec2(6.5, 10.5);\n        vec2 param_14 = _4722 + vec2(7.5, 10.5);\n        vec2 param_15 = _4722 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4552)) + (fa_gi_fetch(param_9).xyz * _4556)) + (fa_gi_fetch(param_10).xyz * _4560)) + (fa_gi_fetch(param_11).xyz * _4567)) + (fa_gi_fetch(param_12).xyz * _4574)) + (fa_gi_fetch(param_13).xyz * _4583)) + (fa_gi_fetch(param_14).xyz * _4590)) + (fa_gi_fetch(param_15).xyz * _4603)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4502 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _4958;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _4958 = _4455.x;\n    }\n    else\n    {\n        _4958 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4450.w * _4958);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _4982 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _4987 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _4992 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _4992) && (k < 8); k++)\n    {\n        int param = _4987 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _4982;\n        vec3 _5017 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5022 = param_3 * left;\n        acc += (_5017 * _5022);\n        left -= _5022;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _5051 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5051;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3887;\n    if (fa_lm.z > 0.5)\n    {\n        _3887 = 0.0;\n    }\n    else\n    {\n        _3887 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _3898 = _3887 < 1.0;\n    bool _3904;\n    if (_3898)\n    {\n        int param = li;\n        _3904 = fa_light_baked(param);\n    }\n    else\n    {\n        _3904 = _3898;\n    }\n    return _3904 ? _3887 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _598 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _611 = (c - (ru * hx)) - p;\n        vec3 _617 = ru * (2.0 * hx);\n        float _623 = max(dot(_617, _617), 9.9999999392252902907785028219223e-09);\n        float _627 = dot(_611, _617);\n        float t = clamp((-_627) / _623, 0.0, 1.0);\n        if (_598)\n        {\n            float _642 = dot(r, _617);\n            float _648 = _623 - (_642 * _642);\n            if (abs(_648) > (9.9999997473787516355514526367188e-06 * _623))\n            {\n                t = clamp(((dot(r, _611) * _642) - _627) / _648, 0.0, 1.0);\n            }\n        }\n        return (p + _611) + (_617 * t);\n    }\n    vec3 q = p;\n    float _680 = dot(r, axis);\n    bool _688;\n    if (_598)\n    {\n        _688 = abs(_680) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _688 = _598;\n    }\n    if (_688)\n    {\n        float _698 = dot(c - p, axis) / _680;\n        if (_698 > 0.0)\n        {\n            q = p + (r * _698);\n        }\n    }\n    vec3 _711 = q - c;\n    vec2 xy = vec2(dot(_711, ru), dot(_711, uu));\n    if (shape > 0.5)\n    {\n        float _726 = length(xy);\n        if (_726 > hx)\n        {\n            xy *= (hx / _726);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _518 = dot(d, right);\n    float _522 = dot(d, up);\n    float _533;\n    if (((_518 * _518) + (_522 * _522)) > 1.0000000133514319600180897396058e-10)\n    {\n        _533 = atan(_522, _518) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _533 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_533 - floor(_533)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _368 = abs(d);\n    float _370 = _368.x;\n    float _372 = _368.y;\n    bool _373 = _370 >= _372;\n    bool _381;\n    if (_373)\n    {\n        _381 = _370 >= _368.z;\n    }\n    else\n    {\n        _381 = _373;\n    }\n    int _382;\n    if (_381)\n    {\n        _382 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _397;\n        if (_372 >= _368.z)\n        {\n            _397 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _397 = (d.z > 0.0) ? 4 : 5;\n        }\n        _382 = _397;\n    }\n    return _382;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _764 = fa_light_base(param);\n    bool _768 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _764;\n    vec4 _772 = fa_light_texel(param_1);\n    int param_2 = _764 + 1;\n    vec4 _777 = fa_light_texel(param_2);\n    float _780 = _777.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _792 = _768 && (_780 > 2.5);\n    fa_light_is_area = _792;\n    bool _794 = _780 < 0.5;\n    vec3 l;\n    if (_794)\n    {\n        l = normalize(_772.xyz);\n        if (_768)\n        {\n            int param_3 = _764 + 6;\n            vec4 _808 = fa_light_texel(param_3);\n            if (_808.z > 0.5)\n            {\n                int param_4 = _764 + 4;\n                vec4 _818 = fa_light_texel(param_4);\n                int param_5 = _764 + 5;\n                vec4 _823 = fa_light_texel(param_5);\n                vec2 param_6 = _808.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _818.xyz) * _818.w, (-dot(world_pos, _823.xyz)) * _823.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _853 = _772.xyz;\n        vec3 _855 = _853 - world_pos;\n        vec3 to_light = _855;\n        float _858 = length(_855);\n        float reach = _858;\n        bool front = true;\n        if (_792)\n        {\n            int param_8 = _764 + 7;\n            reach = max(_858 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _764 + 4;\n            vec4 _882 = fa_light_texel(param_9);\n            int param_10 = _764 + 5;\n            vec4 _887 = fa_light_texel(param_10);\n            int param_11 = _764 + 6;\n            vec4 _892 = fa_light_texel(param_11);\n            float _893 = _892.w;\n            int param_12 = _764 + 2;\n            vec3 _900 = normalize(fa_light_texel(param_12).xyz);\n            bool _902 = _893 > 1.5;\n            bool _910;\n            if (!_902)\n            {\n                _910 = dot(_900, to_light) < 0.0;\n            }\n            else\n            {\n                _910 = _902;\n            }\n            front = _910;\n            vec3 r = vec3(0.0);\n            vec3 _919 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _923 = dot(n, n) > 0.5;\n            bool _931;\n            if (_923)\n            {\n                _931 = dot(_919, _919) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _931 = _923;\n            }\n            if (_931)\n            {\n                r = reflect(-normalize(_919), normalize(n));\n            }\n            vec3 param_13 = _853;\n            vec3 param_14 = _900;\n            vec3 param_15 = _882.xyz;\n            vec3 param_16 = _887.xyz;\n            float param_17 = _882.w;\n            float param_18 = _887.w;\n            float param_19 = _893;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _967 = length(to_light);\n        dist = _967;\n        l = to_light / vec3(max(_967, 9.9999997473787516355514526367188e-05));\n        float _981 = reach / max(_772.w, 0.001000000047497451305389404296875);\n        float _987 = clamp(1.0 - (_981 * _981), 0.0, 1.0);\n        float _989;\n        if (front)\n        {\n            _989 = _987 * _987;\n        }\n        else\n        {\n            _989 = 0.0;\n        }\n        atten = _989;\n        bool _1000 = _780 < 2.5;\n        if ((_780 > 1.5) && _1000)\n        {\n            int param_22 = _764 + 2;\n            vec4 _1008 = fa_light_texel(param_22);\n            float _1018 = _1008.w;\n            int param_23 = _764 + 3;\n            vec4 _1023 = fa_light_texel(param_23);\n            float _1024 = _1023.x;\n            float cos_inner = _1024;\n            if (_1024 > 1.5)\n            {\n                cos_inner = mix(_1018, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1018, cos_inner, dot(-l, normalize(_1008.xyz)));\n        }\n        if (_768 && (_780 < 1.5))\n        {\n            int param_24 = _764 + 6;\n            vec4 _1048 = fa_light_texel(param_24);\n            if (_1048.z > 0.5)\n            {\n                vec3 _1056 = -to_light;\n                int param_25 = _764 + 4;\n                int param_26 = _764 + 5;\n                vec3 _1070 = fa_light_texel(param_25).xyz;\n                vec3 _1074 = fa_light_texel(param_26).xyz;\n                vec3 _1083 = vec3(dot(_1056, _1070), dot(_1056, _1074), dot(_1056, cross(_1070, _1074)));\n                vec3 param_27 = _1083;\n                int _1087 = fa_cube_face(param_27);\n                int param_28 = _1087;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1114 = vec2(dot(_1083, cross(param_29, param_30)), dot(_1083, param_30)) / vec2(max(dot(_1083, param_29), 9.9999997473787516355514526367188e-05));\n                int _1118 = _1087 / 3;\n                vec2 param_31 = _1048.xy + (vec2(float(_1087 - (_1118 * 3)), float(_1118)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1114.x), 0.5 - (0.5 * _1114.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _764 + 7;\n            vec4 _1148 = fa_light_texel(param_33);\n            if (_1148.z > 0.5)\n            {\n                int param_34 = _764 + 2;\n                int param_35 = _764 + 4;\n                int param_36 = _764 + 5;\n                vec2 param_37 = _1148.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_768 && _1000)\n            {\n                int param_42 = _764 + 6;\n                vec4 _1195 = fa_light_texel(param_42);\n                int param_43 = _764 + 7;\n                vec4 _1200 = fa_light_texel(param_43);\n                bool _1203 = _1195.z > 0.5;\n                bool _1210;\n                if (!_1203)\n                {\n                    _1210 = _1200.z > 0.5;\n                }\n                else\n                {\n                    _1210 = _1203;\n                }\n                if (_1210)\n                {\n                    int param_44 = _764 + 2;\n                    vec4 _1217 = fa_light_texel(param_44);\n                    vec3 _1221 = normalize(_1217.xyz);\n                    int param_45 = _764 + 4;\n                    vec4 _1226 = fa_light_texel(param_45);\n                    int param_46 = _764 + 5;\n                    vec4 _1231 = fa_light_texel(param_46);\n                    if (_1203)\n                    {\n                        vec3 _1239 = -to_light;\n                        float _1246 = _1217.w;\n                        float _1262 = 0.5 / max(dot(_1239, _1221) * (sqrt(max(1.0 - (_1246 * _1246), 0.0)) / max(_1246, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1195.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1239, _1226.xyz) * _1262), 0.5 - (dot(_1239, _1231.xyz) * _1262));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1200.z > 0.5)\n                    {\n                        vec2 param_49 = _1200.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1221;\n                        vec3 param_52 = _1226.xyz;\n                        vec3 param_53 = _1231.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5767 = _777.xyz * atten;\n    if (_768)\n    {\n        _5767 *= fa_light_tint;\n    }\n    int _1330;\n    if (_794)\n    {\n        _1330 = 0;\n    }\n    else\n    {\n        _1330 = ((_780 > 1.5) && (_780 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5767, atten, 1.0, dist, _1330);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2119 = fa_shadow_depth(param, param_1);\n    float _2123;\n    if (conv.x < 0.5)\n    {\n        _2123 = _2119;\n    }\n    else\n    {\n        _2123 = (conv.y * conv.z) / (conv.z - (_2119 * (conv.z - conv.y)));\n    }\n    return _2123;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2169 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2175 = vec2(cos(_2169), sin(_2169));\n    vec2 dir = _2175;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2184;\n        if (k < 0.0)\n        {\n            _2184 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2184 = k;\n        }\n        float _2203 = clamp((_2184 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2222 = sqrt((float(i) + 0.5) * 0.0625) * _2203;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2222));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2236 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2236 < (zr - (_2222 * plane)))\n            {\n                sum += _2236;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2264 = sum / cnt;\n        float _2274;\n        if (k < 0.0)\n        {\n            _2274 = (-k) / max(_2264, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2274 = k;\n        }\n        radius = clamp(((max(zr - _2264, 0.0) * unit) * _2274) / texel_m, 1.5, 16.0);\n        dir = _2175;\n    }\n    float lit = 0.0;\n    int _2300 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2300; i_1++)\n    {\n        float _2319 = sqrt((float(i_1) + 0.5) / float(_2300)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2319));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2319 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2300);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2524 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2531;\n    if (!_2524)\n    {\n        _2531 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2531 = _2524;\n    }\n    if (_2531)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2544 = fa_light_texel(param);\n    float _2545 = _2544.x;\n    if (_2545 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2554 = int(_2545 + 0.5);\n    int param_1 = _2554;\n    vec4 _2558 = fa_light_texel(param_1);\n    int param_2 = _2554 + 1;\n    vec4 _2563 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2566 = _2558.y;\n    if (_2566 > 0.0)\n    {\n        float _2583 = 1.0 - smoothstep(0.75 * _2566, _2566, length(world - fa_shadows[27].xyz));\n        fade = _2583;\n        if (_2583 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2558.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2607 = (_2554 + 2) + (face * 6);\n    int param_4 = _2607;\n    int param_5 = _2607 + 1;\n    int param_6 = _2607 + 3;\n    vec4 _2621 = fa_light_texel(param_6);\n    int param_7 = _2607 + 4;\n    vec4 _2626 = fa_light_texel(param_7);\n    int param_8 = _2607 + 5;\n    vec4 _2631 = fa_light_texel(param_8);\n    float _2643 = _2631.x * max(dot(_2621, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2648 = clamp(dot(n, l), 0.0, 1.0);\n    float _2671 = clamp(dot(n, _2621.xyz), -1.0, 1.0);\n    float _2690 = min(sqrt(1.0 - (_2671 * _2671)) / max(abs(dot(n, world - lpos)) / max(dot(_2621, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2693 = _2563.y;\n    float _2695;\n    if (_2693 > 0.0)\n    {\n        _2695 = _2693;\n    }\n    else\n    {\n        _2695 = 1.5 * _2643;\n    }\n    vec4 _2715 = vec4(world + (n * (_2695 * sqrt(1.0 - (_2648 * _2648)))), 1.0);\n    float _2719 = dot(_2621, _2715);\n    float _2722 = _2631.y;\n    if (_2719 < _2722)\n    {\n        return 1.0;\n    }\n    vec2 _2737 = vec2(dot(fa_light_texel(param_4), _2715), dot(fa_light_texel(param_5), _2715)) / vec2(_2719);\n    float _2739 = _2737.x;\n    bool _2742 = _2739 < _2626.x;\n    bool _2751;\n    if (!_2742)\n    {\n        _2751 = _2739 > _2626.z;\n    }\n    else\n    {\n        _2751 = _2742;\n    }\n    bool _2760;\n    if (!_2751)\n    {\n        _2760 = _2737.y < _2626.y;\n    }\n    else\n    {\n        _2760 = _2751;\n    }\n    bool _2769;\n    if (!_2760)\n    {\n        _2769 = _2737.y > _2626.w;\n    }\n    else\n    {\n        _2769 = _2760;\n    }\n    if (_2769)\n    {\n        return 1.0;\n    }\n    float _2775 = _2563.x;\n    float _2777;\n    if (_2775 > 0.0)\n    {\n        _2777 = _2775;\n    }\n    else\n    {\n        _2777 = 1.5 * _2643;\n    }\n    vec2 param_9 = _2737;\n    vec4 param_10 = _2626;\n    float param_11 = _2719 - (_2777 * (1.0 + (0.5 * _2690)));\n    float param_12 = _2643;\n    float param_13 = 1.0;\n    float param_14 = _2631.z * 0.25;\n    float param_15 = (_2643 * min(_2690, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2722, _2631.z);\n    int param_17 = int(_2558.z + 0.5);\n    float param_18 = _2558.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2062;\n    if (i == 0)\n    {\n        _2062 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2078;\n        if (i == 1)\n        {\n            _2078 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2086;\n            if (i == 2)\n            {\n                _2086 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2086 = fa_shadows[24].w;\n            }\n            _2078 = _2086;\n        }\n        _2062 = _2078;\n    }\n    return _2062;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2365 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2370 = clamp(dot(n, l), 0.0, 1.0);\n    float _2376 = sqrt(1.0 - (_2370 * _2370));\n    float _2384 = min(_2376 / max(_2370, 0.20000000298023223876953125), 4.0);\n    float _2389;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2389 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2389 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2414 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2389 * _2376)), 1.0);\n    float _2421 = _2414.x;\n    bool _2424 = _2421 < fa_shadows[ci * 1 + 16].x;\n    bool _2433;\n    if (!_2424)\n    {\n        _2433 = _2421 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2433 = _2424;\n    }\n    bool _2442;\n    if (!_2433)\n    {\n        _2442 = _2414.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2442 = _2433;\n    }\n    bool _2451;\n    if (!_2442)\n    {\n        _2451 = _2414.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2451 = _2442;\n    }\n    bool _2458;\n    if (!_2451)\n    {\n        _2458 = _2414.z > 1.0;\n    }\n    else\n    {\n        _2458 = _2451;\n    }\n    if (_2458)\n    {\n        return -1.0;\n    }\n    float _2466;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2466 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2466 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2414.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2414.z - ((_2466 * (1.0 + (0.5 * _2384))) / _2365);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2365;\n    float param_5 = _2365 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2384, 3.0)) * 0.5) / _2365;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2844 = int(fa_shadows[25].x + 0.5);\n    if (_2844 < 1)\n    {\n        return 1.0;\n    }\n    float _2859 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2844 - 1;\n    if (_2859 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2871 = _2844 > 1;\n    bool _2878;\n    if (_2871)\n    {\n        _2878 = _2859 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2878 = _2871;\n    }\n    if (_2878)\n    {\n        ci = 1;\n    }\n    bool _2882 = _2844 > 2;\n    bool _2889;\n    if (_2882)\n    {\n        _2889 = _2859 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2889 = _2882;\n    }\n    if (_2889)\n    {\n        ci = 2;\n    }\n    bool _2893 = _2844 > 3;\n    bool _2900;\n    if (_2893)\n    {\n        _2900 = _2859 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2900 = _2893;\n    }\n    if (_2900)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2911 = min(_2844, 4);\n    float _2952;\n    for (int c = ci; c < _2911; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2931 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2931;\n            break;\n        }\n        if (_2931 < 0.0)\n        {\n            continue;\n        }\n        s = _2931;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2952 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2952 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _2971 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2952, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2859 - (fa_shadow_split_at(param_7) - _2971)) / _2971, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3003;\n        if ((ci + 1) < _2844)\n        {\n            _3003 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3003 = 1.0;\n        }\n        s = mix(s, _3003, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3108 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3114;\n    if (_3108)\n    {\n        _3114 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3114 = _3108;\n    }\n    if (_3114)\n    {\n        float _3128 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3131 = fwidth(_3128);\n        vec4 _3141 = vec4(fa_world_pos, 1.0);\n        float _3147 = dot(fa_mesh_fs_params[28], _3141);\n        if (_3147 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3166 = vec2(dot(fa_mesh_fs_params[26], _3141), dot(fa_mesh_fs_params[27], _3141)) / vec2(_3147);\n            float _3171 = (_3166.x * 0.5) + 0.5;\n            float _3175;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3175 = (_3166.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3175 = 0.5 - (_3166.y * 0.5);\n            }\n            bool _3191 = _3171 >= 0.0;\n            bool _3197;\n            if (_3191)\n            {\n                _3197 = _3171 < 1.0;\n            }\n            else\n            {\n                _3197 = _3191;\n            }\n            bool _3203;\n            if (_3197)\n            {\n                _3203 = _3175 >= 0.0;\n            }\n            else\n            {\n                _3203 = _3197;\n            }\n            bool _3209;\n            if (_3203)\n            {\n                _3209 = _3175 < 1.0;\n            }\n            else\n            {\n                _3209 = _3203;\n            }\n            if (_3209)\n            {\n                vec4 _3235 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3171, _3175) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3238 = _3235.w > 0.5;\n                bool _3254;\n                if (_3238)\n                {\n                    _3254 = abs(_3128 - _3235.x) <= (((0.00200000009499490261077880859375 * _3128) + 0.00999999977648258209228515625) + min(1.5 * _3131, 0.100000001490116119384765625 * _3128));\n                }\n                else\n                {\n                    _3254 = _3238;\n                }\n                if (_3254)\n                {\n                    float _3260;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3260 = min(_3235.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3260 = _3235.y;\n                    }\n                    return _3260;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3629 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3636;\n    if (!_3629)\n    {\n        _3636 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3636 = _3629;\n    }\n    if (_3636)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3649 = fa_light_texel(param);\n    float _3650 = _3649.y;\n    float len = _3650;\n    if (_3650 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3662 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3671 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3662);\n    if (_3671 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3677 = len;\n    float _3680 = min(_3677, 0.89999997615814208984375 * dist);\n    len = _3680;\n    float _3686 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3662);\n    float _3691 = _3686 + (0.5 * _3680);\n    vec3 _3697 = world + (gn * _3686);\n    float _3699 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3761;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3715 = (float(k) + _3699) * 0.083333335816860198974609375;\n        vec3 _3723 = _3697 + (l * (_3715 * len));\n        vec4 _3729 = vec4(_3723, 1.0);\n        float _3734 = dot(fa_mesh_fs_params[28], _3729);\n        if (_3734 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3752 = vec2(dot(fa_mesh_fs_params[26], _3729), dot(fa_mesh_fs_params[27], _3729)) / vec2(_3734);\n        float _3756 = _3752.x * 0.5;\n        float _3757 = _3756 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3761 = (_3752.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3761 = 0.5 - (_3752.y * 0.5);\n        }\n        bool _3777 = _3757 < 0.0;\n        bool _3784;\n        if (!_3777)\n        {\n            _3784 = _3757 >= 1.0;\n        }\n        else\n        {\n            _3784 = _3777;\n        }\n        bool _3791;\n        if (!_3784)\n        {\n            _3791 = _3761 < 0.0;\n        }\n        else\n        {\n            _3791 = _3784;\n        }\n        bool _3798;\n        if (!_3791)\n        {\n            _3798 = _3761 >= 1.0;\n        }\n        else\n        {\n            _3798 = _3791;\n        }\n        if (_3798)\n        {\n            break;\n        }\n        vec4 _3822 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3757, _3761) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_3822.w < 0.5)\n        {\n            continue;\n        }\n        float _3840 = (dot(fa_mesh_fs_params[29].xyz, _3723) + fa_mesh_fs_params[29].w) - _3822.x;\n        if ((_3840 > _3686) && (_3840 < _3691))\n        {\n            occ = max(occ, (1.0 - (_3715 * _3715)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3757, 0.5 - _3756), min(_3761, 1.0 - _3761))));\n        }\n    }\n    return 1.0 - (occ * _3671);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3943 = fa_baked_keep(param);\n    if (_3943 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3969 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5793 = _3969.color;\n    float _5794 = _3969.attenuation;\n    float _5795 = _3969.shadow;\n    bool _3972 = _3969.type == 0;\n    if (_3972 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3969.direction;\n        float _3983 = fa_shadow_factor(param_5, param_6);\n        _5795 = _3983;\n        _5793 *= _3983;\n    }\n    else\n    {\n        bool _3994 = _3969.type != 0;\n        bool _4000;\n        if (_3994)\n        {\n            _4000 = _5794 > 0.0;\n        }\n        else\n        {\n            _4000 = _3994;\n        }\n        if (_4000)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3969.direction;\n            float _4019 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5795 = _4019;\n            _5793 *= _4019;\n        }\n    }\n    bool _4029 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4035;\n    if (_4029)\n    {\n        _4035 = _5794 > 0.0;\n    }\n    else\n    {\n        _4035 = _4029;\n    }\n    if (_4035)\n    {\n        float _4042;\n        if (_3972)\n        {\n            _4042 = 1000000000.0;\n        }\n        else\n        {\n            _4042 = _3969._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3969.direction;\n        float param_18 = _4042;\n        float _4060 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5795 *= _4060;\n        _5793 *= _4060;\n    }\n    float _4073 = _5794;\n    float _4074 = _4073 * _3943;\n    _5794 = _4074;\n    vec3 _4078 = _5793;\n    vec3 _4079 = _4078 * _3943;\n    _5793 = _4079;\n    return LightSample(_3969.direction, _4079, _4074, _5795, _3969._distance, _3969.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3031 = int(fa_shadows[25].x + 0.5);\n    float _3041 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3046 = _3031 > 0;\n    bool _3055;\n    if (_3046)\n    {\n        int param = _3031 - 1;\n        _3055 = _3041 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3055 = _3046;\n    }\n    if (_3055)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3061 = _3031 > 1;\n        bool _3068;\n        if (_3061)\n        {\n            _3068 = _3041 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3068 = _3061;\n        }\n        if (_3068)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3074 = _3031 > 2;\n        bool _3081;\n        if (_3074)\n        {\n            _3081 = _3041 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3081 = _3074;\n        }\n        if (_3081)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3087 = _3031 > 3;\n        bool _3094;\n        if (_3087)\n        {\n            _3094 = _3041 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3094 = _3087;\n        }\n        if (_3094)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5585 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5585 = -_5585;\n    }\n    vec3 _5159 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5585, fa_world_tangent, fa_uv, fa_vertex_color, _5159, gl_FrontFacing);\n    Surface _5167 = fa_standard_surface(param_1);\n    vec3 _5624 = _5167.albedo;\n    float _5625 = _5167.alpha;\n    vec3 _5626 = _5167.normal;\n    float _5627 = _5167.metallic;\n    float _5628 = _5167.roughness;\n    float _5629 = _5167.occlusion;\n    vec3 _5630 = _5167.emission;\n    float _5631 = _5167.clearcoat;\n    float _5632 = _5167.clearcoat_roughness;\n    vec3 _5633 = _5167.sheen_color;\n    float _5634 = _5167.sheen_roughness;\n    float _5635 = _5167.anisotropy;\n    float _5636 = _5167.anisotropy_rotation;\n    float _5637 = _5167.specular;\n    float _5638 = _5167.ior;\n    vec3 _5639 = _5167.specular_color;\n    float _5640 = _5167.transmission;\n    float _5641 = _5167.thickness;\n    vec3 _5642 = _5167.attenuation_color;\n    float _5643 = _5167.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5585, fa_world_tangent, fa_uv, fa_vertex_color, _5159, gl_FrontFacing);\n    Surface param_3 = _5167;\n    surface(param_2, param_3);\n    _5624 = param_3.albedo;\n    _5625 = param_3.alpha;\n    _5626 = param_3.normal;\n    _5627 = param_3.metallic;\n    _5628 = param_3.roughness;\n    _5629 = param_3.occlusion;\n    _5630 = param_3.emission;\n    _5631 = param_3.clearcoat;\n    _5632 = param_3.clearcoat_roughness;\n    _5633 = param_3.sheen_color;\n    _5634 = param_3.sheen_roughness;\n    _5635 = param_3.anisotropy;\n    _5636 = param_3.anisotropy_rotation;\n    _5637 = param_3.specular;\n    _5638 = param_3.ior;\n    _5639 = param_3.specular_color;\n    _5640 = param_3.transmission;\n    _5641 = param_3.thickness;\n    _5642 = param_3.attenuation_color;\n    _5643 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5585;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5624 = param_6;\n    _5626 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5624;\n    }\n    else\n    {\n        vec3 _5206 = _5626;\n        vec3 _5207 = normalize(_5206);\n        _5626 = _5207;\n        vec3 param_8 = _5207;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _5585, fa_world_tangent, fa_uv, fa_vertex_color, _5159, gl_FrontFacing);\n        Surface param_10 = Surface(_5624, _5625, _5626, _5627, _5628, _5629, _5630, _5631, _5632, _5633, _5634, _5635, _5636, _5637, _5638, _5639, _5640, _5641, _5642, _5643);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _5226 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5226; ln++)\n        {\n            int param_12 = ln;\n            int _5239 = fa_cl_light(param_12);\n            int param_13 = _5239;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _5239;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _5585;\n            LightSample _5255 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _5585, fa_world_tangent, fa_uv, fa_vertex_color, _5159, gl_FrontFacing);\n            Surface param_18 = Surface(_5624, _5625, _5626, _5627, _5628, _5629, _5630, _5631, _5632, _5633, _5634, _5635, _5636, _5637, _5638, _5639, _5640, _5641, _5642, _5643);\n            LightSample param_19 = _5255;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _5270 = result;\n    vec3 _5271 = _5270 + _5630;\n    result = _5271;\n    vec3 param_20 = _5271;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5280 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5287;\n    if (!_5280)\n    {\n        _5287 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5287 = _5280;\n    }\n    if (_5287)\n    {\n        vec3 _5296 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5302 = dot(_5296, fa_mesh_fs_params[9].xyz);\n        bool _5306 = fa_mesh_fs_params[9].w > 0.5;\n        float _5307;\n        if (_5306)\n        {\n            _5307 = _5302;\n        }\n        else\n        {\n            _5307 = length(_5296);\n        }\n        float _5319 = _5307 - fa_mesh_fs_params[8].x;\n        if (_5319 > 0.0)\n        {\n            float _5328 = fa_mesh_fs_params[7].w * _5319;\n            float tau = _5328 * _5328;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5344;\n                if (_5306)\n                {\n                    _5344 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5302);\n                }\n                else\n                {\n                    _5344 = fa_mesh_fs_params[0].y;\n                }\n                float _5365 = mix(_5344, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5307, 0.0, 1.0));\n                float _5369 = fa_world_pos.y - _5365;\n                float _5374 = _5365 - fa_mesh_fs_params[8].z;\n                float _5379 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5382 = _5374 <= 0.0;\n                bool _5383 = !_5382;\n                bool _5389;\n                if (_5383)\n                {\n                    _5389 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5389 = _5382;\n                }\n                float _5390;\n                if (_5389)\n                {\n                    _5390 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5390 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5374, 80.0));\n                }\n                bool _5417;\n                if (_5383)\n                {\n                    _5417 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5417 = _5382;\n                }\n                float _5418;\n                if (_5417)\n                {\n                    _5418 = fa_mesh_fs_params[8].y * _5374;\n                }\n                else\n                {\n                    _5418 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5374, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5443 = _5379 <= 0.0;\n                bool _5450;\n                if (!_5443)\n                {\n                    _5450 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5450 = _5443;\n                }\n                float _5451;\n                if (_5450)\n                {\n                    _5451 = fa_mesh_fs_params[8].y * _5379;\n                }\n                else\n                {\n                    _5451 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5379, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5478;\n                if (abs(_5369) < 0.001000000047497451305389404296875)\n                {\n                    _5478 = _5390;\n                }\n                else\n                {\n                    _5478 = (_5451 - _5418) / _5369;\n                }\n                tau += (_5319 * max(_5478, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5625);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_420",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
            "inst_name": "_2072",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1348 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1355;\n    if (!_1348)\n    {\n        _1355 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1355 = _1348;\n    }\n    bool _1363;\n    if (!_1355)\n    {\n        _1363 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1363 = _1355;\n    }\n    bool _1370;\n    if (!_1363)\n    {\n        _1370 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1370 = _1363;\n    }\n    bool _1377;\n    if (!_1370)\n    {\n        _1377 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1377 = _1370;\n    }\n    if (_1377)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1387 = vec4(world_pos, 1.0);\n    float _1393 = dot(fa_mesh_fs_params[16], _1387);\n    if (!(_1393 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1415 = vec2(dot(fa_mesh_fs_params[14], _1387), dot(fa_mesh_fs_params[15], _1387)) / vec2(_1393);\n    int _1419 = int(fa_mesh_fs_params[18].x);\n    int _1423 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1423) + clamp(int(floor(((_1415.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1423 - 1)) * _1419)) + clamp(int(floor(((_1415.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1419 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1499 = fa_cluster_texel(param);\n    return ivec2(int(_1499.x), int(_1499.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3917 = fa_cluster_lookup(param);\n    fa_cl_slot = _3917.x;\n    fa_cl_local = _3917.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4127 = fa_linear_to_srgb(param);\n        c = _4127;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4135 = fa_srgb_to_linear(param_1);\n            c = _4135;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _302;\n    if (i.front_facing)\n    {\n        _302 = i.world_normal;\n    }\n    else\n    {\n        _302 = -i.world_normal;\n    }\n    vec3 _326 = normalize(i.world_tangent.xyz - (_302 * dot(_302, i.world_tangent.xyz)));\n    vec3 _353 = normalize(((_326 * m.x) + ((cross(_302, _326) * i.world_tangent.w) * m.y)) + (_302 * m.z));\n    vec3 _356;\n    if (i.front_facing)\n    {\n        _356 = _353;\n    }\n    else\n    {\n        _356 = -_353;\n    }\n    return _356;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4167 = fa_tex_fix(param_2, param_3);\n    vec4 _5987 = base_t;\n    _5987.x = _4167.x;\n    _5987.y = _4167.y;\n    _5987.z = _4167.z;\n    base_t = _5987;\n    vec4 _4181 = (_5987 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5813 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4215 = fa_tex_fix(param_6, param_7);\n        vec3 _4218 = (_4215 * 2.0) - vec3(1.0);\n        vec2 _4223 = _4218.xy * fa_mesh_fs_params[6].x;\n        vec3 _5995 = _4218;\n        _5995.x = _4223.x;\n        _5995.y = _4223.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5995;\n        _5813 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4253 = fa_tex_fix(param_12, param_13);\n    vec4 _5998 = mrt;\n    _5998.x = _4253.x;\n    _5998.y = _4253.y;\n    _5998.z = _4253.z;\n    mrt = _5998;\n    vec4 _4283 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4283.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4294 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4326 = fa_tex_fix(param_20, param_21);\n    float _5818 = fa_mesh_fs_params[20].x;\n    float _5819 = fa_mesh_fs_params[20].y;\n    float _5822 = fa_mesh_fs_params[20].z;\n    float _5821 = fa_mesh_fs_params[21].w;\n    float _5824 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5818 *= _4294.y;\n            _5819 *= _4294.z;\n            _5821 *= _4283.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5822 *= mrt.x;\n            _5824 *= mrt.w;\n        }\n    }\n    return Surface(_4181.xyz, _4181.w, _5813, clamp(fa_mesh_fs_params[5].x * _4253.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4253.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4294.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4326), _5818, _5819, fa_mesh_fs_params[21].xyz, _5821, _5822, fa_mesh_fs_params[20].w, _5824, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1579 = rect.zw - rect.xy;\n    vec2 _1583 = _1579 * atlas;\n    vec2 _1587 = ddx * _1583;\n    vec2 _1591 = ddy * _1583;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1579), clamp(0.5 * log2(max(max(dot(_1587, _1587), dot(_1591, _1591)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1624 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1631;\n    if (!_1624)\n    {\n        _1631 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1631 = _1624;\n    }\n    if (_1631)\n    {\n        return;\n    }\n    vec3 _1637 = dFdx(world_pos);\n    vec3 _1640 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1644 = fa_cluster_texel(param);\n    int _1648 = int(_1644.w);\n    if (_1648 < 1)\n    {\n        return;\n    }\n    int _1658 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1658;\n    vec4 _1662 = fa_light_texel(param_1);\n    vec2 _1665 = _1662.yz;\n    int _1669 = int(_1662.w);\n    int param_2 = _1658 + 1;\n    vec4 _1674 = fa_light_texel(param_2);\n    float _1675 = _1674.x;\n    int _1681 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1685 = int(_1644.z);\n    vec3 _1950;\n    for (int k = 0; k < _1648; k++)\n    {\n        int _1698 = _1685 + k;\n        int param_3 = _1669 + (_1698 >> 2);\n        int _1715 = (_1658 + 2) + (int(fa_light_texel(param_3)[_1698 & 3]) * 7);\n        int param_4 = _1715 + 6;\n        vec4 _1720 = fa_light_texel(param_4);\n        if (((int(_1720.w + 0.5) >> _1681) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1715;\n        vec4 _1735 = fa_light_texel(param_5);\n        int param_6 = _1715 + 1;\n        vec4 _1740 = fa_light_texel(param_6);\n        int param_7 = _1715 + 2;\n        vec4 _1745 = fa_light_texel(param_7);\n        vec3 _1748 = _1735.xyz;\n        float _1753 = dot(_1748, world_pos) + _1735.w;\n        vec3 _1755 = _1740.xyz;\n        float _1760 = dot(_1755, world_pos) + _1740.w;\n        vec3 _1762 = _1745.xyz;\n        float _1767 = dot(_1762, world_pos) + _1745.w;\n        bool _1772 = abs(_1753) > 0.5;\n        bool _1780;\n        if (!_1772)\n        {\n            _1780 = abs(_1760) > 0.5;\n        }\n        else\n        {\n            _1780 = _1772;\n        }\n        bool _1788;\n        if (!_1780)\n        {\n            _1788 = abs(_1767) > 0.5;\n        }\n        else\n        {\n            _1788 = _1780;\n        }\n        if (_1788)\n        {\n            continue;\n        }\n        float _1803 = clamp(dot(geo_normal, normalize(_1762)) * _1720.z, 0.0, 1.0);\n        if (_1803 <= 0.0)\n        {\n            continue;\n        }\n        float _1823 = (clamp((0.5 - abs(_1767)) * 10.0, 0.0, 1.0) * _1803) * _1720.x;\n        vec2 _1831 = vec2(_1753 + 0.5, 0.5 - _1760);\n        vec2 _1841 = vec2(dot(_1748, _1637), dot(_1755, _1637));\n        vec2 _1851 = vec2(dot(_1748, _1640), dot(_1755, _1640));\n        int param_8 = _1715 + 5;\n        vec4 _1856 = fa_light_texel(param_8);\n        int param_9 = _1715 + 3;\n        vec4 _1861 = fa_light_texel(param_9);\n        int param_10 = _1715 + 4;\n        vec4 _1866 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1856.xyz;\n        bool _1876 = _1861.z > _1861.x;\n        if (_1876)\n        {\n            vec4 param_11 = _1861;\n            vec2 param_12 = _1831;\n            vec2 param_13 = _1665;\n            vec2 param_14 = _1841;\n            vec2 param_15 = _1851;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1675 > 0.5) && (_1675 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1902 = fa_dc_to_linear(param_16);\n                vec4 _5901 = tx;\n                _5901.x = _1902.x;\n                _5901.y = _1902.y;\n                _5901.z = _1902.z;\n                tx = _5901;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1823 * tex_a) * _1856.w, 0.0, 1.0)));\n        if (_1866.z > _1866.x)\n        {\n            vec4 param_17 = _1866;\n            vec2 param_18 = _1831;\n            vec2 param_19 = _1665;\n            vec2 param_20 = _1841;\n            vec2 param_21 = _1851;\n            vec4 _1946 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1675 > 1.5)\n            {\n                vec3 param_22 = _1946.xyz;\n                vec3 _1956 = fa_dc_to_srgb(param_22);\n                _1950 = _1956;\n            }\n            else\n            {\n                _1950 = _1946.xyz;\n            }\n            vec3 _1965 = (_1950 * 2.0) - vec3(1.0);\n            vec2 _1970 = _1965.xy * _1720.y;\n            vec3 _1992 = (normalize(_1748) * _1970.x) + (normalize(_1755) * _1970.y);\n            vec3 _1995 = normalize(normal);\n            normal = normalize(mix(_1995, normalize((_1995 * max(_1965.z, 0.0500000007450580596923828125)) + (_1992 - (_1995 * dot(_1995, _1992)))), vec3(clamp(_1823 * (_1876 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3379 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3379;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3489 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3495 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3489 > 0.0005000000237487256526947021484375)\n    {\n        if (_3495)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3489;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3489;\n        }\n    }\n    bool _3547 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3547)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3578 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3578)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3495 || _3547) || _3578)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3399 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3402 = _3399.x;\n    float _3404 = _3399.z;\n    vec2 e = vec2(_3402, _3404);\n    if (_3399.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3404)) * ((_3402 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3402)) * ((_3404 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4440 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4445 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4450 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4455 = fa_light_texel(param_3);\n    bool _4458 = _4455.z < 0.5;\n    bool _4466;\n    if (!_4458)\n    {\n        _4466 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4466 = _4458;\n    }\n    if (_4466)\n    {\n        return vec3(0.0);\n    }\n    float _4473 = max(_4440.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4476 = _4445.xyz;\n    vec3 _4480 = _4440.xyz;\n    vec3 _4484 = (fa_world_pos - _4480) / vec3(_4473);\n    vec3 _4493 = min(_4484 + vec3(0.5), (_4476 - vec3(0.5)) - _4484);\n    float _4502 = min(_4493.x, min(_4493.y, _4493.z));\n    if (!(_4502 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4517 = _4476 - vec3(1.0);\n    vec3 _4518 = clamp(_4484, vec3(0.0), _4517);\n    vec3 _4526 = min(floor(_4518), max(_4476 - vec3(2.0), vec3(0.0)));\n    vec3 _4530 = _4518 - _4526;\n    vec3 _4542 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4473));\n    int _4547 = int(_4450.y + 0.5);\n    float _4552 = 0.3257350027561187744140625 * n.y;\n    float _4556 = 0.3257350027561187744140625 * n.z;\n    float _4560 = 0.3257350027561187744140625 * n.x;\n    float _4567 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _4574 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _4583 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _4590 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _4603 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _4610 = 8 + int(_4455.w);\n    float _4637;\n    float _4650;\n    float _4664;\n    for (int k = 0; k < _4610; k++)\n    {\n        float _4623 = float(k & 1);\n        float _4627 = float((k >> 1) & 1);\n        float _4631 = float((k >> 2) & 1);\n        if (_4623 > 0.5)\n        {\n            _4637 = _4530.x;\n        }\n        else\n        {\n            _4637 = 1.0 - _4530.x;\n        }\n        if (_4627 > 0.5)\n        {\n            _4650 = _4530.y;\n        }\n        else\n        {\n            _4650 = 1.0 - _4530.y;\n        }\n        if (_4631 > 0.5)\n        {\n            _4664 = _4530.z;\n        }\n        else\n        {\n            _4664 = 1.0 - _4530.z;\n        }\n        float _4674 = (_4637 * _4650) * _4664;\n        if (!(_4674 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4687 = min(_4526 + vec3(_4623, _4627, _4631), _4517);\n        int _4707 = int(((_4450.x + _4687.x) + (_4445.x * (_4687.y + (_4445.y * _4687.z)))) + 0.5);\n        vec2 _4722 = vec2(float(_4707 % _4547) * 10.0, 1024.0 + (float(_4707 / _4547) * 11.0));\n        vec2 param_4 = _4722 + vec2(9.5, 10.5);\n        vec4 _4730 = fa_gi_fetch(param_4);\n        bool _4733 = _4730.y < 0.5;\n        bool _4742;\n        if (!_4733)\n        {\n            _4742 = _4730.x > _4455.y;\n        }\n        else\n        {\n            _4742 = _4733;\n        }\n        if (_4742)\n        {\n            continue;\n        }\n        vec3 _4754 = _4542 - (_4480 + (_4687 * _4473));\n        float _4757 = length(_4754);\n        vec3 _4763 = _4754 / vec3(max(_4757, 9.9999997473787516355514526367188e-05));\n        float _4773 = max(9.9999997473787516355514526367188e-05, (dot(-_4763, n) + 1.0) * 0.5);\n        float w = _4674 * (_4773 * _4773);\n        vec3 param_5 = _4763;\n        vec2 param_6 = (_4722 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _4793 = fa_gi_fetch(param_6);\n        float _4800 = _4757 / max(_4450.z, 9.9999997473787516355514526367188e-05);\n        float _4803 = _4793.x;\n        if (_4800 > _4803)\n        {\n            float _4816 = max(_4793.y - (_4803 * _4803), 0.0);\n            float _4821 = _4800 - _4803;\n            float _4830 = _4816 / max(_4816 + (_4821 * _4821), 9.9999999600419720025001879548654e-13);\n            w *= ((_4830 * _4830) * _4830);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _4722 + vec2(0.5, 10.5);\n        vec2 param_8 = _4722 + vec2(1.5, 10.5);\n        vec2 param_9 = _4722 + vec2(2.5, 10.5);\n        vec2 param_10 = _4722 + vec2(3.5, 10.5);\n        vec2 param_11 = _4722 + vec2(4.5, 10.5);\n        vec2 param_12 = _4722 + vec2(5.5, 10.5);\n        vec2 param_13 = _4722 + vec2(6.5, 10.5);\n        vec2 param_14 = _4722 + vec2(7.5, 10.5);\n        vec2 param_15 = _4722 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4552)) + (fa_gi_fetch(param_9).xyz * _4556)) + (fa_gi_fetch(param_10).xyz * _4560)) + (fa_gi_fetch(param_11).xyz * _4567)) + (fa_gi_fetch(param_12).xyz * _4574)) + (fa_gi_fetch(param_13).xyz * _4583)) + (fa_gi_fetch(param_14).xyz * _4590)) + (fa_gi_fetch(param_15).xyz * _4603)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4502 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _4958;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _4958 = _4455.x;\n    }\n    else\n    {\n        _4958 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4450.w * _4958);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _4982 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _4987 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _4992 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _4992) && (k < 8); k++)\n    {\n        int param = _4987 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _4982;\n        vec3 _5017 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5022 = param_3 * left;\n        acc += (_5017 * _5022);\n        left -= _5022;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _5051 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5051;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3887;\n    if (fa_lm.z > 0.5)\n    {\n        _3887 = 0.0;\n    }\n    else\n    {\n        _3887 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _3898 = _3887 < 1.0;\n    bool _3904;\n    if (_3898)\n    {\n        int param = li;\n        _3904 = fa_light_baked(param);\n    }\n    else\n    {\n        _3904 = _3898;\n    }\n    return _3904 ? _3887 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _598 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _611 = (c - (ru * hx)) - p;\n        vec3 _617 = ru * (2.0 * hx);\n        float _623 = max(dot(_617, _617), 9.9999999392252902907785028219223e-09);\n        float _627 = dot(_611, _617);\n        float t = clamp((-_627) / _623, 0.0, 1.0);\n        if (_598)\n        {\n            float _642 = dot(r, _617);\n            float _648 = _623 - (_642 * _642);\n            if (abs(_648) > (9.9999997473787516355514526367188e-06 * _623))\n            {\n                t = clamp(((dot(r, _611) * _642) - _627) / _648, 0.0, 1.0);\n            }\n        }\n        return (p + _611) + (_617 * t);\n    }\n    vec3 q = p;\n    float _680 = dot(r, axis);\n    bool _688;\n    if (_598)\n    {\n        _688 = abs(_680) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _688 = _598;\n    }\n    if (_688)\n    {\n        float _698 = dot(c - p, axis) / _680;\n        if (_698 > 0.0)\n        {\n            q = p + (r * _698);\n        }\n    }\n    vec3 _711 = q - c;\n    vec2 xy = vec2(dot(_711, ru), dot(_711, uu));\n    if (shape > 0.5)\n    {\n        float _726 = length(xy);\n        if (_726 > hx)\n        {\n            xy *= (hx / _726);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _518 = dot(d, right);\n    float _522 = dot(d, up);\n    float _533;\n    if (((_518 * _518) + (_522 * _522)) > 1.0000000133514319600180897396058e-10)\n    {\n        _533 = atan(_522, _518) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _533 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_533 - floor(_533)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _368 = abs(d);\n    float _370 = _368.x;\n    float _372 = _368.y;\n    bool _373 = _370 >= _372;\n    bool _381;\n    if (_373)\n    {\n        _381 = _370 >= _368.z;\n    }\n    else\n    {\n        _381 = _373;\n    }\n    int _382;\n    if (_381)\n    {\n        _382 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _397;\n        if (_372 >= _368.z)\n        {\n            _397 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _397 = (d.z > 0.0) ? 4 : 5;\n        }\n        _382 = _397;\n    }\n    return _382;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _764 = fa_light_base(param);\n    bool _768 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _764;\n    vec4 _772 = fa_light_texel(param_1);\n    int param_2 = _764 + 1;\n    vec4 _777 = fa_light_texel(param_2);\n    float _780 = _777.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _792 = _768 && (_780 > 2.5);\n    fa_light_is_area = _792;\n    bool _794 = _780 < 0.5;\n    vec3 l;\n    if (_794)\n    {\n        l = normalize(_772.xyz);\n        if (_768)\n        {\n            int param_3 = _764 + 6;\n            vec4 _808 = fa_light_texel(param_3);\n            if (_808.z > 0.5)\n            {\n                int param_4 = _764 + 4;\n                vec4 _818 = fa_light_texel(param_4);\n                int param_5 = _764 + 5;\n                vec4 _823 = fa_light_texel(param_5);\n                vec2 param_6 = _808.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _818.xyz) * _818.w, (-dot(world_pos, _823.xyz)) * _823.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _853 = _772.xyz;\n        vec3 _855 = _853 - world_pos;\n        vec3 to_light = _855;\n        float _858 = length(_855);\n        float reach = _858;\n        bool front = true;\n        if (_792)\n        {\n            int param_8 = _764 + 7;\n            reach = max(_858 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _764 + 4;\n            vec4 _882 = fa_light_texel(param_9);\n            int param_10 = _764 + 5;\n            vec4 _887 = fa_light_texel(param_10);\n            int param_11 = _764 + 6;\n            vec4 _892 = fa_light_texel(param_11);\n            float _893 = _892.w;\n            int param_12 = _764 + 2;\n            vec3 _900 = normalize(fa_light_texel(param_12).xyz);\n            bool _902 = _893 > 1.5;\n            bool _910;\n            if (!_902)\n            {\n                _910 = dot(_900, to_light) < 0.0;\n            }\n            else\n            {\n                _910 = _902;\n            }\n            front = _910;\n            vec3 r = vec3(0.0);\n            vec3 _919 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _923 = dot(n, n) > 0.5;\n            bool _931;\n            if (_923)\n            {\n                _931 = dot(_919, _919) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _931 = _923;\n            }\n            if (_931)\n            {\n                r = reflect(-normalize(_919), normalize(n));\n            }\n            vec3 param_13 = _853;\n            vec3 param_14 = _900;\n            vec3 param_15 = _882.xyz;\n            vec3 param_16 = _887.xyz;\n            float param_17 = _882.w;\n            float param_18 = _887.w;\n            float param_19 = _893;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _967 = length(to_light);\n        dist = _967;\n        l = to_light / vec3(max(_967, 9.9999997473787516355514526367188e-05));\n        float _981 = reach / max(_772.w, 0.001000000047497451305389404296875);\n        float _987 = clamp(1.0 - (_981 * _981), 0.0, 1.0);\n        float _989;\n        if (front)\n        {\n            _989 = _987 * _987;\n        }\n        else\n        {\n            _989 = 0.0;\n        }\n        atten = _989;\n        bool _1000 = _780 < 2.5;\n        if ((_780 > 1.5) && _1000)\n        {\n            int param_22 = _764 + 2;\n            vec4 _1008 = fa_light_texel(param_22);\n            float _1018 = _1008.w;\n            int param_23 = _764 + 3;\n            vec4 _1023 = fa_light_texel(param_23);\n            float _1024 = _1023.x;\n            float cos_inner = _1024;\n            if (_1024 > 1.5)\n            {\n                cos_inner = mix(_1018, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1018, cos_inner, dot(-l, normalize(_1008.xyz)));\n        }\n        if (_768 && (_780 < 1.5))\n        {\n            int param_24 = _764 + 6;\n            vec4 _1048 = fa_light_texel(param_24);\n            if (_1048.z > 0.5)\n            {\n                vec3 _1056 = -to_light;\n                int param_25 = _764 + 4;\n                int param_26 = _764 + 5;\n                vec3 _1070 = fa_light_texel(param_25).xyz;\n                vec3 _1074 = fa_light_texel(param_26).xyz;\n                vec3 _1083 = vec3(dot(_1056, _1070), dot(_1056, _1074), dot(_1056, cross(_1070, _1074)));\n                vec3 param_27 = _1083;\n                int _1087 = fa_cube_face(param_27);\n                int param_28 = _1087;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1114 = vec2(dot(_1083, cross(param_29, param_30)), dot(_1083, param_30)) / vec2(max(dot(_1083, param_29), 9.9999997473787516355514526367188e-05));\n                int _1118 = _1087 / 3;\n                vec2 param_31 = _1048.xy + (vec2(float(_1087 - (_1118 * 3)), float(_1118)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1114.x), 0.5 - (0.5 * _1114.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _764 + 7;\n            vec4 _1148 = fa_light_texel(param_33);\n            if (_1148.z > 0.5)\n            {\n                int param_34 = _764 + 2;\n                int param_35 = _764 + 4;\n                int param_36 = _764 + 5;\n                vec2 param_37 = _1148.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_768 && _1000)\n            {\n                int param_42 = _764 + 6;\n                vec4 _1195 = fa_light_texel(param_42);\n                int param_43 = _764 + 7;\n                vec4 _1200 = fa_light_texel(param_43);\n                bool _1203 = _1195.z > 0.5;\n                bool _1210;\n                if (!_1203)\n                {\n                    _1210 = _1200.z > 0.5;\n                }\n                else\n                {\n                    _1210 = _1203;\n                }\n                if (_1210)\n                {\n                    int param_44 = _764 + 2;\n                    vec4 _1217 = fa_light_texel(param_44);\n                    vec3 _1221 = normalize(_1217.xyz);\n                    int param_45 = _764 + 4;\n                    vec4 _1226 = fa_light_texel(param_45);\n                    int param_46 = _764 + 5;\n                    vec4 _1231 = fa_light_texel(param_46);\n                    if (_1203)\n                    {\n                        vec3 _1239 = -to_light;\n                        float _1246 = _1217.w;\n                        float _1262 = 0.5 / max(dot(_1239, _1221) * (sqrt(max(1.0 - (_1246 * _1246), 0.0)) / max(_1246, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1195.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1239, _1226.xyz) * _1262), 0.5 - (dot(_1239, _1231.xyz) * _1262));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1200.z > 0.5)\n                    {\n                        vec2 param_49 = _1200.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1221;\n                        vec3 param_52 = _1226.xyz;\n                        vec3 param_53 = _1231.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5767 = _777.xyz * atten;\n    if (_768)\n    {\n        _5767 *= fa_light_tint;\n    }\n    int _1330;\n    if (_794)\n    {\n        _1330 = 0;\n    }\n    else\n    {\n        _1330 = ((_780 > 1.5) && (_780 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5767, atten, 1.0, dist, _1330);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2119 = fa_shadow_depth(param, param_1);\n    float _2123;\n    if (conv.x < 0.5)\n    {\n        _2123 = _2119;\n    }\n    else\n    {\n        _2123 = (conv.y * conv.z) / (conv.z - (_2119 * (conv.z - conv.y)));\n    }\n    return _2123;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2169 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2175 = vec2(cos(_2169), sin(_2169));\n    vec2 dir = _2175;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2184;\n        if (k < 0.0)\n        {\n            _2184 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2184 = k;\n        }\n        float _2203 = clamp((_2184 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2222 = sqrt((float(i) + 0.5) * 0.0625) * _2203;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2222));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2236 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2236 < (zr - (_2222 * plane)))\n            {\n                sum += _2236;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2264 = sum / cnt;\n        float _2274;\n        if (k < 0.0)\n        {\n            _2274 = (-k) / max(_2264, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2274 = k;\n        }\n        radius = clamp(((max(zr - _2264, 0.0) * unit) * _2274) / texel_m, 1.5, 16.0);\n        dir = _2175;\n    }\n    float lit = 0.0;\n    int _2300 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2300; i_1++)\n    {\n        float _2319 = sqrt((float(i_1) + 0.5) / float(_2300)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2319));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2319 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2300);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2524 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2531;\n    if (!_2524)\n    {\n        _2531 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2531 = _2524;\n    }\n    if (_2531)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2544 = fa_light_texel(param);\n    float _2545 = _2544.x;\n    if (_2545 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2554 = int(_2545 + 0.5);\n    int param_1 = _2554;\n    vec4 _2558 = fa_light_texel(param_1);\n    int param_2 = _2554 + 1;\n    vec4 _2563 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2566 = _2558.y;\n    if (_2566 > 0.0)\n    {\n        float _2583 = 1.0 - smoothstep(0.75 * _2566, _2566, length(world - fa_shadows[27].xyz));\n        fade = _2583;\n        if (_2583 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2558.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2607 = (_2554 + 2) + (face * 6);\n    int param_4 = _2607;\n    int param_5 = _2607 + 1;\n    int param_6 = _2607 + 3;\n    vec4 _2621 = fa_light_texel(param_6);\n    int param_7 = _2607 + 4;\n    vec4 _2626 = fa_light_texel(param_7);\n    int param_8 = _2607 + 5;\n    vec4 _2631 = fa_light_texel(param_8);\n    float _2643 = _2631.x * max(dot(_2621, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2648 = clamp(dot(n, l), 0.0, 1.0);\n    float _2671 = clamp(dot(n, _2621.xyz), -1.0, 1.0);\n    float _2690 = min(sqrt(1.0 - (_2671 * _2671)) / max(abs(dot(n, world - lpos)) / max(dot(_2621, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2693 = _2563.y;\n    float _2695;\n    if (_2693 > 0.0)\n    {\n        _2695 = _2693;\n    }\n    else\n    {\n        _2695 = 1.5 * _2643;\n    }\n    vec4 _2715 = vec4(world + (n * (_2695 * sqrt(1.0 - (_2648 * _2648)))), 1.0);\n    float _2719 = dot(_2621, _2715);\n    float _2722 = _2631.y;\n    if (_2719 < _2722)\n    {\n        return 1.0;\n    }\n    vec2 _2737 = vec2(dot(fa_light_texel(param_4), _2715), dot(fa_light_texel(param_5), _2715)) / vec2(_2719);\n    float _2739 = _2737.x;\n    bool _2742 = _2739 < _2626.x;\n    bool _2751;\n    if (!_2742)\n    {\n        _2751 = _2739 > _2626.z;\n    }\n    else\n    {\n        _2751 = _2742;\n    }\n    bool _2760;\n    if (!_2751)\n    {\n        _2760 = _2737.y < _2626.y;\n    }\n    else\n    {\n        _2760 = _2751;\n    }\n    bool _2769;\n    if (!_2760)\n    {\n        _2769 = _2737.y > _2626.w;\n    }\n    else\n    {\n        _2769 = _2760;\n    }\n    if (_2769)\n    {\n        return 1.0;\n    }\n    float _2775 = _2563.x;\n    float _2777;\n    if (_2775 > 0.0)\n    {\n        _2777 = _2775;\n    }\n    else\n    {\n        _2777 = 1.5 * _2643;\n    }\n    vec2 param_9 = _2737;\n    vec4 param_10 = _2626;\n    float param_11 = _2719 - (_2777 * (1.0 + (0.5 * _2690)));\n    float param_12 = _2643;\n    float param_13 = 1.0;\n    float param_14 = _2631.z * 0.25;\n    float param_15 = (_2643 * min(_2690, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2722, _2631.z);\n    int param_17 = int(_2558.z + 0.5);\n    float param_18 = _2558.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2062;\n    if (i == 0)\n    {\n        _2062 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2078;\n        if (i == 1)\n        {\n            _2078 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2086;\n            if (i == 2)\n            {\n                _2086 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2086 = fa_shadows[24].w;\n            }\n            _2078 = _2086;\n        }\n        _2062 = _2078;\n    }\n    return _2062;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2365 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2370 = clamp(dot(n, l), 0.0, 1.0);\n    float _2376 = sqrt(1.0 - (_2370 * _2370));\n    float _2384 = min(_2376 / max(_2370, 0.20000000298023223876953125), 4.0);\n    float _2389;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2389 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2389 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2414 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2389 * _2376)), 1.0);\n    float _2421 = _2414.x;\n    bool _2424 = _2421 < fa_shadows[ci * 1 + 16].x;\n    bool _2433;\n    if (!_2424)\n    {\n        _2433 = _2421 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2433 = _2424;\n    }\n    bool _2442;\n    if (!_2433)\n    {\n        _2442 = _2414.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2442 = _2433;\n    }\n    bool _2451;\n    if (!_2442)\n    {\n        _2451 = _2414.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2451 = _2442;\n    }\n    bool _2458;\n    if (!_2451)\n    {\n        _2458 = _2414.z > 1.0;\n    }\n    else\n    {\n        _2458 = _2451;\n    }\n    if (_2458)\n    {\n        return -1.0;\n    }\n    float _2466;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2466 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2466 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2414.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2414.z - ((_2466 * (1.0 + (0.5 * _2384))) / _2365);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2365;\n    float param_5 = _2365 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2384, 3.0)) * 0.5) / _2365;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2844 = int(fa_shadows[25].x + 0.5);\n    if (_2844 < 1)\n    {\n        return 1.0;\n    }\n    float _2859 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2844 - 1;\n    if (_2859 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2871 = _2844 > 1;\n    bool _2878;\n    if (_2871)\n    {\n        _2878 = _2859 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2878 = _2871;\n    }\n    if (_2878)\n    {\n        ci = 1;\n    }\n    bool _2882 = _2844 > 2;\n    bool _2889;\n    if (_2882)\n    {\n        _2889 = _2859 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2889 = _2882;\n    }\n    if (_2889)\n    {\n        ci = 2;\n    }\n    bool _2893 = _2844 > 3;\n    bool _2900;\n    if (_2893)\n    {\n        _2900 = _2859 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2900 = _2893;\n    }\n    if (_2900)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2911 = min(_2844, 4);\n    float _2952;\n    for (int c = ci; c < _2911; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2931 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2931;\n            break;\n        }\n        if (_2931 < 0.0)\n        {\n            continue;\n        }\n        s = _2931;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2952 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2952 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _2971 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2952, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2859 - (fa_shadow_split_at(param_7) - _2971)) / _2971, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3003;\n        if ((ci + 1) < _2844)\n        {\n            _3003 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3003 = 1.0;\n        }\n        s = mix(s, _3003, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3108 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3114;\n    if (_3108)\n    {\n        _3114 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3114 = _3108;\n    }\n    if (_3114)\n    {\n        float _3128 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3131 = fwidth(_3128);\n        vec4 _3141 = vec4(fa_world_pos, 1.0);\n        float _3147 = dot(fa_mesh_fs_params[28], _3141);\n        if (_3147 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3166 = vec2(dot(fa_mesh_fs_params[26], _3141), dot(fa_mesh_fs_params[27], _3141)) / vec2(_3147);\n            float _3171 = (_3166.x * 0.5) + 0.5;\n            float _3175;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3175 = (_3166.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3175 = 0.5 - (_3166.y * 0.5);\n            }\n            bool _3191 = _3171 >= 0.0;\n            bool _3197;\n            if (_3191)\n            {\n                _3197 = _3171 < 1.0;\n            }\n            else\n            {\n                _3197 = _3191;\n            }\n            bool _3203;\n            if (_3197)\n            {\n                _3203 = _3175 >= 0.0;\n            }\n            else\n            {\n                _3203 = _3197;\n            }\n            bool _3209;\n            if (_3203)\n            {\n                _3209 = _3175 < 1.0;\n            }\n            else\n            {\n                _3209 = _3203;\n            }\n            if (_3209)\n            {\n                vec4 _3235 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3171, _3175) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3238 = _3235.w > 0.5;\n                bool _3254;\n                if (_3238)\n                {\n                    _3254 = abs(_3128 - _3235.x) <= (((0.00200000009499490261077880859375 * _3128) + 0.00999999977648258209228515625) + min(1.5 * _3131, 0.100000001490116119384765625 * _3128));\n                }\n                else\n                {\n                    _3254 = _3238;\n                }\n                if (_3254)\n                {\n                    float _3260;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3260 = min(_3235.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3260 = _3235.y;\n                    }\n                    return _3260;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3629 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3636;\n    if (!_3629)\n    {\n        _3636 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3636 = _3629;\n    }\n    if (_3636)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3649 = fa_light_texel(param);\n    float _3650 = _3649.y;\n    float len = _3650;\n    if (_3650 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3662 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3671 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3662);\n    if (_3671 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3677 = len;\n    float _3680 = min(_3677, 0.89999997615814208984375 * dist);\n    len = _3680;\n    float _3686 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3662);\n    float _3691 = _3686 + (0.5 * _3680);\n    vec3 _3697 = world + (gn * _3686);\n    float _3699 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3761;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3715 = (float(k) + _3699) * 0.083333335816860198974609375;\n        vec3 _3723 = _3697 + (l * (_3715 * len));\n        vec4 _3729 = vec4(_3723, 1.0);\n        float _3734 = dot(fa_mesh_fs_params[28], _3729);\n        if (_3734 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3752 = vec2(dot(fa_mesh_fs_params[26], _3729), dot(fa_mesh_fs_params[27], _3729)) / vec2(_3734);\n        float _3756 = _3752.x * 0.5;\n        float _3757 = _3756 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3761 = (_3752.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3761 = 0.5 - (_3752.y * 0.5);\n        }\n        bool _3777 = _3757 < 0.0;\n        bool _3784;\n        if (!_3777)\n        {\n            _3784 = _3757 >= 1.0;\n        }\n        else\n        {\n            _3784 = _3777;\n        }\n        bool _3791;\n        if (!_3784)\n        {\n            _3791 = _3761 < 0.0;\n        }\n        else\n        {\n            _3791 = _3784;\n        }\n        bool _3798;\n        if (!_3791)\n        {\n            _3798 = _3761 >= 1.0;\n        }\n        else\n        {\n            _3798 = _3791;\n        }\n        if (_3798)\n        {\n            break;\n        }\n        vec4 _3822 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3757, _3761) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_3822.w < 0.5)\n        {\n            continue;\n        }\n        float _3840 = (dot(fa_mesh_fs_params[29].xyz, _3723) + fa_mesh_fs_params[29].w) - _3822.x;\n        if ((_3840 > _3686) && (_3840 < _3691))\n        {\n            occ = max(occ, (1.0 - (_3715 * _3715)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3757, 0.5 - _3756), min(_3761, 1.0 - _3761))));\n        }\n    }\n    return 1.0 - (occ * _3671);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3943 = fa_baked_keep(param);\n    if (_3943 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3969 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5793 = _3969.color;\n    float _5794 = _3969.attenuation;\n    float _5795 = _3969.shadow;\n    bool _3972 = _3969.type == 0;\n    if (_3972 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3969.direction;\n        float _3983 = fa_shadow_factor(param_5, param_6);\n        _5795 = _3983;\n        _5793 *= _3983;\n    }\n    else\n    {\n        bool _3994 = _3969.type != 0;\n        bool _4000;\n        if (_3994)\n        {\n            _4000 = _5794 > 0.0;\n        }\n        else\n        {\n            _4000 = _3994;\n        }\n        if (_4000)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3969.direction;\n            float _4019 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5795 = _4019;\n            _5793 *= _4019;\n        }\n    }\n    bool _4029 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4035;\n    if (_4029)\n    {\n        _4035 = _5794 > 0.0;\n    }\n    else\n    {\n        _4035 = _4029;\n    }\n    if (_4035)\n    {\n        float _4042;\n        if (_3972)\n        {\n            _4042 = 1000000000.0;\n        }\n        else\n        {\n            _4042 = _3969._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3969.direction;\n        float param_18 = _4042;\n        float _4060 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5795 *= _4060;\n        _5793 *= _4060;\n    }\n    float _4073 = _5794;\n    float _4074 = _4073 * _3943;\n    _5794 = _4074;\n    vec3 _4078 = _5793;\n    vec3 _4079 = _4078 * _3943;\n    _5793 = _4079;\n    return LightSample(_3969.direction, _4079, _4074, _5795, _3969._distance, _3969.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3031 = int(fa_shadows[25].x + 0.5);\n    float _3041 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3046 = _3031 > 0;\n    bool _3055;\n    if (_3046)\n    {\n        int param = _3031 - 1;\n        _3055 = _3041 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3055 = _3046;\n    }\n    if (_3055)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3061 = _3031 > 1;\n        bool _3068;\n        if (_3061)\n        {\n            _3068 = _3041 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3068 = _3061;\n        }\n        if (_3068)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3074 = _3031 > 2;\n        bool _3081;\n        if (_3074)\n        {\n            _3081 = _3041 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3081 = _3074;\n        }\n        if (_3081)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3087 = _3031 > 3;\n        bool _3094;\n        if (_3087)\n        {\n            _3094 = _3041 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3094 = _3087;\n        }\n        if (_3094)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5585 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5585 = -_5585;\n    }\n    vec3 _5159 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5585, fa_world_tangent, fa_uv, fa_vertex_color, _5159, gl_FrontFacing);\n    Surface _5167 = fa_standard_surface(param_1);\n    vec3 _5624 = _5167.albedo;\n    float _5625 = _5167.alpha;\n    vec3 _5626 = _5167.normal;\n    float _5627 = _5167.metallic;\n    float _5628 = _5167.roughness;\n    float _5629 = _5167.occlusion;\n    vec3 _5630 = _5167.emission;\n    float _5631 = _5167.clearcoat;\n    float _5632 = _5167.clearcoat_roughness;\n    vec3 _5633 = _5167.sheen_color;\n    float _5634 = _5167.sheen_roughness;\n    float _5635 = _5167.anisotropy;\n    float _5636 = _5167.anisotropy_rotation;\n    float _5637 = _5167.specular;\n    float _5638 = _5167.ior;\n    vec3 _5639 = _5167.specular_color;\n    float _5640 = _5167.transmission;\n    float _5641 = _5167.thickness;\n    vec3 _5642 = _5167.attenuation_color;\n    float _5643 = _5167.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5585, fa_world_tangent, fa_uv, fa_vertex_color, _5159, gl_FrontFacing);\n    Surface param_3 = _5167;\n    surface(param_2, param_3);\n    _5624 = param_3.albedo;\n    _5625 = param_3.alpha;\n    _5626 = param_3.normal;\n    _5627 = param_3.metallic;\n    _5628 = param_3.roughness;\n    _5629 = param_3.occlusion;\n    _5630 = param_3.emission;\n    _5631 = param_3.clearcoat;\n    _5632 = param_3.clearcoat_roughness;\n    _5633 = param_3.sheen_color;\n    _5634 = param_3.sheen_roughness;\n    _5635 = param_3.anisotropy;\n    _5636 = param_3.anisotropy_rotation;\n    _5637 = param_3.specular;\n    _5638 = param_3.ior;\n    _5639 = param_3.specular_color;\n    _5640 = param_3.transmission;\n    _5641 = param_3.thickness;\n    _5642 = param_3.attenuation_color;\n    _5643 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5585;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5624 = param_6;\n    _5626 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5624;\n    }\n    else\n    {\n        vec3 _5206 = _5626;\n        vec3 _5207 = normalize(_5206);\n        _5626 = _5207;\n        vec3 param_8 = _5207;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _5585, fa_world_tangent, fa_uv, fa_vertex_color, _5159, gl_FrontFacing);\n        Surface param_10 = Surface(_5624, _5625, _5626, _5627, _5628, _5629, _5630, _5631, _5632, _5633, _5634, _5635, _5636, _5637, _5638, _5639, _5640, _5641, _5642, _5643);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _5226 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5226; ln++)\n        {\n            int param_12 = ln;\n            int _5239 = fa_cl_light(param_12);\n            int param_13 = _5239;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _5239;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _5585;\n            LightSample _5255 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _5585, fa_world_tangent, fa_uv, fa_vertex_color, _5159, gl_FrontFacing);\n            Surface param_18 = Surface(_5624, _5625, _5626, _5627, _5628, _5629, _5630, _5631, _5632, _5633, _5634, _5635, _5636, _5637, _5638, _5639, _5640, _5641, _5642, _5643);\n            LightSample param_19 = _5255;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _5270 = result;\n    vec3 _5271 = _5270 + _5630;\n    result = _5271;\n    vec3 param_20 = _5271;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5280 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5287;\n    if (!_5280)\n    {\n        _5287 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5287 = _5280;\n    }\n    if (_5287)\n    {\n        vec3 _5296 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5302 = dot(_5296, fa_mesh_fs_params[9].xyz);\n        bool _5306 = fa_mesh_fs_params[9].w > 0.5;\n        float _5307;\n        if (_5306)\n        {\n            _5307 = _5302;\n        }\n        else\n        {\n            _5307 = length(_5296);\n        }\n        float _5319 = _5307 - fa_mesh_fs_params[8].x;\n        if (_5319 > 0.0)\n        {\n            float _5328 = fa_mesh_fs_params[7].w * _5319;\n            float tau = _5328 * _5328;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5344;\n                if (_5306)\n                {\n                    _5344 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5302);\n                }\n                else\n                {\n                    _5344 = fa_mesh_fs_params[0].y;\n                }\n                float _5365 = mix(_5344, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5307, 0.0, 1.0));\n                float _5369 = fa_world_pos.y - _5365;\n                float _5374 = _5365 - fa_mesh_fs_params[8].z;\n                float _5379 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5382 = _5374 <= 0.0;\n                bool _5383 = !_5382;\n                bool _5389;\n                if (_5383)\n                {\n                    _5389 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5389 = _5382;\n                }\n                float _5390;\n                if (_5389)\n                {\n                    _5390 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5390 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5374, 80.0));\n                }\n                bool _5417;\n                if (_5383)\n                {\n                    _5417 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5417 = _5382;\n                }\n                float _5418;\n                if (_5417)\n                {\n                    _5418 = fa_mesh_fs_params[8].y * _5374;\n                }\n                else\n                {\n                    _5418 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5374, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5443 = _5379 <= 0.0;\n                bool _5450;\n                if (!_5443)\n                {\n                    _5450 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5450 = _5443;\n                }\n                float _5451;\n                if (_5450)\n                {\n                    _5451 = fa_mesh_fs_params[8].y * _5379;\n                }\n                else\n                {\n                    _5451 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5379, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5478;\n                if (abs(_5369) < 0.001000000047497451305389404296875)\n                {\n                    _5478 = _5390;\n                }\n                else\n                {\n                    _5478 = (_5451 - _5418) / _5369;\n                }\n                tau += (_5319 * max(_5478, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5625);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_420",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
            "inst_name": "_2072",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_prev_r0;\nlayout(location = 10) in vec4 fa_prev_r1;\nlayout(location = 11) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _455 = _246.world_pos;\n    mat4 _250 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _257 = vec4(_455, 1.0);\n    fa_world_pos = _455;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -(_250 * _257).z;\n    fa_pre_r0 = vec3(_250[0].x, _250[1].x, _250[2].x);\n    fa_pre_r1 = vec3(_250[0].y, _250[1].y, _250[2].y);\n    fa_pre_r2 = vec3(_250[0].z, _250[1].z, _250[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _257;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_231)\n    {\n        vec4 _330 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _257).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_455 + (fa_prev_model() * _330).xyz) - (model * _330).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    vec4 _246 = (_889 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _844 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = fa_mesh_fs_params[20].x;\n    float _850 = fa_mesh_fs_params[20].y;\n    float _853 = fa_mesh_fs_params[20].z;\n    float _852 = fa_mesh_fs_params[21].w;\n    float _855 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _844, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _849, _850, fa_mesh_fs_params[21].xyz, _852, _853, fa_mesh_fs_params[20].w, _855, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r2"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_57",
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
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_225",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 9,
                "offset": 0,
                "glsl_name": "fa_vel_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_204 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_204 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_204 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _720 = _490.world_pos;\n    mat4 _494 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _501 = vec4(_720, 1.0);\n    fa_world_pos = _720;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -(_494 * _501).z;\n    fa_pre_r0 = vec3(_494[0].x, _494[1].x, _494[2].x);\n    fa_pre_r1 = vec3(_494[0].y, _494[1].y, _494[2].y);\n    fa_pre_r2 = vec3(_494[0].z, _494[1].z, _494[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _501;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_475)\n    {\n        vec4 _574 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _501).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_720 + (fa_prev_model() * _574).xyz) - (model * _574).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    vec4 _246 = (_889 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _844 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = fa_mesh_fs_params[20].x;\n    float _850 = fa_mesh_fs_params[20].y;\n    float _853 = fa_mesh_fs_params[20].z;\n    float _852 = fa_mesh_fs_params[21].w;\n    float _855 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _844, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _849, _850, fa_mesh_fs_params[21].xyz, _852, _853, fa_mesh_fs_params[20].w, _855, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 13,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r2"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_74",
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
            "inst_name": "_213",
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
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_470",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 9,
                "offset": 0,
                "glsl_name": "fa_vel_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
          },
          {
            "texture": {
              "slot": 29,
              "stage": "vertex",
              "name": "fa_prev_pal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 11,
            "stage": "vertex",
            "name": "fa_prev_pal_smp",
            "sampler_type": "nonfiltering"
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
            "stage": "vertex",
            "name": "fa_prev_pal_tex_fa_prev_pal_smp",
            "view_name": "fa_prev_pal_tex",
            "sampler_name": "fa_prev_pal_smp",
            "view_slot": 29,
            "sampler_slot": 11,
            "glsl_name": "fa_prev_pal_tex_fa_prev_pal_smp"
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
          }
        ]
      }
    }
  }
}
