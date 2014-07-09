using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace ChosenDropDownList
{
    [ToolboxData("<{0}:EmbeddedChosenDdl runat=server></{0}:EmbeddedChosenDdl>")]
    [ViewStateModeById]
    [PersistenceMode(PersistenceMode.InnerProperty)]
    [PersistChildren(true)]
    public class EmbeddedChosenDdl : System.Web.UI.UserControl//, IPostBackDataHandler
    {
        private HiddenField hdnChosen = new HiddenField { ID = "hdnChosen" };
        private ChosenDropDownList ddlChosen = new ChosenDropDownList { ID = "ddlChosen", HiddenFieldID="hdnChosen"};

        private string hdnChosenSavedValue
        {
            get
            {
                object o = ViewState["hdnChosen"];
                if (o != null)
                    return o.ToString();
                else
                    return null;
            }

            set
            {
                ViewState["NoResultsText"] = value;
            }
        }

        private object ddlChosenSavedDataSource
        {
            get
            {
                object o = ViewState["ddlChosen"];
                if (o != null )
                    return o;
                else
                    return null;
            }

            set
            {
                ViewState["ddlChosen"] = value;
            }
        }

        #region Properties
        public bool IsMultiselect
        {
            get { return ddlChosen.IsMultiselect; }
            set { ddlChosen.IsMultiselect = value; }
        }

        public string NoResultsText
        {
            get
            {
                return ddlChosen.NoResultsText;
            }

            set
            {
                ddlChosen.NoResultsText = value;
            }
        }

        public string PlaceholderTextMultiple
        {
            get
            {
                return ddlChosen.PlaceholderTextMultiple;
            }

            set
            {
                ddlChosen.PlaceholderTextMultiple = value;
            }
        }

        public string PlaceholderTextSingle
        {
            get
            {
                return ddlChosen.PlaceholderTextSingle;
            }

            set
            {
                ddlChosen.PlaceholderTextSingle = value;
            }
        }

        public bool SearchContains
        {
            get
            {
                return ddlChosen.SearchContains;
            }

            set
            {
                ddlChosen.SearchContains = value;
            }
        }

        public bool DisableSearch
        {
            get
            {
                return ddlChosen.DisableSearch;
            }

            set
            {
                ddlChosen.DisableSearch = value;
            }
        }

        public int MaxSelectedOptions
        {
            get
            {
                return ddlChosen.MaxSelectedOptions;
            }

            set
            {
                ddlChosen.MaxSelectedOptions = value;
            }
        }

        public string Width
        {
            get
            {
                return ddlChosen.Width;
            }

            set
            {
                ddlChosen.Width = value;
            }
        }

        public List<string> SelectedValues
        {
            get
            {
                return ddlChosen.SelectedValues;
            }

            set
            {
                ddlChosen.SelectedValues = value;
            }
        }

        public string DefaultSelectedValues
        {
            get
            {
                return ddlChosen.DefaultSelectedValues;
            }

            set
            {
                ddlChosen.DefaultSelectedValues = value;
            }
        }

        public object DataSource
        {
            get { return ddlChosen.DataSource; }
            set { ddlChosen.DataSource = value; }
        }

        public string DataTextField
        {
            get { return ddlChosen.DataTextField; }
            set { ddlChosen.DataTextField = value; }
        }
        public string DataValueField
        {
            get { return ddlChosen.DataValueField; }
            set { ddlChosen.DataValueField = value; }
        }
        public string DataTextFormatString
        {
            get { return ddlChosen.DataTextFormatString; }
            set { ddlChosen.DataTextFormatString = value; }
        }
        public string CssClass
        {
            get { return ddlChosen.CssClass; }
            set { ddlChosen.CssClass = value; }
        }
        #endregion

        public override void DataBind()
        {
            ddlChosen.DataBind();
            base.DataBind();
        }

        //[System.Security.Permissions.PermissionSet(System.Security.Permissions.SecurityAction.Demand, Name = "Execution")]
        protected override void CreateChildControls()
        {
            if (hdnChosenSavedValue != null)
                hdnChosen.Value = hdnChosenSavedValue;
            this.Controls.Add(hdnChosen);


            if (ddlChosenSavedDataSource != null)
                ddlChosen.DataSource = ddlChosenSavedDataSource;
            this.Controls.Add(ddlChosen);
            ddlChosen.DataBind();
        }

        protected override void RenderChildren(HtmlTextWriter output)
        {
            base.RenderChildren(output);
        }

        protected override void OnPreRender(EventArgs e)
        {
            EnableViewState = true;
            //Page.RegisterRequiresPostBack(this);
            base.OnPreRender(e);
        }

        protected override void OnUnload(EventArgs e)
        {
            base.OnUnload(e);
        }
    }
}
