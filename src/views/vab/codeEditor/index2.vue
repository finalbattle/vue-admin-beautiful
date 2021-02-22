<template>
  <div>
    <!-- 操作按钮 -->
    <el-button @click="handleAdd">代码编辑，高亮补全</el-button>
    <el-button @click="handleUpdateBBB">代码版本，差异对比</el-button>
    <div id="view"></div>
    <el-form ref="form" :model="form" label-width="0px">
      <el-form-item label="">
        <div class="in-coder-panel">
          <textarea ref="textarea"></textarea>
          <el-select
            v-model="mode"
            class="code-mode-select"
            @change="changeMode"
          >
            <el-option
              v-for="mode1 in modes"
              :key="mode1.value"
              :label="mode1.label"
              :value="mode1.value"
            ></el-option>
          </el-select>
        </div>
      </el-form-item>
    </el-form>
    <!-- 代码编辑，高亮补全 对话框内容 -->
    <!-- <el-dialog :title="title" :visible.sync="open">
    </el-dialog> -->

    <!-- 代码版本，差异对比 对话框内容 -->
    <el-dialog :title="titleBBB" :visible.sync="openBBB">
      <!-- <div id="view"></div> -->
    </el-dialog>
  </div>
</template>

<script>
  // 引入全局实例
  import CodeMirror from 'codemirror'
  // 核心样式
  import 'codemirror/lib/codemirror.css'
  // 引入主题后还需要在 options 中指定主题才会生效
  import 'codemirror/theme/eclipse.css'

  // 需要引入具体的语法高亮库才会有对应的语法高亮效果
  // codemirror 官方其实支持通过 /addon/mode/loadmode.js 和 /mode/meta.js 来实现动态加载对应语法高亮库
  // 但 vue 貌似没有无法在实例初始化后再动态加载对应 JS ，所以此处才把对应的 JS 提前引入
  import 'codemirror/mode/javascript/javascript.js'
  import 'codemirror/mode/css/css.js'
  import 'codemirror/mode/xml/xml.js'
  import 'codemirror/mode/shell/shell.js'
  import 'codemirror/mode/sql/sql.js'
  import 'codemirror/mode/python/python.js'
  // import 'codemirror/mode/java/java.js'

  //代码补全提示
  import 'codemirror/addon/hint/anyword-hint.js'
  import 'codemirror/addon/hint/css-hint.js'
  import 'codemirror/addon/hint/html-hint.js'
  import 'codemirror/addon/hint/javascript-hint.js'
  import 'codemirror/addon/hint/show-hint.css'
  import 'codemirror/addon/hint/show-hint.js'
  import 'codemirror/addon/hint/sql-hint.js'
  import 'codemirror/addon/hint/xml-hint.js'
  // import 'codemirror/addon/hint/python-hint.js'
  // import 'codemirror/addon/hint/java-hint.js'

  //代码版本差异比较
  import 'codemirror/addon/merge/merge.js'
  import 'codemirror/addon/merge/merge.css'
  import DiffMatchPatch from 'diff-match-patch'

  window.diff_match_patch = DiffMatchPatch
  window.DIFF_DELETE = -1
  window.DIFF_INSERT = 1
  window.DIFF_EQUAL = 0

  export default {
    name: 'Code',
    // code: '',

    props: {
      // 外部传入的内容，用于实现双向绑定
      // value: '',
      value: {
        type: String,
        default: null,
      },
      // 外部传入的语法类型
      language: {
        type: String,
        default: null,
      },
    },

    data() {
      return {
        // 内部真实的内容
        code: this.code,

        // 默认的语法类型
        mode: 'shell',
        // 编辑器实例
        coder: null,
        // 默认配置
        options: {
          // 缩进格式
          tabSize: 4,
          // 主题，对应主题库 JS 需要提前引入
          theme: 'eclipse',
          // 显示行号
          lineNumbers: true,
          line: true,
          extraKeys: { Ctrl: 'autocomplete' },
        },
        // 支持切换的语法高亮类型，对应 JS 已经提前引入
        // 使用的是 MIME-TYPE ，不过作为前缀的 text/ 在后面指定时写死了
        modes: [
          {
            value: 'css',
            label: 'CSS',
          },
          {
            value: 'javascript',
            label: 'Javascript',
          },
          {
            value: 'html',
            label: 'XML/HTML',
          },
          {
            value: 'x-sh',
            label: 'Shell',
          },
          {
            value: 'python',
            label: 'Python',
          },
          {
            value: 'x-sql',
            label: 'SQL',
          },
        ],
        // 弹出层标题
        title: '',
        titleBBB: '',
        // 是否显示弹出层
        open: false,
        openBBB: false,
      }
    },
    created() {
      this.fetchData()
    },
    methods: {
      // 初始化
      _initialize() {
        // 初始化编辑器实例，传入需要被实例化的文本域对象和默认配置
        this.coder = CodeMirror.fromTextArea(this.$refs.textarea, this.options)
        // 编辑器赋值
        this.coder.setValue(this.value || this.code)

        // 支持双向绑定
        this.coder.on('change', (coder) => {
          this.code = coder.getValue()

          if (this.$emit) {
            this.$emit('input', this.code)
          }
        })

        // 尝试从父容器获取语法类型
        if (this.language) {
          // 获取具体的语法类型对象
          let modeObj = this._getLanguage(this.language)

          // 判断父容器传入的语法是否被支持
          if (modeObj) {
            this.mode = modeObj.label
          }
        }
      },
      // 获取当前语法类型
      _getLanguage(language) {
        // 在支持的语法类型列表中寻找传入的语法类型
        return this.modes.find((mode) => {
          // 所有的值都忽略大小写，方便比较
          let currentLanguage = language.toLowerCase()
          let currentLabel = mode.label.toLowerCase()
          let currentValue = mode.value.toLowerCase()

          // 由于真实值可能不规范，例如 java 的真实值是 x-java ，所以讲 value 和 label 同时和传入语法进行比较
          return (
            currentLabel === currentLanguage || currentValue === currentLanguage
          )
        })
      },
      // 更改模式
      changeMode(val) {
        // 修改编辑器的语法配置
        this.coder.setOption('mode', `text/${val}`)

        // 获取修改后的语法
        let label = this._getLanguage(val).label.toLowerCase()

        // 允许父容器通过以下函数监听当前的语法值
        this.$emit('language-change', label)
      },

      initUI(value, orig) {
        if (value == null) return
        let target = document.getElementById('view')
        target.innerHTML = ''
        CodeMirror.MergeView(target, {
          value: value, //上次内容
          origLeft: null,
          orig: orig, //本次内容
          lineNumbers: true, //显示行号
          mode: 'shell',
          highlightDifferences: true,
          styleActiveLine: true,
          matchBrackets: true,
          connect: 'align',
          readOnly: true, //只读 不可修改
        })
      },

      /** 按钮操作 */
      handleAdd() {
        // this.open = true
        // this.title = '代码编辑，高亮补全'
        this.fetchData()
        this.$nextTick(function () {
          this._initialize()
        })
      },

      /** 按钮操作 */
      handleUpdateBBB() {
        // this.openBBB = true
        // this.titleBBB = '代码版本，差异对比'

        // 初始化版本差异
        this.$nextTick(function () {
          this.initUI(
            '#!/bin/bash\n' +
              'ip="123.21.12.11"\n' +
              'email="lgx@example"\n' +
              ' \n' +
              'while 1\n' +
              'do\n' +
              '  ping -c10 $ip > /dev/null 2>/dev/null\n' +
              '  if [ $? != "0" ]\n' +
              '  then\n' +
              '       # 调用一个用于发邮件的脚本\n' +
              '     python /usr/local/sbin/mail.py $email "$ip down" "$ip is down"\n' +
              '  fi\n' +
              '  sleep 30\n' +
              'done", "#!/bin/bash\n' +
              'ip="123.21.12.11"\n' +
              'email="admin@example"\n' +
              ' \n' +
              'while 1\n' +
              'do\n' +
              '  ping -c10 $ip > /dev/null 2>/dev/null\n' +
              '  if [ $? != "0" ]\n' +
              '  then\n' +
              '       # 调用一个用于发邮件的脚本\n' +
              '     python /usr/local/sbin/mail.py $email "$ip down" "$ip is down"\n' +
              '  fi\n' +
              'done'
          )
        })
      },

      fetchData() {
        this._readTestFile()
        this.$nextTick(function () {
          this._initialize()
        })
      },

      _readTestFile() {
        const filename =
          '/jumper_master/code_for_mount/jumper/test/test_seg_solo.py'
        const file = this._loadFile(filename)
        this.code = this._unicodeToUtf8(file)
      },
      // 读取文件
      _loadFile(name) {
        const xhr = new XMLHttpRequest()
        const okStatus = document.location.protocol === 'file:' ? 0 : 200
        xhr.open('GET', name, false)
        xhr.setRequestHeader('Access-Control-Allow-Origin', '*')
        xhr.overrideMimeType('text/plain;charset=utf-8') // 默认为utf-8
        xhr.send(null)
        return xhr.status === okStatus ? xhr.responseText : null
      },
      // unicode转utf-8
      _unicodeToUtf8(data) {
        if (data != null) {
          data = data.replace(/\\/g, '%')
        }
        return unescape(data)
      },
    },
  }
</script>
<style>
  /* .in-coder-panel{
    flex-grow: 1;
    display: flex;
    position:relative;
  }

  .CodeMirror{
    flex-grow :1;
    z-index :1;
  }
  .CodeMirror-code{
    line-height :19px
  }

  .code-mode-select{
    position: absolute;
    z-index :2;
    right: 10px;
    top: 10px;
    max-width :130px
  } */
  .code-mode-select {
    position: absolute;
    top: 0;
    right: 85px;
    z-index: 10;
  }
  .CodeMirror pre.CodeMirror-line,
  .CodeMirror pre.CodeMirror-line-like {
    padding: 0 45px;
  }
  .red {
    background-color: red !important;
  }
</style>
