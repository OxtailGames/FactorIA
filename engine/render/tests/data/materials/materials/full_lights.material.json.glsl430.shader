{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "e358a7feb715feb1de20536d5d32a92796c655eba3051c35dd264669efa3bd15",
  "slang": "glsl430",
  "params": [
    "base"
  ],
  "textures": [],
  "full": true,
  "shadow": "none",
  "prepass": false,
  "passes": [
    {
      "name": "main",
      "cull": "back",
      "depthTest": true,
      "depthWrite": true,
      "blend": "none",
      "program": "mesh",
      "programSkin": "mesh_skin"
    }
  ],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 0) out vec3 v_pos;\nlayout(location = 1) out vec3 v_normal;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 2) out vec4 v_shadow;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 4) in vec4 fa_color;\nmat4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nvec3 fa_world_position(vec3 p)\n{\n    return (fa_model * vec4(p, 1.0)).xyz;\n}\n\nvec3 fa_world_direction(vec3 n)\n{\n    vec3 _61 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_61 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _61) < 0.0) ? (-1.0) : 1.0));\n}\n\nvec4 fa_shadow_coord(vec3 world)\n{\n    return vec4(world, 1.0);\n}\n\nvoid fa_user_main()\n{\n    vec3 param = fa_position;\n    vec3 _109 = fa_world_position(param);\n    v_pos = _109;\n    vec3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    vec3 param_2 = _109;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_109, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    fa_model = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    fa_user_main();\n}\n\n",
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_light_tex_fa_full_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_full_light_tex_fa_full_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _110 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _117 = fa_light_texel(param_1);\n    float _122 = _117.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _130 = _122 < 0.5;\n    vec3 l;\n    if (_130)\n    {\n        l = normalize(_110.xyz);\n    }\n    else\n    {\n        vec3 _142 = _110.xyz - world_pos;\n        float _144 = length(_142);\n        dist = _144;\n        l = _142 / vec3(max(_144, 9.9999997473787516355514526367188e-05));\n        float _159 = _144 / max(_110.w, 0.001000000047497451305389404296875);\n        float _165 = clamp(1.0 - (_159 * _159), 0.0, 1.0);\n        atten = _165 * _165;\n        if (_122 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _180 = fa_light_texel(param_2);\n            float _190 = _180.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _197 = fa_light_texel(param_3);\n            float _199 = _197.x;\n            float cos_inner = _199;\n            if (_199 > 1.5)\n            {\n                cos_inner = mix(_190, 1.0, 0.25);\n            }\n            atten *= smoothstep(_190, cos_inner, dot(-l, normalize(_180.xyz)));\n        }\n    }\n    int _230;\n    if (_130)\n    {\n        _230 = 0;\n    }\n    else\n    {\n        _230 = (_122 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _117.xyz * atten, atten, 1.0, dist, _230);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _282;\n    if (i == 0)\n    {\n        _282 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _299;\n        if (i == 1)\n        {\n            _299 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _308;\n            if (i == 2)\n            {\n                _308 = fa_shadows[24].z;\n            }\n            else\n            {\n                _308 = fa_shadows[24].w;\n            }\n            _299 = _308;\n        }\n        _282 = _299;\n    }\n    return _282;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_full_shadow_tex_fa_full_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _270 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_270), sin(_270)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _348 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _353 = clamp(dot(n, l), 0.0, 1.0);\n    float _359 = sqrt(1.0 - (_353 * _353));\n    float _367 = min(_359 / max(_353, 0.20000000298023223876953125), 4.0);\n    float _372;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _372 = fa_shadows[26].y;\n    }\n    else\n    {\n        _372 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _397 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_372 * _359)), 1.0);\n    float _404 = _397.x;\n    bool _407 = _404 < fa_shadows[ci * 1 + 16].x;\n    bool _416;\n    if (!_407)\n    {\n        _416 = _404 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _416 = _407;\n    }\n    bool _425;\n    if (!_416)\n    {\n        _425 = _397.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _425 = _416;\n    }\n    bool _434;\n    if (!_425)\n    {\n        _434 = _397.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _434 = _425;\n    }\n    bool _441;\n    if (!_434)\n    {\n        _441 = _397.z > 1.0;\n    }\n    else\n    {\n        _441 = _434;\n    }\n    if (_441)\n    {\n        return -1.0;\n    }\n    float _450;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _450 = fa_shadows[26].x;\n    }\n    else\n    {\n        _450 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _469 = _397.z - ((_450 * (1.0 + (0.5 * _367))) / _348);\n    float _478 = ((fa_shadows[ci * 1 + 20].x * min(_367, 3.0)) * 0.5) / _348;\n    int _487 = int(fa_shadows[25].z + 0.5);\n    if (_487 == 1)\n    {\n        vec2 param = _397.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _498 = fa_shadow_depth(param, param_1);\n        return float(_469 <= _498);\n    }\n    float _505 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _508 = _487 == 2;\n    if (_508)\n    {\n        float _522 = clamp(((fa_shadows[25].w * _348) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _505;\n            vec2 _542 = fa_shadow_vogel(param_2, param_3, param_4) * _522;\n            vec2 param_5 = _397.xy + (_542 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _553 = fa_shadow_depth(param_5, param_6);\n            if (_553 < (_469 - (length(_542) * _478)))\n            {\n                sum += _553;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_469 - (sum / cnt), 0.0) * _348) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _597 = _508 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _597; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _597;\n        float param_9 = _505;\n        vec2 _616 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _397.xy + (_616 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _627 = fa_shadow_depth(param_10, param_11);\n        lit += float((_469 - (length(_616) * _478)) <= _627);\n    }\n    return lit / float(_597);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _660 = int(fa_shadows[25].x + 0.5);\n    if (_660 < 1)\n    {\n        return 1.0;\n    }\n    float _677 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _660 - 1;\n    if (_677 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _689 = _660 > 1;\n    bool _696;\n    if (_689)\n    {\n        _696 = _677 > fa_shadows[24].x;\n    }\n    else\n    {\n        _696 = _689;\n    }\n    if (_696)\n    {\n        ci = 1;\n    }\n    bool _700 = _660 > 2;\n    bool _707;\n    if (_700)\n    {\n        _707 = _677 > fa_shadows[24].y;\n    }\n    else\n    {\n        _707 = _700;\n    }\n    if (_707)\n    {\n        ci = 2;\n    }\n    bool _711 = _660 > 3;\n    bool _718;\n    if (_711)\n    {\n        _718 = _677 > fa_shadows[24].z;\n    }\n    else\n    {\n        _718 = _711;\n    }\n    if (_718)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _660)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _744 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _744;\n        if (_744 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _769;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _769 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _769 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _788 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _769, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _799 = clamp((_677 - (fa_shadow_split_at(param_7) - _788)) / _788, 0.0, 1.0);\n        if (_799 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _660)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _820 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _820;\n                if (_820 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _799);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec3 param = coord.xyz / vec3(coord.w);\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _859 = fa_light_sample(param, param_1);\n    vec3 _1213 = _859.direction;\n    vec3 _1208 = _859.color;\n    float _1210 = _859.shadow;\n    int _1218 = _859.type;\n    if ((_1218 == 0) && (li == 0))\n    {\n        vec4 param_2 = coord;\n        vec3 param_3 = gn;\n        vec3 param_4 = _1213;\n        float _875 = fa_shadow(param_2, param_3, param_4);\n        _1210 = _875;\n        _1208 *= _875;\n    }\n    return LightSample(_1213, _1208, _859.attenuation, _1210, _859._distance, _1218);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _888 = fa_mesh_fs_params[7].w > 0.0;\n    bool _896;\n    if (!_888)\n    {\n        _896 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _896 = _888;\n    }\n    if (_896)\n    {\n        vec3 _904 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _911 = dot(_904, fa_mesh_fs_params[9].xyz);\n        bool _915 = fa_mesh_fs_params[9].w > 0.5;\n        float _916;\n        if (_915)\n        {\n            _916 = _911;\n        }\n        else\n        {\n            _916 = length(_904);\n        }\n        float _928 = _916 - fa_mesh_fs_params[8].x;\n        if (_928 > 0.0)\n        {\n            float _937 = fa_mesh_fs_params[7].w * _928;\n            float tau = _937 * _937;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _953;\n                if (_915)\n                {\n                    _953 = world_pos.y - (fa_mesh_fs_params[9].y * _911);\n                }\n                else\n                {\n                    _953 = fa_mesh_fs_params[0].y;\n                }\n                float _974 = mix(_953, world_pos.y, clamp(fa_mesh_fs_params[8].x / _916, 0.0, 1.0));\n                float _978 = world_pos.y - _974;\n                float _983 = _974 - fa_mesh_fs_params[8].z;\n                float _988 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _991 = _983 <= 0.0;\n                bool _992 = !_991;\n                bool _998;\n                if (_992)\n                {\n                    _998 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _998 = _991;\n                }\n                float _999;\n                if (_998)\n                {\n                    _999 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _999 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _983, 80.0));\n                }\n                bool _1026;\n                if (_992)\n                {\n                    _1026 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1026 = _991;\n                }\n                float _1027;\n                if (_1026)\n                {\n                    _1027 = fa_mesh_fs_params[8].y * _983;\n                }\n                else\n                {\n                    _1027 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _983, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1052 = _988 <= 0.0;\n                bool _1059;\n                if (!_1052)\n                {\n                    _1059 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1059 = _1052;\n                }\n                float _1060;\n                if (_1059)\n                {\n                    _1060 = fa_mesh_fs_params[8].y * _988;\n                }\n                else\n                {\n                    _1060 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _988, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1087;\n                if (abs(_978) < 0.001000000047497451305389404296875)\n                {\n                    _1087 = _999;\n                }\n                else\n                {\n                    _1087 = (_1060 - _1027) / _978;\n                }\n                tau += (_928 * max(_1087, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _1125 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _1125;\n        vec4 param_3 = v_shadow;\n        LightSample _1157 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _1157.color) * max(dot(_1125, _1157.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _1180 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_1180, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_129",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_292",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_649",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 20,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1132",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_full_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_full_light_tex",
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
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_full_light_tex_fa_full_shadow_smp",
            "view_name": "fa_full_light_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_full_light_tex_fa_full_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_full_shadow_tex_fa_full_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nuniform vec4 fa_skin[192];\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 0) out vec3 v_pos;\nlayout(location = 1) out vec3 v_normal;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 2) out vec4 v_shadow;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 4) in vec4 fa_color;\nmat4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _61 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_61 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_61 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_61 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec3 fa_world_position(vec3 p)\n{\n    return (fa_model * vec4(p, 1.0)).xyz;\n}\n\nvec3 fa_world_direction(vec3 n)\n{\n    vec3 _185 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_185 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _185) < 0.0) ? (-1.0) : 1.0));\n}\n\nvec4 fa_shadow_coord(vec3 world)\n{\n    return vec4(world, 1.0);\n}\n\nvoid fa_user_main()\n{\n    vec3 param = fa_position;\n    vec3 _227 = fa_world_position(param);\n    v_pos = _227;\n    vec3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    vec3 param_2 = _227;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_227, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_model = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    fa_user_main();\n}\n\n",
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_light_tex_fa_full_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_full_light_tex_fa_full_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _110 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _117 = fa_light_texel(param_1);\n    float _122 = _117.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _130 = _122 < 0.5;\n    vec3 l;\n    if (_130)\n    {\n        l = normalize(_110.xyz);\n    }\n    else\n    {\n        vec3 _142 = _110.xyz - world_pos;\n        float _144 = length(_142);\n        dist = _144;\n        l = _142 / vec3(max(_144, 9.9999997473787516355514526367188e-05));\n        float _159 = _144 / max(_110.w, 0.001000000047497451305389404296875);\n        float _165 = clamp(1.0 - (_159 * _159), 0.0, 1.0);\n        atten = _165 * _165;\n        if (_122 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _180 = fa_light_texel(param_2);\n            float _190 = _180.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _197 = fa_light_texel(param_3);\n            float _199 = _197.x;\n            float cos_inner = _199;\n            if (_199 > 1.5)\n            {\n                cos_inner = mix(_190, 1.0, 0.25);\n            }\n            atten *= smoothstep(_190, cos_inner, dot(-l, normalize(_180.xyz)));\n        }\n    }\n    int _230;\n    if (_130)\n    {\n        _230 = 0;\n    }\n    else\n    {\n        _230 = (_122 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _117.xyz * atten, atten, 1.0, dist, _230);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _282;\n    if (i == 0)\n    {\n        _282 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _299;\n        if (i == 1)\n        {\n            _299 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _308;\n            if (i == 2)\n            {\n                _308 = fa_shadows[24].z;\n            }\n            else\n            {\n                _308 = fa_shadows[24].w;\n            }\n            _299 = _308;\n        }\n        _282 = _299;\n    }\n    return _282;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_full_shadow_tex_fa_full_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _270 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_270), sin(_270)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _348 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _353 = clamp(dot(n, l), 0.0, 1.0);\n    float _359 = sqrt(1.0 - (_353 * _353));\n    float _367 = min(_359 / max(_353, 0.20000000298023223876953125), 4.0);\n    float _372;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _372 = fa_shadows[26].y;\n    }\n    else\n    {\n        _372 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _397 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_372 * _359)), 1.0);\n    float _404 = _397.x;\n    bool _407 = _404 < fa_shadows[ci * 1 + 16].x;\n    bool _416;\n    if (!_407)\n    {\n        _416 = _404 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _416 = _407;\n    }\n    bool _425;\n    if (!_416)\n    {\n        _425 = _397.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _425 = _416;\n    }\n    bool _434;\n    if (!_425)\n    {\n        _434 = _397.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _434 = _425;\n    }\n    bool _441;\n    if (!_434)\n    {\n        _441 = _397.z > 1.0;\n    }\n    else\n    {\n        _441 = _434;\n    }\n    if (_441)\n    {\n        return -1.0;\n    }\n    float _450;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _450 = fa_shadows[26].x;\n    }\n    else\n    {\n        _450 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _469 = _397.z - ((_450 * (1.0 + (0.5 * _367))) / _348);\n    float _478 = ((fa_shadows[ci * 1 + 20].x * min(_367, 3.0)) * 0.5) / _348;\n    int _487 = int(fa_shadows[25].z + 0.5);\n    if (_487 == 1)\n    {\n        vec2 param = _397.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _498 = fa_shadow_depth(param, param_1);\n        return float(_469 <= _498);\n    }\n    float _505 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _508 = _487 == 2;\n    if (_508)\n    {\n        float _522 = clamp(((fa_shadows[25].w * _348) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _505;\n            vec2 _542 = fa_shadow_vogel(param_2, param_3, param_4) * _522;\n            vec2 param_5 = _397.xy + (_542 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _553 = fa_shadow_depth(param_5, param_6);\n            if (_553 < (_469 - (length(_542) * _478)))\n            {\n                sum += _553;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_469 - (sum / cnt), 0.0) * _348) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _597 = _508 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _597; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _597;\n        float param_9 = _505;\n        vec2 _616 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _397.xy + (_616 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _627 = fa_shadow_depth(param_10, param_11);\n        lit += float((_469 - (length(_616) * _478)) <= _627);\n    }\n    return lit / float(_597);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _660 = int(fa_shadows[25].x + 0.5);\n    if (_660 < 1)\n    {\n        return 1.0;\n    }\n    float _677 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _660 - 1;\n    if (_677 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _689 = _660 > 1;\n    bool _696;\n    if (_689)\n    {\n        _696 = _677 > fa_shadows[24].x;\n    }\n    else\n    {\n        _696 = _689;\n    }\n    if (_696)\n    {\n        ci = 1;\n    }\n    bool _700 = _660 > 2;\n    bool _707;\n    if (_700)\n    {\n        _707 = _677 > fa_shadows[24].y;\n    }\n    else\n    {\n        _707 = _700;\n    }\n    if (_707)\n    {\n        ci = 2;\n    }\n    bool _711 = _660 > 3;\n    bool _718;\n    if (_711)\n    {\n        _718 = _677 > fa_shadows[24].z;\n    }\n    else\n    {\n        _718 = _711;\n    }\n    if (_718)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _660)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _744 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _744;\n        if (_744 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _769;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _769 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _769 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _788 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _769, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _799 = clamp((_677 - (fa_shadow_split_at(param_7) - _788)) / _788, 0.0, 1.0);\n        if (_799 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _660)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _820 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _820;\n                if (_820 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _799);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec3 param = coord.xyz / vec3(coord.w);\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _859 = fa_light_sample(param, param_1);\n    vec3 _1213 = _859.direction;\n    vec3 _1208 = _859.color;\n    float _1210 = _859.shadow;\n    int _1218 = _859.type;\n    if ((_1218 == 0) && (li == 0))\n    {\n        vec4 param_2 = coord;\n        vec3 param_3 = gn;\n        vec3 param_4 = _1213;\n        float _875 = fa_shadow(param_2, param_3, param_4);\n        _1210 = _875;\n        _1208 *= _875;\n    }\n    return LightSample(_1213, _1208, _859.attenuation, _1210, _859._distance, _1218);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _888 = fa_mesh_fs_params[7].w > 0.0;\n    bool _896;\n    if (!_888)\n    {\n        _896 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _896 = _888;\n    }\n    if (_896)\n    {\n        vec3 _904 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _911 = dot(_904, fa_mesh_fs_params[9].xyz);\n        bool _915 = fa_mesh_fs_params[9].w > 0.5;\n        float _916;\n        if (_915)\n        {\n            _916 = _911;\n        }\n        else\n        {\n            _916 = length(_904);\n        }\n        float _928 = _916 - fa_mesh_fs_params[8].x;\n        if (_928 > 0.0)\n        {\n            float _937 = fa_mesh_fs_params[7].w * _928;\n            float tau = _937 * _937;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _953;\n                if (_915)\n                {\n                    _953 = world_pos.y - (fa_mesh_fs_params[9].y * _911);\n                }\n                else\n                {\n                    _953 = fa_mesh_fs_params[0].y;\n                }\n                float _974 = mix(_953, world_pos.y, clamp(fa_mesh_fs_params[8].x / _916, 0.0, 1.0));\n                float _978 = world_pos.y - _974;\n                float _983 = _974 - fa_mesh_fs_params[8].z;\n                float _988 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _991 = _983 <= 0.0;\n                bool _992 = !_991;\n                bool _998;\n                if (_992)\n                {\n                    _998 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _998 = _991;\n                }\n                float _999;\n                if (_998)\n                {\n                    _999 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _999 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _983, 80.0));\n                }\n                bool _1026;\n                if (_992)\n                {\n                    _1026 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1026 = _991;\n                }\n                float _1027;\n                if (_1026)\n                {\n                    _1027 = fa_mesh_fs_params[8].y * _983;\n                }\n                else\n                {\n                    _1027 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _983, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1052 = _988 <= 0.0;\n                bool _1059;\n                if (!_1052)\n                {\n                    _1059 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1059 = _1052;\n                }\n                float _1060;\n                if (_1059)\n                {\n                    _1060 = fa_mesh_fs_params[8].y * _988;\n                }\n                else\n                {\n                    _1060 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _988, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1087;\n                if (abs(_978) < 0.001000000047497451305389404296875)\n                {\n                    _1087 = _999;\n                }\n                else\n                {\n                    _1087 = (_1060 - _1027) / _978;\n                }\n                tau += (_928 * max(_1087, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _1125 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _1125;\n        vec4 param_3 = v_shadow;\n        LightSample _1157 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _1157.color) * max(dot(_1125, _1157.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _1180 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_1180, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
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
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_71",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_247",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_292",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_649",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 20,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1132",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_full_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_full_light_tex",
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
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_full_light_tex_fa_full_shadow_smp",
            "view_name": "fa_full_light_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_full_light_tex_fa_full_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_full_shadow_tex_fa_full_shadow_smp"
          }
        ]
      }
    }
  }
}
